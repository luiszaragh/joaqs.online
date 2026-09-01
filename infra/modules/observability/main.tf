terraform {
  required_version = ">= 1.11"

  required_providers {
    # Floors only. The ceiling lives in the root's versions.tf, and Terraform
    # takes the intersection — so a `~>` here would have to be edited in every
    # module the day the root moves to a new major. A minimum says what this
    # module needs without constraining what the caller may use.
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0"
    }
  }
}

variable "project" {
  type = string
}

variable "monthly_budget_usd" {
  type = number
}

variable "alert_email" {
  type = string
}

variable "cloudfront_distribution_arn" {
  description = "The distribution whose access logs land in the bucket in logs.tf (#62)."
  type        = string
}

variable "log_retention_days" {
  description = <<-EOT
    DECISIONS.md #22 — access logs live 90 days, then delete themselves.

    These records contain visitor IP addresses. "Keep them in case" is a
    privacy decision made by inertia; ninety days answers every question worth
    asking about a portfolio's traffic.
  EOT
  type        = number
  default     = 90
}

variable "tags" {
  type    = map(string)
  default = {}
}

# ---------------------------------------------------------------------------
# The cost control from DECISIONS.md #5, in code rather than in the console.
#
# Two notifications on purpose. ACTUAL at 80% is the "something changed" signal
# and arrives while there is still room to react; FORECASTED at 100% catches a
# runaway before the month is over — which is the shape a chatbot with a real
# API key behind it would fail in.
# ---------------------------------------------------------------------------

resource "aws_sns_topic" "budget" {
  # checkov:skip=CKV_AWS_26:Encrypting this topic would break it. Server-side
  # encryption with the AWS-managed key (alias/aws/sns) blocks cross-service
  # publishing, because budgets.amazonaws.com cannot be granted
  # kms:GenerateDataKey on a key whose policy is not editable — the alerts
  # would stop arriving with no error anywhere. Doing it properly means a
  # customer-managed key at roughly $1/month, on a stack whose entire target
  # is under $1/month, to encrypt the sentence "you have spent $8". The
  # payload is a threshold notification containing no secret.
  name = "${var.project}-budget-alerts"
}

# AWS Budgets publishes as a service principal, so the topic needs an explicit
# grant. Scoped to this account so another account's budget cannot publish here.
data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "budget_topic" {
  statement {
    sid       = "AllowBudgetsToPublish"
    effect    = "Allow"
    actions   = ["SNS:Publish"]
    resources = [aws_sns_topic.budget.arn]

    principals {
      type        = "Service"
      identifiers = ["budgets.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

resource "aws_sns_topic_policy" "budget" {
  arn    = aws_sns_topic.budget.arn
  policy = data.aws_iam_policy_document.budget_topic.json
}

# Two subscribers per threshold, each with a different job:
#
#   EMAIL  — AWS Budgets mails the address directly. No SNS in the path and no
#            confirmation step, so it works from the moment of the first apply.
#            This is the notification a human reads.
#   SNS    — the fan-out point for machines. M5 subscribes the chatbot's
#            degrade-to-canned-message path here (DECISIONS.md #12); a Lambda
#            can subscribe to a topic, it cannot subscribe to a budget email.
#
# The topic ALSO has an email subscription now, reversing the note that used to
# stand here. DECISIONS.md #62.
#
# The original reasoning was that it duplicates a mail AWS Budgets already
# sends, and parks at "pending confirmation" until someone clicks a link — a
# state that reads as healthy and delivers nothing. Both of those are still
# true. What they missed is that the direct budget email is UNTESTABLE: AWS
# Budgets has no test-fire, so the only proof it works is a threshold being
# crossed for real, which on a stack that costs pennies may be never.
#
# A topic subscription can be tested in ten seconds — confirm it, publish a
# test message, see whether it arrives. An alert path nobody has ever seen
# deliver is a hope, not a control. A duplicate email is a small price for
# turning one into the other.
resource "aws_sns_topic_subscription" "budget_email" {
  topic_arn = aws_sns_topic.budget.arn
  protocol  = "email"
  endpoint  = var.alert_email

  # AWS mails a confirmation link on create and the subscription stays pending
  # until it is clicked. Terraform cannot click it, and cannot read the
  # resulting ARN either — so without this every subsequent plan shows a
  # spurious change and would tear the subscription down and recreate it,
  # sending a fresh confirmation each time.
  lifecycle {
    ignore_changes = [id]
  }
}

resource "aws_budgets_budget" "monthly" {
  name         = "${var.project}-monthly"
  budget_type  = "COST"
  limit_amount = tostring(var.monthly_budget_usd)
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_sns_topic_arns  = [aws_sns_topic.budget.arn]
    subscriber_email_addresses = [var.alert_email]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_sns_topic_arns  = [aws_sns_topic.budget.arn]
    subscriber_email_addresses = [var.alert_email]
  }

  depends_on = [aws_sns_topic_policy.budget]
}

output "budget_topic_arn" {
  description = "Budget alert topic. M5 subscribes the chatbot's degrade-to-canned-message path to this."
  value       = aws_sns_topic.budget.arn
}
