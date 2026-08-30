terraform {
  required_version = ">= 1.11"

  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

variable "project" {
  type = string
}

variable "github_owner" {
  description = "GitHub account that owns the repository allowed to deploy."
  type        = string
}

variable "github_repo" {
  description = "Repository name. Combined with the owner and branch to form the OIDC subject claim."
  type        = string
}

variable "github_owner_id" {
  description = "Immutable numeric owner ID, embedded in the OIDC subject claim since 2026-07-15."
  type        = number
}

variable "github_repo_id" {
  description = "Immutable numeric repository ID. Changes if the repo is deleted and recreated."
  type        = number
}

variable "deploy_branch" {
  description = "The only branch permitted to assume the deploy role."
  type        = string
  default     = "main"
}

variable "site_bucket_arn" {
  type = string
}

variable "cloudfront_distribution_arn" {
  type = string
}

# ---------------------------------------------------------------------------
# The OIDC trust anchor.
#
# This replaces long-lived AWS access keys in GitHub secrets. GitHub mints a
# short-lived, signed token describing the workflow run; AWS verifies the
# signature against this provider and exchanges it for temporary credentials.
# Nothing durable is ever stored on GitHub's side, so there is no key to leak
# and none to rotate.
# ---------------------------------------------------------------------------

resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  # The audience GitHub is asked to put in the token. Restricting it to STS
  # means a token minted for some other audience cannot be replayed here.
  client_id_list = ["sts.amazonaws.com"]

  # thumbprint_list is deliberately omitted. AWS manages certificate trust for
  # well-known OIDC providers including GitHub Actions, so a hardcoded
  # thumbprint is no longer required — and a stale one used to break every
  # workflow in an account the day GitHub rotated its certificate.
}

# ---------------------------------------------------------------------------
# Who may assume the deploy role.
#
# This document is the actual security boundary of the whole pipeline. The
# permissions policy below decides what the role can touch; this decides who
# gets to be the role at all. Everything else is secondary to getting the `sub`
# condition right.
# ---------------------------------------------------------------------------

data "aws_iam_policy_document" "site_deploy_assume" {
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

    # StringEquals, not StringLike, and no wildcard anywhere in the value.
    #
    # This matches pushes to one branch of one repository and nothing else. It
    # does not match a pull request from a fork (those carry `pull_request` in
    # the subject instead of `ref`), another branch, or a tag.
    #
    # A wildcard here is the classic way this gets compromised: `repo:owner/*`
    # lets any repository in the account deploy, and `repo:owner/name:*` lets
    # any branch — including one a stranger opens a pull request from.
    #
    # Note the `@id` segments. Since 2026-07-15 GitHub embeds immutable numeric
    # owner and repository IDs in the subject claim, so the value is
    #
    #   repo:owner@ownerID/repo@repoID:ref:refs/heads/main
    #
    # not the `repo:owner/repo:...` form most documentation still shows. A name
    # can be released and re-registered by someone else; an ID cannot, so the
    # trust cannot be inherited by a repository that merely reuses the name.
    #
    # The practical cost is that deleting and recreating the repository issues a
    # new repo ID and breaks this policy until var.github_repo_id is updated.
    # That is the protection working, not a bug — but it is worth knowing before
    # it happens rather than during.
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        "repo:${var.github_owner}@${var.github_owner_id}/${var.github_repo}@${var.github_repo_id}:ref:refs/heads/${var.deploy_branch}",
      ]
    }
  }
}

# ---------------------------------------------------------------------------
# What the deploy role may do: publish this site, and nothing else.
#
# Every resource is named by ARN. There is no `s3:*`, no `*` resource, and no
# CloudFront permission beyond invalidating this one distribution.
# ---------------------------------------------------------------------------

data "aws_iam_policy_document" "site_deploy" {
  # `aws s3 sync` lists the bucket to work out what changed. Without this it
  # would fall back to uploading everything on every run.
  statement {
    sid       = "ListSiteBucket"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [var.site_bucket_arn]
  }

  # PutObject to upload, DeleteObject because the sync runs with --delete.
  # GetObject is not granted: the deploy writes the site, it never reads it.
  statement {
    sid       = "WriteSiteObjects"
    effect    = "Allow"
    actions   = ["s3:PutObject", "s3:DeleteObject"]
    resources = ["${var.site_bucket_arn}/*"]
  }

  statement {
    sid       = "InvalidateThisDistribution"
    effect    = "Allow"
    actions   = ["cloudfront:CreateInvalidation", "cloudfront:GetInvalidation"]
    resources = [var.cloudfront_distribution_arn]
  }
}

resource "aws_iam_role" "site_deploy" {
  name                 = "${var.project}-site-deploy"
  description          = "Assumed by site.yml over OIDC to publish the static site"
  assume_role_policy   = data.aws_iam_policy_document.site_deploy_assume.json
  max_session_duration = 3600
}

resource "aws_iam_role_policy" "site_deploy" {
  name   = "${var.project}-site-deploy"
  role   = aws_iam_role.site_deploy.id
  policy = data.aws_iam_policy_document.site_deploy.json
}

output "site_deploy_role_arn" {
  description = "Goes into site.yml as role-to-assume."
  value       = aws_iam_role.site_deploy.arn
}

output "oidc_provider_arn" {
  description = "Reused by lambda.yml (M5) and infra.yml (M4) — one provider per account, many roles."
  value       = aws_iam_openid_connect_provider.github.arn
}
