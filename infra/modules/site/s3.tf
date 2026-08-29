data "aws_caller_identity" "current" {}

# ---------------------------------------------------------------------------
# Origin bucket. Private, reachable only by CloudFront through OAC. There is no
# website-hosting configuration and no public bucket policy anywhere in this
# file, which is the entire point.
# ---------------------------------------------------------------------------

resource "aws_s3_bucket" "site" {
  bucket = "${var.project}-site-${data.aws_caller_identity.current.account_id}"
  tags   = merge(var.tags, { Name = "${var.project}-site" })
}

resource "aws_s3_bucket_public_access_block" "site" {
  bucket = aws_s3_bucket.site.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ACLs off entirely. Nothing in this stack needs them, and leaving them
# available is a standing invitation to make the bucket public by accident.
resource "aws_s3_bucket_ownership_controls" "site" {
  bucket = aws_s3_bucket.site.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# SSE-S3 rather than KMS: this bucket holds public HTML. KMS would add a
# per-request charge and a key policy that has to be kept in sync with the OAC
# principal, in exchange for protecting content that is served to anyone who
# asks for it.
resource "aws_s3_bucket_server_side_encryption_configuration" "site" {
  bucket = aws_s3_bucket.site.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_versioning" "site" {
  bucket = aws_s3_bucket.site.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Versioning without expiry means every hashed asset ever deployed is kept
# forever. 30 days is long enough to roll back a bad deploy by hand.
resource "aws_s3_bucket_lifecycle_configuration" "site" {
  bucket = aws_s3_bucket.site.id

  depends_on = [aws_s3_bucket_versioning.site]

  rule {
    id     = "expire-noncurrent-versions"
    status = "Enabled"

    filter {}

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }

  rule {
    id     = "abort-incomplete-uploads"
    status = "Enabled"

    filter {}

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

# ---------------------------------------------------------------------------
# The only read grant on this bucket: one CloudFront distribution, identified
# by ARN. Not "any CloudFront distribution", not "any principal in this
# account" — the AWS:SourceArn condition is what makes OAC meaningfully
# different from the old public-bucket pattern.
# ---------------------------------------------------------------------------

data "aws_iam_policy_document" "site" {
  statement {
    sid       = "AllowCloudFrontServicePrincipalReadOnly"
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.site.arn}/*"]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.this.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "site" {
  bucket = aws_s3_bucket.site.id
  policy = data.aws_iam_policy_document.site.json

  depends_on = [aws_s3_bucket_public_access_block.site]
}
