# Copyright Amazon.com, Inc. or its affiliates. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

data "aws_caller_identity" "current" {}

data "aws_ssm_parameter" "guard_duty_bucket_for_logs" {
  provider = aws.log-archive-primary
  name     = "/org/core/central-logs/guardduty-s3"
}

data "aws_ssm_parameter" "guard_duty_kms_for_logs" {
  provider = aws.log-archive-primary
  name     = "/org/core/central-logs/guardduty-kms"
}

data "aws_ssm_parameter" "ct_log_archive_account_id" {
  provider = aws.aft-management
  name     = "/org/core/accounts/ct-log-archive"
}