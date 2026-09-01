# ---------------------------------------------------------------------------
# CloudFront access logs. DECISIONS.md #22, #62 — M6.
#
# The point of these is one question: does anyone actually arrive from
# LinkedIn. No JavaScript, no cookies, no consent banner and no hosted
# analytics product — the CDN already sees every request, so the cheapest
# honest answer is to keep what it already knows for 90 days and query it when
# there is a reason to.
#
# STANDARD LOGGING V2, not the legacy `logging_config` block on the
# distribution. The legacy path is free but writes with an object ACL, which
# means the log bucket has to have ACLs ENABLED. modules/site/s3.tf turns them
# off on purpose — "leaving them available is a standing invitation to make the
# bucket public by accident" — and re-enabling them on the bucket that holds
# visitor IP addresses is the wrong bucket to make that exception for. V2
# delivers through CloudWatch Logs instead, costs a fraction of a cent a month
# at this volume, and needs no ACLs anywhere.
#
# Everything here is us-east-1 because the module is: CloudFront is a global
# service anchored there, and a delivery source for it can only be created in
# that region.
# ---------------------------------------------------------------------------

resource "aws_s3_bucket" "logs" {
  # checkov:skip=CKV_AWS_18:Access logging ON the log bucket is a recursion
  # with a monthly bill. Nothing writes here but one AWS service.
  # checkov:skip=CKV_AWS_145:SSE-S3 for the same reason as the site bucket —
  # KMS adds a per-request charge to protect records that expire in 90 days.
  # checkov:skip=CKV_AWS_144:Cross-region replication protects data that cannot
  # be recreated. These are logs with a 90-day life; losing them costs nothing
  # that was not already going to be deleted.
  # checkov:skip=CKV2_AWS_62:Event notifications need a consumer, and wiring an
  # unused one is more attack surface rather than less.
  # checkov:skip=CKV_AWS_21:Versioning protects against an object being
  # overwritten or deleted. Nothing overwrites anything here — one AWS service
  # appends immutable objects that the lifecycle rule then expires at 90 days.
  # Enabling it would roughly double the storage AND leave non-current versions
  # that the expiry rule does not touch, so the 90-day promise in #22 would
  # quietly stop being true. Off is the choice that keeps the retention honest.
  bucket = "${var.project}-logs-${data.aws_caller_identity.current.account_id}"
  tags   = merge(var.tags, { Name = "${var.project}-logs" })
}

resource "aws_s3_bucket_public_access_block" "logs" {
  bucket = aws_s3_bucket.logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ACLs off here too. V2 delivery does not need them, which is the whole reason
# it was chosen over the legacy path.
resource "aws_s3_bucket_ownership_controls" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_versioning" "logs" {
  bucket = aws_s3_bucket.logs.id

  versioning_configuration {
    # Off deliberately. Versioning a write-once log stream doubles the storage
    # and gives the lifecycle rule below a second set of objects to chase.
    status = "Disabled"
  }
}

# DECISIONS.md #22 — 90 days, then gone. These records contain visitor IP
# addresses, so "keep them forever in case" is a privacy decision made by
# inertia. Ninety days answers every question worth asking about a portfolio's
# traffic and answers it about the period anyone cares about.
resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    id     = "expire-after-90-days"
    status = "Enabled"

    filter {}

    expiration {
      days = var.log_retention_days
    }

    # A multipart upload that never completes is invisible in the console and
    # billable forever.
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }

  depends_on = [aws_s3_bucket_versioning.logs]
}

# --- the delivery path ------------------------------------------------------

data "aws_iam_policy_document" "logs_bucket" {
  # The log-delivery service writes here on CloudFront's behalf. Both
  # conditions matter: SourceAccount stops another account's delivery from
  # writing into this bucket, and the ArnLike pins it to deliveries from this
  # account's log service rather than any caller that assumes the role.
  statement {
    sid       = "AllowLogDeliveryWrite"
    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.logs.arn}/*"]

    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = ["arn:aws:logs:us-east-1:${data.aws_caller_identity.current.account_id}:delivery-source:*"]
    }
  }

  # Delivery checks the bucket's ownership before its first write.
  statement {
    sid       = "AllowLogDeliveryCheckAcl"
    effect    = "Allow"
    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.logs.arn]

    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

resource "aws_s3_bucket_policy" "logs" {
  bucket = aws_s3_bucket.logs.id
  policy = data.aws_iam_policy_document.logs_bucket.json

  depends_on = [aws_s3_bucket_public_access_block.logs]
}

# What produces the logs.
resource "aws_cloudwatch_log_delivery_source" "cloudfront" {
  name         = "${var.project}-cdn-access-logs"
  log_type     = "ACCESS_LOGS"
  resource_arn = var.cloudfront_distribution_arn

  tags = merge(var.tags, { Name = "${var.project}-cdn-access-logs" })
}

# Where they land, and in what shape. JSON rather than parquet: at a
# portfolio's volume the storage difference is measured in kilobytes, and JSON
# is far easier to point Athena at and to read by eye when something looks
# wrong. Revisit if this ever gets big enough for the scan cost to matter.
resource "aws_cloudwatch_log_delivery_destination" "logs_bucket" {
  name          = "${var.project}-cdn-logs-s3"
  output_format = "json"

  delivery_destination_configuration {
    destination_resource_arn = aws_s3_bucket.logs.arn
  }

  tags = merge(var.tags, { Name = "${var.project}-cdn-logs-s3" })
}

resource "aws_cloudwatch_log_delivery" "cloudfront_to_s3" {
  delivery_source_name     = aws_cloudwatch_log_delivery_source.cloudfront.name
  delivery_destination_arn = aws_cloudwatch_log_delivery_destination.logs_bucket.arn

  # Hive-style partitioning, so an Athena query for "last week" reads last
  # week's objects instead of every object ever written. Free to ask for now
  # and expensive to retrofit once ninety days of unpartitioned logs exist.
  #
  # A list, not a block: the provider models this as a list of objects.
  #
  # THE SUFFIX PATH IS THE VARIABLES ONLY. Writing the hive `key=value` pairs
  # by hand — `/year={yyyy}/month={MM}` — is rejected with a bare "Provided
  # suffixPath is invalid": `enable_hive_compatible_path` is what adds those
  # names, and the path may contain nothing but separators and the fields the
  # service allows. The authoritative list is not in the Terraform docs, it is
  # in the API:
  #
  #   aws logs describe-configuration-templates --region us-east-1 \
  #     --service cloudfront --log-types ACCESS_LOGS \
  #     --delivery-destination-types S3 \
  #     --query 'configurationTemplates[].allowedSuffixPathFields'
  #
  # which answers: accountid, region, DistributionId, distributionid, yyyy, MM,
  # dd, HH — and nothing else.
  s3_delivery_configuration = [{
    suffix_path                 = "/{yyyy}/{MM}/{dd}"
    enable_hive_compatible_path = true
  }]

  tags = merge(var.tags, { Name = "${var.project}-cdn-logs-delivery" })

  depends_on = [aws_s3_bucket_policy.logs]
}

output "logs_bucket_name" {
  description = "Where CloudFront access logs land. Point Athena here (see infra/README.md)."
  value       = aws_s3_bucket.logs.bucket
}
