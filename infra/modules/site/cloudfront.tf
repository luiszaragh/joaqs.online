locals {
  s3_origin_id      = "${var.project}-s3-origin"
  chatbot_origin_id = "${var.project}-chat-origin"
  chatbot_enabled   = var.chatbot_origin_domain != null
}

# OAC replaces the legacy Origin Access Identity. CloudFront signs each origin
# request with SigV4, so the bucket can stay fully private with no public
# policy and no website endpoint.
resource "aws_cloudfront_origin_access_control" "this" {
  name                              = "${var.project}-oac"
  description                       = "SigV4 access from CloudFront to the private site bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_function" "router" {
  name    = "${var.project}-router"
  runtime = "cloudfront-js-2.0"
  comment = "www -> apex redirect, and directory-index rewrite for S3 OAC origins"
  publish = true
  code    = file("${path.module}/functions/router.js")
}

# AWS-managed policy rather than a hand-rolled one: it already does the right
# thing (compression negotiation, no cookie/header forwarding) and does not
# drift.
data "aws_cloudfront_cache_policy" "optimized" {
  name = "Managed-CachingOptimized"
}

# The chat endpoint is a POST returning a different answer every time; caching
# it would be actively wrong.
data "aws_cloudfront_cache_policy" "disabled" {
  name = "Managed-CachingDisabled"
}

# A Lambda Function URL rejects a request whose Host header names the
# distribution rather than the function, so the Host header must NOT be
# forwarded. This managed policy forwards everything else — including
# CloudFront-Viewer-Address, which the handler uses to rate-limit by IP.
data "aws_cloudfront_origin_request_policy" "all_viewer_except_host" {
  name = "Managed-AllViewerExceptHostHeader"
}

resource "aws_cloudfront_response_headers_policy" "security" {
  # checkov:skip=CKV_AWS_259:HSTS is configured below with a one-year max-age
  # and includeSubDomains. The check fails only because `preload` is false, and
  # that is a considered choice: preload submission is browser-baked and
  # effectively irreversible, while DECISIONS.md #25 already plans a move to a
  # different domain. Preloading a domain you intend to abandon is a trap.
  name    = "${var.project}-security-headers"
  comment = "Baseline security headers for a static site"

  security_headers_config {
    strict_transport_security {
      access_control_max_age_sec = 31536000
      include_subdomains         = true
      # preload is deliberately off. Submitting to the HSTS preload list is
      # effectively permanent and browser-baked, and DECISIONS.md #25 already
      # plans a move to a real-name domain. Preloading a domain you intend to
      # abandon is a trap you set for yourself.
      preload  = false
      override = true
    }

    content_type_options {
      override = true
    }

    frame_options {
      frame_option = "DENY"
      override     = true
    }

    referrer_policy {
      referrer_policy = "strict-origin-when-cross-origin"
      override        = true
    }
  }

  # No Content-Security-Policy yet. The theme script in BaseLayout.astro is
  # inline and blocking on purpose (it prevents a flash of the wrong palette),
  # so a `default-src 'self'` policy would break the page today. M3 hashes that
  # script and the CSP lands with it.
}

resource "aws_cloudfront_distribution" "this" {
  # checkov:skip=CKV_AWS_86:Standard access logging to S3 with a 90-day
  # lifecycle, queried with Athena, is M6 (DECISIONS.md #22). Deferred on
  # purpose: storing logs before anything reads them is cost without signal.
  # checkov:skip=CKV_AWS_310:Origin failover needs a second origin. There is
  # one bucket, holding files rebuilt from git by a pipeline run. A standby
  # origin would be a second thing to keep in sync in exchange for protection
  # against an S3 regional outage that would also take down the deploy path.
  # checkov:skip=CKV_AWS_374:Geo restriction is the opposite of the goal. This
  # is a job-seeking portfolio; a recruiter in any country must be able to
  # reach it.
  # checkov:skip=CKV_AWS_68:WAF is a recorded deferral (DECISIONS.md #11). The
  # architecture routes the future chatbot through this same distribution
  # precisely so a WAF can be added later without moving anything. A WAF in
  # front of static HTML today costs about $6/month — six times the rest of the
  # stack — to rate-limit a bucket of public files.
  # checkov:skip=CKV2_AWS_47:Follows from the above. There is no WebACL to
  # attach Log4j managed rules to, and nothing here runs Java.
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "${var.project} static site"
  default_root_object = "index.html"
  price_class         = var.price_class
  aliases             = var.aliases
  http_version        = "http2and3"

  origin {
    domain_name              = aws_s3_bucket.site.bucket_regional_domain_name
    origin_id                = local.s3_origin_id
    origin_access_control_id = aws_cloudfront_origin_access_control.this.id
  }

  # DECISIONS.md #11 — the chatbot behind the same distribution, so the site
  # and its API share one hostname and one place to attach a WAF.
  dynamic "origin" {
    for_each = local.chatbot_enabled ? [1] : []

    content {
      domain_name              = var.chatbot_origin_domain
      origin_id                = local.chatbot_origin_id
      origin_access_control_id = var.chatbot_origin_access_control_id

      custom_origin_config {
        http_port              = 80
        https_port             = 443
        origin_protocol_policy = "https-only"
        origin_ssl_protocols   = ["TLSv1.2"]
      }
    }
  }

  default_cache_behavior {
    target_origin_id       = local.s3_origin_id
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true

    cache_policy_id            = data.aws_cloudfront_cache_policy.optimized.id
    response_headers_policy_id = aws_cloudfront_response_headers_policy.security.id

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.router.arn
    }
  }

  dynamic "ordered_cache_behavior" {
    for_each = local.chatbot_enabled ? [1] : []

    content {
      path_pattern           = "/api/*"
      target_origin_id       = local.chatbot_origin_id
      viewer_protocol_policy = "https-only"
      # POST carries the message; HEAD and GET are here because CloudFront
      # requires them alongside POST, not because the endpoint answers them —
      # the handler returns 405 for anything but POST.
      allowed_methods = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
      cached_methods  = ["GET", "HEAD"]
      compress        = true

      cache_policy_id            = data.aws_cloudfront_cache_policy.disabled.id
      origin_request_policy_id   = data.aws_cloudfront_origin_request_policy.all_viewer_except_host.id
      response_headers_policy_id = aws_cloudfront_response_headers_policy.security.id

      # No router function here. It rewrites directory paths for the S3 origin;
      # running it on the API path would rewrite /api/chat into /api/chat/index.html.
    }
  }

  # A private bucket does not grant s3:ListBucket, so a missing key comes back
  # as 403 AccessDenied, not 404. Both are mapped to the real 404 page and both
  # answer with a 404 status, so a mistyped URL does not show a visitor an S3
  # XML error document.
  custom_error_response {
    error_code            = 403
    response_code         = 404
    response_page_path    = "/404.html"
    error_caching_min_ttl = 60
  }

  custom_error_response {
    error_code            = 404
    response_code         = 404
    response_page_path    = "/404.html"
    error_caching_min_ttl = 60
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.this.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # Standard access logs to S3, 90-day lifecycle, queried with Athena on demand
  # (DECISIONS.md #22) land in M6 alongside the blog. Adding the log bucket now
  # would mean paying for storage of logs nobody is reading yet.

  tags = merge(var.tags, { Name = "${var.project}-cdn" })
}
