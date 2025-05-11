locals {
  identifiers = {
      region = "us-west-1",
      additional_regions = []
}
}

# set variable for log_rentention_days
# set a variable for log rentention days  



variable "log_retention_days" {
     type = number
     default = 365
}

variable "access_log_retention_days" {
     type = number
     default = 3650
}

variable "landingzone_version" {
     type = string
     default = "3.3"
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
            accountId = "859060841143"
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
            accountId = "063511066488"
          }
          accessManagement = {
            enabled = true
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
