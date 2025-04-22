locals {
  # Process budgets with defaults
  budgets = {
    for i, budget in var.budgets : i => merge(
      {
        time_unit = var.default_time_unit
      },
      budget
    )
  }
}