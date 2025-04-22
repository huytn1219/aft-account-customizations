output "budget_ids" {
  description = "Map of budget names to their IDs"
  value       = module.aws_budget.budget_ids
}

output "budget_arns" {
  description = "Map of budget names to their ARNs"
  value       = module.aws_budget.budget_arns
}

output "sns_topic_arn" {
  description = "ARN of the SNS topic created for budget notifications"
  value       = module.aws_budget.sns_topic_arn
}

output "sns_topic_name" {
  description = "Name of the SNS topic created for budget notifications"
  value       = module.aws_budget.sns_topic_name
}
