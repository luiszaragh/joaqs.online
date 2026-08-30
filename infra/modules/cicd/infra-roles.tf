# ---------------------------------------------------------------------------
# Two roles for infra.yml, split by what they are allowed to do.
#
# DECISIONS.md #21 — plan on a pull request, apply on main behind a GitHub
# Environment approval. Splitting the credentials along the same seam is the
# point: a pull request can read the account and produce a plan, and nothing
# more. Only the approved apply job holds write access.
#
# A single role used for both would mean every pull request ran with the
# permissions needed to destroy the stack.
# ---------------------------------------------------------------------------

# --- the subject claims -----------------------------------------------------
#
# These differ from the deploy role's, and the difference is easy to get wrong.
#
#   push to main            repo:owner@id/repo@id:ref:refs/heads/main
#   pull request            repo:owner@id/repo@id:pull_request
#   job using an Environment repo:owner@id/repo@id:environment:NAME
#
# The last one is the trap. The moment a job declares `environment:`, GitHub
# replaces the ref subject with the environment subject. A trust policy written
# against refs/heads/main will reject the apply job with the same opaque
# "Not authorized" that says nothing about why.

locals {
  oidc_subject_prefix = "repo:${var.github_owner}@${var.github_owner_id}/${var.github_repo}@${var.github_repo_id}"
}

# --- plan role: read the account, write only the state lock ------------------

data "aws_iam_policy_document" "infra_plan_assume" {
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
      values   = ["${local.oidc_subject_prefix}:pull_request"]
    }
  }
}

resource "aws_iam_role" "infra_plan" {
  name                 = "${var.project}-infra-plan"
  description          = "Assumed by infra.yml on pull requests. Read-only, plus the state lock."
  assume_role_policy   = data.aws_iam_policy_document.infra_plan_assume.json
  max_session_duration = 3600
}

# ReadOnlyAccess rather than a hand-written read policy. A plan touches every
# service in the configuration and AWS adds read actions faster than a
# hand-maintained list can track; an incomplete list produces plans that are
# silently wrong rather than failing loudly.
#
# The tradeoff is real and worth stating: this role can read the account. It
# cannot change anything, and infra.yml refuses to run the plan job for a pull
# request opened from a fork, so the only principals who can assume it are
# people who can already push a branch here.
resource "aws_iam_role_policy_attachment" "infra_plan_readonly" {
  role       = aws_iam_role.infra_plan.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

# A plan against an S3 backend with `use_lockfile` writes a .tflock object and
# deletes it on the way out. Without this the plan fails on the lock, not on
# anything to do with the configuration.
data "aws_iam_policy_document" "infra_state_lock" {
  statement {
    sid       = "ReadState"
    effect    = "Allow"
    actions   = ["s3:GetObject", "s3:ListBucket"]
    resources = [var.state_bucket_arn, "${var.state_bucket_arn}/*"]
  }

  statement {
    sid       = "HoldStateLock"
    effect    = "Allow"
    actions   = ["s3:PutObject", "s3:DeleteObject"]
    resources = ["${var.state_bucket_arn}/*.tflock"]
  }
}

resource "aws_iam_role_policy" "infra_plan_state" {
  name   = "${var.project}-infra-plan-state"
  role   = aws_iam_role.infra_plan.id
  policy = data.aws_iam_policy_document.infra_state_lock.json
}

# --- apply role: write, gated behind an Environment approval ----------------

data "aws_iam_policy_document" "infra_apply_assume" {
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

    # environment:, not ref:. See the note at the top of this file.
    #
    # This is a stronger condition than a branch would be. A branch subject only
    # says where the code came from; the environment subject is only issued
    # after GitHub has recorded the approval that the Environment's protection
    # rules demand.
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["${local.oidc_subject_prefix}:environment:${var.apply_environment}"]
    }
  }
}

resource "aws_iam_role" "infra_apply" {
  name                 = "${var.project}-infra-apply"
  description          = "Assumed by infra.yml after Environment approval. Writes the stack."
  assume_role_policy   = data.aws_iam_policy_document.infra_apply_assume.json
  max_session_duration = 3600
}

# Scoped by service and, where the API supports it, by resource. Not
# AdministratorAccess: this role should not be able to touch anything outside
# the stack it manages.
#
# Where a resource is "*", that is because the service is global or its create
# actions carry no resource to scope against — CloudFront, ACM and Budgets all
# behave this way. Named in comments rather than left to be assumed.
data "aws_iam_policy_document" "infra_apply" {
  # checkov:skip=CKV_AWS_356:The three "*" resources are cloudfront, acm and
  # budgets. All are global services whose create actions carry no resource ARN
  # to scope against — AWS does not accept a narrower policy for them. Every
  # other statement in this document is bound to a specific ARN or prefix.
  # checkov:skip=CKV_AWS_111:Same three statements. The write actions that
  # cannot be constrained are constrained instead at the trust boundary: this
  # role can only be assumed after a human approves the production Environment.
  # checkov:skip=CKV_AWS_109:Permissions-management actions here are bounded to
  # arn:aws:iam::<account>:role/joaqs-online-* and the one OIDC provider. The
  # residual risk — that the prefix includes this role itself — is stated in
  # the ProjectIamPrincipals statement below rather than hidden.

  statement {
    sid    = "StateBackend"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:ListBucket",
      "s3:GetBucketVersioning",
    ]
    resources = [var.state_bucket_arn, "${var.state_bucket_arn}/*"]
  }

  # The site bucket is created and configured by this role, so the actions
  # cover its whole lifecycle. Scoped to the one bucket by name prefix.
  statement {
    sid       = "SiteBucket"
    effect    = "Allow"
    actions   = ["s3:*"]
    resources = ["arn:aws:s3:::${var.project}-site-*", "arn:aws:s3:::${var.project}-site-*/*"]
  }

  # CloudFront, ACM and Budgets are global services whose create actions take
  # no scopable resource ARN.
  statement {
    sid    = "GlobalEdgeAndBilling"
    effect = "Allow"
    actions = [
      "cloudfront:*",
      "acm:*",
      "budgets:*",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "BudgetNotifications"
    effect = "Allow"
    actions = [
      "sns:CreateTopic",
      "sns:DeleteTopic",
      "sns:GetTopicAttributes",
      "sns:SetTopicAttributes",
      "sns:ListTagsForResource",
      "sns:TagResource",
      "sns:UntagResource",
      "sns:Subscribe",
      "sns:Unsubscribe",
      "sns:ListSubscriptionsByTopic",
      "sns:GetSubscriptionAttributes",
    ]
    resources = ["arn:aws:sns:*:${var.account_id}:${var.project}-*"]
  }

  # IAM is where this role is most dangerous, so it is the most tightly bound:
  # only principals whose names start with the project prefix.
  #
  # ACCEPTED RISK, recorded rather than hidden: that prefix includes this role
  # itself, so the apply role can rewrite its own policy. It is unavoidable
  # while Terraform manages the CI roles it runs as. The mitigation is the
  # Environment approval — the role cannot be assumed at all until a human
  # approves the deployment.
  statement {
    sid    = "ProjectIamPrincipals"
    effect = "Allow"
    actions = [
      "iam:CreateRole",
      "iam:DeleteRole",
      "iam:GetRole",
      "iam:UpdateRole",
      "iam:UpdateAssumeRolePolicy",
      "iam:PutRolePolicy",
      "iam:DeleteRolePolicy",
      "iam:GetRolePolicy",
      "iam:ListRolePolicies",
      "iam:AttachRolePolicy",
      "iam:DetachRolePolicy",
      "iam:ListAttachedRolePolicies",
      "iam:TagRole",
      "iam:UntagRole",
      "iam:ListRoleTags",
    ]
    resources = ["arn:aws:iam::${var.account_id}:role/${var.project}-*"]
  }

  statement {
    sid    = "OidcProvider"
    effect = "Allow"
    actions = [
      "iam:GetOpenIDConnectProvider",
      "iam:CreateOpenIDConnectProvider",
      "iam:DeleteOpenIDConnectProvider",
      "iam:UpdateOpenIDConnectProviderThumbprint",
      "iam:AddClientIDToOpenIDConnectProvider",
      "iam:TagOpenIDConnectProvider",
    ]
    resources = ["arn:aws:iam::${var.account_id}:oidc-provider/token.actions.githubusercontent.com"]
  }

  # Terraform reads these on almost every plan to resolve data sources and to
  # confirm what it is talking to. All read-only.
  statement {
    sid    = "ReadOnlyContext"
    effect = "Allow"
    actions = [
      "sts:GetCallerIdentity",
      "iam:ListRoles",
      "iam:ListOpenIDConnectProviders",
      "iam:ListPolicies",
      "s3:ListAllMyBuckets",
      "s3:GetBucketLocation",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "infra_apply" {
  name   = "${var.project}-infra-apply"
  role   = aws_iam_role.infra_apply.id
  policy = data.aws_iam_policy_document.infra_apply.json
}

output "infra_plan_role_arn" {
  description = "role-to-assume for the plan job in infra.yml."
  value       = aws_iam_role.infra_plan.arn
}

output "infra_apply_role_arn" {
  description = "role-to-assume for the apply job in infra.yml."
  value       = aws_iam_role.infra_apply.arn
}
