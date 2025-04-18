#!/bin/bash
# Copyright Amazon.com, Inc. or its affiliates. All rights reserved.
# SPDX-License-Identifier: Apache-2.0
#
set -e

export BASELINE_VERSION="4.0"

echo "Executing Post-API Helpers"

echo "Update Accounts"

# Function to check if a command succeeded
check_error() {
  if [ $? -ne 0 ]; then
    echo "Error: $1"
    exit 1
  fi
}

# Get landing zone ID from SSM
echo "Fetching Landing Zone ID from SSM..."
LZ_ID=$(aws ssm get-parameter --name "/landingzone_id" --query 'Parameter.Value' --output text 2>/dev/null)

if [ -z "$LZ_ID" ]; then
  echo "Error: Failed to retrieve Landing Zone ID from SSM parameter /landingzone_id"
  exit 1
fi

echo "Landing Zone ID: $LZ_ID"

# Get root OU ID
echo "Fetching Root OU ID..."
ROOT_ID=$(aws organizations list-roots --query 'Roots[0].Id' --output text 2>/dev/null)

if [ -z "$ROOT_ID" ]; then
  echo "Error: Failed to retrieve Root OU ID"
  exit 1
fi

echo "Root OU ID: $ROOT_ID"

# Get all OUs
OUS=$(aws organizations list-organizational-units-for-parent \
  --parent-id "$ROOT_ID" \
  --query 'OrganizationalUnits[*].Id' --output text 2>/dev/null)

if [ -z "$OUS" ]; then
  echo "Warning: No Organizational Units found under Root ID $ROOT_ID"
  exit 0  # Exit gracefully if no OUs exist
fi

# Get AWSControlTowerBaseline ARN (needed for re-registration)
echo "Fetching AWSControlTowerBaseline ARN..."
CONTROL_TOWER_BASELINE_ARN=$(aws controltower list-baselines \
  --query 'baselines[?name==`AWSControlTowerBaseline`].arn' --output text 2>/dev/null)
if [ -z "$CONTROL_TOWER_BASELINE_ARN" ]; then
  echo "Error: Failed to retrieve AWSControlTowerBaseline ARN"
  exit 1
fi
echo "AWSControlTowerBaseline ARN: $CONTROL_TOWER_BASELINE_ARN"

# Loop through OUs
for OU_ID in $OUS; do
  echo "Processing OU: $OU_ID"

  #  Get the ARN of the target OU to re-register.
  OU_ARN=$(aws organizations describe-organizational-unit --organizational-unit-id $OU_ID --query 'OrganizationalUnit.[Arn]' --output text 2>/dev/null)
  if [ -z "$OU_ARN" ]; then
    echo "Error: Failed to retrieve ARN for OU $OU_ID"
    continue
  fi
  echo "OU ARN: $OU_ARN"

  # Get the ARN of the EnabledBaseline resource for the target OU.
  echo "Found BASELINE_ARN for $OU_ARN"
  BASELINE_ARN=$(aws controltower list-enabled-baselines --query 'enabledBaselines[?targetIdentifier==`'$OU_ARN'`].[arn]' --output text 2>/dev/null)
  if [ -z "$BASELINE_ARN" ]; then
    echo "Warning: No enabled baseline found for OU $OU_ID, skipping reset"
    continue
  fi
  echo "Enabled Baseline ARN: $BASELINE_ARN"

  # Reset the Enabled Baseline
  echo "Resetting Enabled Baseline."
  aws controltower reset-enabled-baseline --enabled-baseline-identifier "$BASELINE_ARN" 2>/dev/null
  check_error "Failed to reset enabled baseline for OU $OU_ID"

  echo "Baseline reset successfully for OU $OU_ID"
done

echo "Script execution completed"