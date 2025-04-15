# Copyright Amazon.com, Inc. or its affiliates. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

variable "guardduty_auto_enable_organization_members" {
  description = "Define whether enable GuardDuty Organization Configuration or not."
  type        = string
  default     = "ALL"
  validation {
    condition     = contains(["ALL", "NEW", "NONE"], var.guardduty_auto_enable_organization_members)
    error_message = "Valid values are: ALL, NEW, and NONE."
  }
}

variable "securityhub_control_finding_generator" {
  description = "Define whether the Security Hub calling account has consolidated control findings turned on."
  type        = string
  default     = "SECURITY_CONTROL"
  validation {
    condition     = contains(["SECURITY_CONTROL", "STANDARD_CONTROL"], var.securityhub_control_finding_generator)
    error_message = "Valid values are: SECURITY_CONTROL, STANDARD_CONTROL."
  }
}

variable "securityhub_enabled_standard_arns" {
  description = "List of AWS Security Hub standard ARNs to enable."
  type        = list(string)
  default     = []
}

variable "datasources" {
  description = "Define the collected datasources configuration."
  type        = map(bool)
  default = {
    s3_logs            = false
    kubernetes         = false
    malware_protection = false
  }
  validation {
    condition = alltrue([
      for k, v in var.datasources : true if
      contains(["s3_logs", "kubernetes", "malware_protection"], k)
    ])
    error_message = "Valid values are: s3_logs, kubernetes, and malware_protection."
  }
}

variable "organization_features" {
  description = <<-EOF
    "GuardDuty features that will be enabled.
    Acording to GuardDuty documentation, specifying both RUNTIME_MONITORING (preferred) and EKS_RUNTIME_MONITORING will cause an error.
    See the https://docs.aws.amazon.com/guardduty/latest/APIReference/API_OrganizationFeatureConfiguration.html for more information."
    Example:
    ```
      organization_features = {
        S3_DATA_EVENTS         = "NEW"
        EKS_AUDIT_LOGS         = "NEW"
        EBS_MALWARE_PROTECTION = "NEW"
        RDS_LOGIN_EVENTS       = "NEW"
        LAMBDA_NETWORK_LOGS    = "NEW"
        RUNTIME_MONITORING     = "NEW"
      }
    ```
  EOF
  type        = map(string)
  default = {
    S3_DATA_EVENTS         = "NONE"
    EKS_AUDIT_LOGS         = "NONE"
    EBS_MALWARE_PROTECTION = "NONE"
    RDS_LOGIN_EVENTS       = "NONE"
    LAMBDA_NETWORK_LOGS    = "NONE"
    RUNTIME_MONITORING     = "NONE"
  }
}

variable "additional_configuration" {
  description = <<-EOF
    "Additional configuration for RUNTIME_MONITORING and EKS_RUNTIME_MONITORING features.
    See https://docs.aws.amazon.com/guardduty/latest/APIReference/API_OrganizationAdditionalConfiguration.html for more information."
    Example:
    ```
      additional_configuration = {
        EKS_ADDON_MANAGEMENT         = "NEW" # for RUNTIME_MONITORING or EKS_RUNTIME_MONITORING
        ECS_FARGATE_AGENT_MANAGEMENT = "NEW" # for RUNTIME_MONITORING only
        EC2_AGENT_MANAGEMENT         = "NEW" # for RUNTIME_MONITORING only
      }
    ```
  EOF
  type        = map(string)
  default = {
    EKS_ADDON_MANAGEMENT         = "NONE"
    ECS_FARGATE_AGENT_MANAGEMENT = "NONE"
    EC2_AGENT_MANAGEMENT         = "NONE"
  }
  validation {
    condition = alltrue([
      for k, v in var.additional_configuration : true if
      contains(["EKS_ADDON_MANAGEMENT", "ECS_FARGATE_AGENT_MANAGEMENT", "EC2_AGENT_MANAGEMENT"], k) &&
      contains(["NEW", "ALL", "NONE"], v)
    ])
    error_message = "Valid values are: EKS_ADDON_MANAGEMENT, ECS_FARGATE_AGENT_MANAGEMENT, and EC2_AGENT_MANAGEMENT."
  }
}