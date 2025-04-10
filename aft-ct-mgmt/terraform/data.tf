# Copyright Amazon.com, Inc. or its affiliates. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

data "aws_caller_identity" "current" {}

data "aws_ssm_parameter" "landing_zone_id" {
    name = "landingzone_id"
}