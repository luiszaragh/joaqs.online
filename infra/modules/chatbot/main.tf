# ---------------------------------------------------------------------------
# The chatbot. DECISIONS.md #11, #12, #20, #29.
#
# Lambda Function URL, not API Gateway. The function needs one route, no
# authorizers, no request transformation and no usage plans; API Gateway would
# add a hop, a per-request charge and a second thing to configure in exchange
# for features this does not use. The trade — losing API Gateway's built-in
# throttling and WAF attachment — is covered by putting CloudFront in front,
# which is where a WAF would attach anyway (#11).
#
# The Function URL is IAM-authenticated and reachable ONLY through CloudFront,
# signed with Origin Access Control. An open Function URL would let anyone
# bypass the CDN, and with it any future WAF, straight to the thing holding an
# API key.
# ---------------------------------------------------------------------------

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# --- rate limiting ----------------------------------------------------------

# DECISIONS.md #12 — 10 messages per hour per IP. On-demand billing: at
# portfolio traffic this is a few thousand writes a month, which is inside the
# free tier and needs no capacity planning.
resource "aws_dynamodb_table" "rate_limit" {
  # checkov:skip=CKV_AWS_28:Point-in-time recovery protects data you would need
  # to restore. Every row here is a counter that expires after an hour by
  # design; restoring one would restore a rate-limit window, which is
  # meaningless. PITR would add cost for negative value.
  # checkov:skip=CKV_AWS_119:The table holds a salted hash and an integer. The
  # AWS-owned key that DynamoDB encrypts with by default is appropriate for
  # data that carries no identifier in the first place; a CMK would add ~$1/mo
  # to a stack targeting under $1/mo to protect a counter.
  name         = "${var.project}-chat-rate-limit"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "pk"

  attribute {
    name = "pk"
    type = "S"
  }

  # DynamoDB deletes expired rows itself, so nothing accumulates and no
  # cleanup job has to exist. The pseudonymous key is gone within an hour of
  # the last message.
  ttl {
    attribute_name = "expires_at"
    enabled        = true
  }

  tags = merge(var.tags, { Name = "${var.project}-chat-rate-limit" })
}

# The salt that turns a stored IP hash into a pseudonym. A bare SHA-256 of an
# IPv4 address is reversible by brute force in seconds — the whole address
# space is four billion values — so without this the table would effectively
# hold visitor IP addresses.
#
# It lives in state rather than in the code because it must be stable (a
# rotating salt resets everyone's rate limit) and must not be a literal in a
# public repository. It grants no access to anything, so state is an
# appropriate home for it.
resource "random_password" "ip_salt" {
  length  = 32
  special = false
}

# --- the function -----------------------------------------------------------

# Created empty and filled by lambda.yml (DECISIONS.md #21 — one workflow per
# concern). Terraform owns the function's existence and configuration; the
# pipeline owns its code. `ignore_changes` on the package is what keeps the
# two from fighting: without it, every `terraform apply` would roll the code
# back to this placeholder.
data "archive_file" "placeholder" {
  type        = "zip"
  output_path = "${path.module}/build/placeholder.zip"

  source {
    filename = "index.mjs"
    content  = <<-EOT
      // Placeholder. The real handler is deployed by .github/workflows/lambda.yml.
      export async function handler() {
        return {
          statusCode: 503,
          headers: { "content-type": "application/json" },
          body: JSON.stringify({ reply: "The assistant is not deployed yet." }),
        };
      }
    EOT
  }
}

resource "aws_cloudwatch_log_group" "chat" {
  # checkov:skip=CKV_AWS_158:CloudWatch encrypts log groups with an AWS-managed
  # key by default. A CMK here would cost more per month than the rest of this
  # stack, to protect questions the public asks a public chatbot.
  # checkov:skip=CKV_AWS_338:The check wants a year. DECISIONS.md #12 says 30
  # days, and shorter is the stronger position here rather than the weaker one:
  # these logs contain questions typed by identifiable strangers. The reason to
  # keep them is to learn what recruiters ask, which a month answers as well as
  # a year. Retaining visitor questions for twelve months would be a privacy
  # decision made by a compliance default rather than on purpose.
  name              = "/aws/lambda/${var.project}-chat"
  retention_in_days = var.log_retention_days

  tags = merge(var.tags, { Name = "${var.project}-chat-logs" })
}

resource "aws_lambda_function" "chat" {
  # checkov:skip=CKV_AWS_50:X-Ray tracing on a single-function synchronous
  # request path shows one segment calling three AWS APIs and one HTTP
  # endpoint, which the structured logs already record with timings. It would
  # be genuine value across a multi-service call graph; there is not one here.
  # checkov:skip=CKV_AWS_115:Reserved concurrency is deliberately unset. It
  # would cap this function's share of the account limit — but this is the only
  # function in the account, so it would protect nothing while adding a hard
  # failure mode at the cap. Spend is capped where spend actually happens: the
  # per-IP rate limit and the budget alarm.
  # checkov:skip=CKV_AWS_116:A dead-letter queue is for asynchronous
  # invocations whose failures would otherwise vanish. This is a synchronous
  # request/response function — a failure returns a canned sentence to the
  # browser and is logged. There is nothing to replay.
  # checkov:skip=CKV_AWS_117:VPC placement would mean private subnets, a NAT
  # gateway at ~$32/month, and slower cold starts, to reach an API on the
  # public internet. The function holds no VPC-resident dependency.
  # checkov:skip=CKV_AWS_272:Code signing is real supply-chain control, and it
  # is skipped on a boundary argument rather than a cost one. It stops anyone
  # holding lambda:UpdateFunctionCode from deploying unsigned code. Here that
  # is one principal — joaqs-online-lambda-deploy — assumable only by this
  # repository's main branch over OIDC. A Signer profile would live in the same
  # account and be used by the same pipeline, so it would re-state the boundary
  # that already exists rather than add one. It becomes worth doing the day
  # signing authority can sit somewhere the deploy pipeline cannot reach.
  # checkov:skip=CKV_AWS_173:The environment holds a bucket name, an object
  # key, a table name, a parameter name, and the rate limiter's IP salt. The
  # API key is deliberately NOT among them — it lives in SSM as a SecureString
  # and is fetched at runtime, which is the finding this check is really
  # reaching for and it is already satisfied. The salt is a privacy value, not
  # a credential: it grants nothing, and reading it would additionally require
  # DynamoDB access to be worth anything. Lambda already encrypts these at rest
  # with an AWS-managed key; a CMK would roughly double this stack's monthly
  # bill to re-encrypt four resource names and a salt.
  function_name = "${var.project}-chat"
  description   = "Answers questions about Luis from the build-time corpus. DECISIONS.md #20."
  role          = aws_iam_role.chat.arn
  handler       = "index.handler"
  runtime       = "nodejs22.x"
  architectures = ["arm64"] # ~20% cheaper per GB-second than x86_64

  filename         = data.archive_file.placeholder.output_path
  source_code_hash = data.archive_file.placeholder.output_base64sha256

  # 20s upstream timeout in the handler, plus room for a cold start and the
  # corpus fetch. Not higher: a hung request should fail while the reader is
  # still watching, not after they have left.
  timeout = 29

  # Above ~512 MB this workload gains nothing but costs proportionally more —
  # it is waiting on a network call, not computing.
  memory_size = 512

  environment {
    variables = {
      CORPUS_BUCKET     = var.corpus_bucket_name
      CORPUS_KEY        = var.corpus_key
      RATE_LIMIT_TABLE  = aws_dynamodb_table.rate_limit.name
      API_KEY_PARAMETER = var.api_key_parameter_name
      IP_HASH_SALT      = random_password.ip_salt.result
    }
  }

  depends_on = [aws_cloudwatch_log_group.chat]

  lifecycle {
    # lambda.yml owns the code from here on. See the note above.
    ignore_changes = [filename, source_code_hash]
  }

  tags = merge(var.tags, { Name = "${var.project}-chat" })
}

# --- the URL ----------------------------------------------------------------

# AWS_IAM, not NONE. With NONE this URL is a public endpoint that anyone can
# call directly, bypassing CloudFront and any future WAF, straight to the
# function that holds the API key. Signed by CloudFront's OAC instead.
resource "aws_lambda_function_url" "chat" {
  function_name      = aws_lambda_function.chat.function_name
  authorization_type = "AWS_IAM"
}

# CloudFront signs origin requests to the Function URL with SigV4, the same
# mechanism as the S3 origin. `always` because the origin rejects anything
# unsigned; the Lambda service checks the signature before the function runs.
resource "aws_cloudfront_origin_access_control" "chat" {
  name                              = "${var.project}-chat-oac"
  description                       = "SigV4 access from CloudFront to the chat Function URL"
  origin_access_control_origin_type = "lambda"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# --- execution role ---------------------------------------------------------

data "aws_iam_policy_document" "chat_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "chat" {
  name               = "${var.project}-chat-exec"
  description        = "Execution role for the chatbot Lambda."
  assume_role_policy = data.aws_iam_policy_document.chat_assume.json

  tags = merge(var.tags, { Name = "${var.project}-chat-exec" })
}

# Every statement is bound to one resource. The function reads one object, one
# parameter and one table, and writes to one log group — so that is exactly
# what the role says.
data "aws_iam_policy_document" "chat" {
  statement {
    sid       = "WriteOwnLogs"
    effect    = "Allow"
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.chat.arn}:*"]
  }

  statement {
    sid       = "ReadCorpus"
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${var.corpus_bucket_arn}/${var.corpus_key}"]
  }

  statement {
    sid       = "ReadApiKey"
    effect    = "Allow"
    actions   = ["ssm:GetParameter"]
    resources = ["arn:aws:ssm:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:parameter${var.api_key_parameter_name}"]
  }

  # Decrypting the SecureString. Scoped to the SSM service in this region by
  # the ViaService condition, so this grant cannot be used to decrypt anything
  # else the account's default key protects.
  statement {
    sid       = "DecryptApiKey"
    effect    = "Allow"
    actions   = ["kms:Decrypt"]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["ssm.${data.aws_region.current.region}.amazonaws.com"]
    }
  }

  statement {
    sid       = "RateLimit"
    effect    = "Allow"
    actions   = ["dynamodb:UpdateItem"]
    resources = [aws_dynamodb_table.rate_limit.arn]
  }
}

resource "aws_iam_role_policy" "chat" {
  # checkov:skip=CKV_AWS_355:The one "*" is kms:Decrypt, which is constrained
  # instead by kms:ViaService to SSM in this region — the account's default SSM
  # key has no ARN to name here, and the condition is the tighter bound anyway.
  # checkov:skip=CKV_AWS_356:Same statement, same reason.
  name   = "${var.project}-chat"
  role   = aws_iam_role.chat.id
  policy = data.aws_iam_policy_document.chat.json
}
