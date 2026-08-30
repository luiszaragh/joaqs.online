# ---------------------------------------------------------------------------
# The role lambda.yml assumes. DECISIONS.md #21 — one least-privilege role per
# workflow, so a compromised workflow reaches only what that workflow needs.
#
# This one updates the code of exactly one function. It cannot create a
# function, change its execution role, read its environment variables, or touch
# anything else in the account. In particular it cannot read the API key
# parameter: the running function does that with its own execution role, and
# the deploy pipeline never needs the value.
# ---------------------------------------------------------------------------

data "aws_iam_policy_document" "lambda_deploy_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["${local.oidc_subject_prefix}:ref:refs/heads/${var.deploy_branch}"]
    }
  }
}

resource "aws_iam_role" "lambda_deploy" {
  name                 = "${var.project}-lambda-deploy"
  description          = "Assumed by lambda.yml on main. Updates the chat function's code only."
  assume_role_policy   = data.aws_iam_policy_document.lambda_deploy_assume.json
  max_session_duration = 3600
}

data "aws_iam_policy_document" "lambda_deploy" {
  # UpdateFunctionCode and nothing adjacent. Notably absent:
  # UpdateFunctionConfiguration (which could repoint environment variables at
  # an attacker's bucket) and PassRole (which could attach a different
  # execution role). Terraform owns configuration; this owns code.
  statement {
    sid    = "UpdateChatFunctionCode"
    effect = "Allow"
    actions = [
      "lambda:UpdateFunctionCode",
      "lambda:GetFunction",
      "lambda:GetFunctionConfiguration",
      "lambda:PublishVersion",
    ]
    resources = [var.chat_function_arn]
  }

  # Waiting for the update to finish before the smoke test runs.
  statement {
    sid       = "ReadFunctionState"
    effect    = "Allow"
    actions   = ["lambda:ListFunctions"]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "lambda_deploy" {
  # checkov:skip=CKV_AWS_355:The one "*" is lambda:ListFunctions, an
  # account-level read that takes no resource ARN. Every write action in this
  # document is bound to the single chat function.
  name   = "${var.project}-lambda-deploy"
  role   = aws_iam_role.lambda_deploy.id
  policy = data.aws_iam_policy_document.lambda_deploy.json
}

output "lambda_deploy_role_arn" {
  description = "role-to-assume in .github/workflows/lambda.yml."
  value       = aws_iam_role.lambda_deploy.arn
}
