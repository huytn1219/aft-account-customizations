# Copyright Amazon.com, Inc. or its affiliates. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

output "budget_ids" {
  description = "Map of budget names to their IDs"
  value       = { for k, v in aws_budgets_budget.this : v.name => v.id }
}

output "budget_arns" {
  description = "Map of budget names to their ARNs"
  value       = { for k, v in aws_budgets_budget.this : v.name => v.arn }
}

output "budgets" {
  description = "All budget resources created by this module"
  value       = aws_budgets_budget.this
}

output "sns_topic_arn" {
  description = "ARN of the SNS topic created for budget notifications"
  value       = var.create_sns_topic ? aws_sns_topic.budget_notifications[0].arn : null
}

output "sns_topic_name" {
  description = "Name of the SNS topic created for budget notifications"
  value       = var.create_sns_topic ? aws_sns_topic.budget_notifications[0].name : null
}