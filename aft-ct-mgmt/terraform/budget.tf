
locals {
  budgets = [
    {
      name        = "monthly-cost-budget"
      budget_type = "COST"
      limit_amount = "1000"
      limit_unit  = "USD"
      time_unit   = "MONTHLY"
      
      cost_filter = {
        "InstanceType" = ["Amazon Elastic Compute Cloud - Compute"]
      }
      
      notification = {
        comparison_operator = "GREATER_THAN"
        threshold           = "80"
        threshold_type      = "PERCENTAGE"
        notification_type   = "ACTUAL"
      }
    },
    {
      name        = "monthly-usage-budget"
      budget_type = "USAGE"
      limit_amount = "100"
      limit_unit  = "GB"
      time_unit   = "MONTHLY"
      
      notification = [
        {
          comparison_operator = "GREATER_THAN"
          threshold           = "75"
          threshold_type      = "PERCENTAGE"
          notification_type   = "ACTUAL"
        },
        {
          comparison_operator = "GREATER_THAN"
          threshold           = "90"
          threshold_type      = "PERCENTAGE"
          notification_type   = "FORECASTED"
        }
      ]
    },
    {
      name        = "savings-plans-budget"
      budget_type = "SAVINGS_PLANS_UTILIZATION"
      limit_amount = "100.0"
      limit_unit  = "PERCENTAGE"
      time_unit   = "QUARTERLY"
      
      cost_types = {
        include_credit             = false
        include_discount           = false
        include_other_subscription = false
        include_recurring          = false
        include_refund             = false
        include_subscription       = true
        include_support            = false
        include_tax                = false
        include_upfront            = false
        use_amortized              = false
        use_blended                = false
      }
      notification = {
        comparison_operator = "LESS_THAN"
      }
    }
  ]
}

module "aws_budget" {
  source = "../../common/modules/budget"
  
  budgets = local.budgets
  
  # Global notification settings
  create_sns_topic = true
  email_addresses  = ["admin@example.com", "finance@example.com"]
  
  # Default notification settings
  default_time_unit          = "MONTHLY"
  default_threshold          = 80
  default_notification_type  = "ACTUAL"
  default_comparison_operator = "GREATER_THAN"
  
  tags = {
    Environment = "example"
    Project     = "budget-monitoring"
  }
}
