# Copyright Amazon.com, Inc. or its affiliates. All rights reserved.
# SPDX-License-Identifier: Apache-2.0


# Create SNS topic for budget notifications if enabled
resource "aws_sns_topic" "budget_notifications" {
  count = var.create_sns_topic ? 1 : 0
  name  = var.sns_topic_name != null ? var.sns_topic_name : "aws-budget-notifications"
  tags  = var.tags
}


# Create SNS topic policy to allow AWS Budgets to publish
resource "aws_sns_topic_policy" "budget_notifications" {
  count  = var.create_sns_topic ? 1 : 0
  arn    = aws_sns_topic.budget_notifications[0].arn
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AWSBudgetsSNSPublishingPermissions"
        Effect    = "Allow"
        Principal = {
          Service = "budgets.amazonaws.com"
        }
        Action    = "SNS:Publish"
        Resource  = aws_sns_topic.budget_notifications[0].arn
      }
    ]
  })
}

# Create AWS Budgets
resource "aws_budgets_budget" "this" {
  for_each = local.budgets

  name              = each.value.name
  budget_type       = each.value.budget_type
  limit_amount      = each.value.limit_amount
  limit_unit        = lookup(each.value, "limit_unit", "USD")
  time_unit         = each.value.time_unit
  time_period_start = lookup(each.value, "time_period_start", null)
  time_period_end   = lookup(each.value, "time_period_end", null)

  # Dynamic block for cost types
  dynamic "cost_types" {
    for_each = lookup(each.value, "cost_types", null) != null ? [each.value.cost_types] : []
    content {
      include_credit             = lookup(cost_types.value, "include_credit", null)
      include_discount           = lookup(cost_types.value, "include_discount", null)
      include_other_subscription = lookup(cost_types.value, "include_other_subscription", null)
      include_recurring          = lookup(cost_types.value, "include_recurring", null)
      include_refund             = lookup(cost_types.value, "include_refund", null)
      include_subscription       = lookup(cost_types.value, "include_subscription", null)
      include_support            = lookup(cost_types.value, "include_support", null)
      include_tax                = lookup(cost_types.value, "include_tax", null)
      include_upfront            = lookup(cost_types.value, "include_upfront", null)
      use_amortized              = lookup(cost_types.value, "use_amortized", null)
      use_blended                = lookup(cost_types.value, "use_blended", null)
    }
  }

  # Dynamic block for auto adjust data
  dynamic "auto_adjust_data" {
    for_each = lookup(each.value, "auto_adjust_data", null) != null ? [each.value.auto_adjust_data] : []
    content {
      auto_adjust_type = auto_adjust_data.value.auto_adjust_type
      historical_options {
        budget_adjustment_period = lookup(auto_adjust_data.value.historical_options, "budget_adjustment_period", null)
        lookback_available_periods = lookup(auto_adjust_data.value.historical_options, "lookback_available_periods", null)
      }
    }
  }

  # Dynamic block for cost filters
  dynamic "cost_filter" {
    for_each = lookup(each.value, "cost_filter", null) != null ? each.value.cost_filter : {}

    content {
      name   = cost_filter.key
      values = cost_filter.value
    }
  }

  # Dynamic block for notifications
  dynamic "notification" {
    for_each = lookup(each.value, "notification", null) != null ? (
      try(tolist(each.value.notification), [each.value.notification])
    ) : []
    
    content {
      comparison_operator       = lookup(notification.value, "comparison_operator", var.default_comparison_operator)
      threshold                 = lookup(notification.value, "threshold", var.default_threshold)
      threshold_type            = lookup(notification.value, "threshold_type", "PERCENTAGE")
      notification_type         = lookup(notification.value, "notification_type", var.default_notification_type)
      
      # Use SNS topic if created, otherwise use email addresses
      subscriber_sns_topic_arns = var.create_sns_topic ? [aws_sns_topic.budget_notifications[0].arn] : lookup(notification.value, "subscriber_sns_topic_arns", null)
      
      # Use email addresses from individual notification if specified, otherwise use default email addresses
      subscriber_email_addresses = lookup(notification.value, "subscriber_email_addresses", length(var.email_addresses) > 0 ? var.email_addresses : null)
    }
  }

  # Add default notification if none specified and email addresses are provided
  dynamic "notification" {
    for_each = (
      lookup(each.value, "notification", null) == null && 
      length(var.email_addresses) > 0
    ) ? [1] : []
    
    content {
      comparison_operator        = var.default_comparison_operator
      threshold                  = var.default_threshold
      threshold_type             = "PERCENTAGE"
      notification_type          = var.default_notification_type
      subscriber_email_addresses = var.email_addresses
    }
  }

  tags = var.tags
}