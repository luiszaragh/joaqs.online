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

variable "monthly_budget_usd" {
  type = number
}

variable "alert_email" {
  type = string
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

# AWS emails a confirmation link on first apply and the subscription sits at
# "pending confirmation" until it is clicked. Terraform cannot complete this
# step, and an unconfirmed subscription silently delivers nothing — so confirm
# it, then verify in the SNS console that the status reads "Confirmed".
resource "aws_sns_topic_subscription" "budget_email" {
  topic_arn = aws_sns_topic.budget.arn
  protocol  = "email"
  endpoint  = var.alert_email
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
