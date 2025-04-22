# Copyright Amazon.com, Inc. or its affiliates. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

variable "budgets" {
  type        = any
  description = <<-EOF
    A list of budgets to be managed by this module. Each budget can be of type COST, USAGE, or SAVINGS_PLANS.
    See https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/budgets_budget for all available options.
    
    Example:
    ```
    budgets = [
      {
        name            = "monthly-cost-budget"
        budget_type     = "COST"
        limit_amount    = "1000"
        limit_unit      = "USD"
        time_unit       = "MONTHLY"
        
        cost_filter = {
          Service = ["Amazon Elastic Compute Cloud - Compute"]
        }
        
        notification = {
          comparison_operator        = "GREATER_THAN"
          threshold                  = "80"
          threshold_type             = "PERCENTAGE"
          notification_type          = "ACTUAL"
          subscriber_email_addresses = ["user@example.com"]
        }
      }
    ]
    ```
  EOF
  default     = []
}

variable "email_addresses" {
  type        = list(string)
  description = "List of email addresses to notify for all budgets (can be overridden in individual budget notifications)"
  default     = []
}

variable "default_comparison_operator" {
  type        = string
  description = "The default comparison operator for budget notifications"
  default     = "GREATER_THAN"
  validation {
    condition     = contains(["GREATER_THAN", "LESS_THAN", "EQUAL_TO"], var.default_comparison_operator)
    error_message = "The default_comparison_operator must be one of: GREATER_THAN, LESS_THAN, or EQUAL_TO."
  }
}

variable "default_threshold" {
  type        = number
  description = "The default threshold for budget notifications (percentage of budget)"
  default     = 80
  validation {
    condition     = var.default_threshold > 0 && var.default_threshold <= 100
    error_message = "The default_threshold must be between 1 and 100."
  }
}

variable "default_notification_type" {
  type        = string
  description = "The default notification type for all budgets (ACTUAL or FORECASTED)"
  default     = "ACTUAL"
  validation {
    condition     = contains(["ACTUAL", "FORECASTED"], var.default_notification_type)
    error_message = "The default_notification_type must be either ACTUAL or FORECASTED."
  }
}

variable "default_time_unit" {
  type        = string
  description = "The default time unit for all budgets (DAILY, MONTHLY, QUARTERLY, or ANNUALLY)"
  default     = "MONTHLY"
  validation {
    condition     = contains(["DAILY", "MONTHLY", "QUARTERLY", "ANNUALLY"], var.default_time_unit)
    error_message = "The default_time_unit must be one of: DAILY, MONTHLY, QUARTERLY, or ANNUALLY."
  }
}

variable "create_sns_topic" {
  type        = bool
  description = "Whether to create an SNS topic for budget notifications"
  default     = true
}

variable "sns_topic_name" {
  type        = string
  description = "The name of the SNS topic for budget notifications"
  default     = null
}













variable "tags" {
  type        = map(string)
  description = "A map of tags to add to all resources"
  default     = {}
}