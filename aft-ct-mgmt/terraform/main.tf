locals {
  identifiers = {
      region = "us-west-1"
      additional_regions = []
}

variables "log_retention_days" {
     value = 365
}

variables "access_log_retention_days" {
     value = 3650
}

resource "aws_controltower_landing_zone" "main" {
  manifest_json = jsonencode({
      governedRegions = concat([local.identifiers.region], local.identifiers.additional_regions)
      organizationStructure = {
        security = {
          name = "Security"
        }
        sandbox = {
          name = "Sandbox"
        }
      }
      centralizedLogging = {
            accountId = data.aws_ssm_parameter.aft_logging_account_id.value
            configurations = {
              loggingBucket = {
                retentionDays = tostring(var.log_retention_days)
              }
              accessLoggingBucket = {
                retentionDays = tostring(var.access_log_retention_days)
              }
            }
            enabled = true
          }
          securityRoles = {
            accountId = data.aws_ssm_parameter.aft_audit_account_id.value
          }
          accessManagement = {
            enabled = false
          }
      })
  version       = var.landingzone_version
}

# Trigger OU re-registration process to update accounts
resource "null_resource" "run_script" {
  provisioner "local-exec" {
    command  = file("${path.module}/re-register-ous.sh")
  }
  depends_on = [aws_controltower_landing_zone.main]
}

import {
  to = aws_controltower_landing_zone.main
  id = data.aws_ssm_parameter.landing_zone_id.value
}

data "aws_ssm_parameter" "aft_audit_account_id" {
  name = "/aft/account/audit/account-id"
}

data "aws_ssm_parameter" "aft_logging_account_id" {
  name = "/aft/account/log-archive/account-id"
}
