#!/bin/bash
# Copyright Amazon.com, Inc. or its affiliates. All rights reserved.
# SPDX-License-Identifier: Apache-2.0
#

echo "Executing Post-API Helpers"

echo "Update Accounts"

# Get landing zone ID from SSM
LZ_ID=$(aws ssm get-parameter --name "/landingzone_id" --query 'Parameter.Value' --output text)
echo "Landing Zone ID: $LZ_ID"

# Get root OU ID
ROOT_ID=$(aws organizations list-roots --query 'Roots[0].Id' --output text)

# Get all OUs
OUS=$(aws organizations list-organizational-units-for-parent \
  --parent-id "$ROOT_ID" \
  --query 'OrganizationalUnits[*].Id' --output text)

# Loop through OUs
for OU_ID in $OUS; do
  echo "Processing OU: $OU_ID"

  #  Get the ARN of the target OU to re-register.
  OU_ARN=$(aws organizations describe-organizational-unit --organizational-unit-id $OU_ID --query 'OrganizationalUnit.[Arn]' --output text)

  # Get the ARN of the EnabledBaseline resource for the target OU.
  echo "Found BASELINE_ARN for $OU_ARN"
  BASELINE_ARN=$(aws controltower list-enabled-baselines --query 'enabledBaselines[?targetIdentifier==`'$OU_ARN'`].[arn]' --output text)

  # Reset the Enabled Baseline
  echo "Resetting Enabled Baseline."
  aws controltower reset-enabled-baseline --enabled-baseline-identifier $BASELINE_ARN
