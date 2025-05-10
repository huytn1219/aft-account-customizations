#!/bin/bash
# Copyright Amazon.com, Inc. or its affiliates. All rights reserved.
# SPDX-License-Identifier: Apache-2.0
#
set -e

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
LZ_ID=$(aws ssm get-parameter --name "/landingzone_id" --query 'Parameter.Value' --output text)

if [ -z "$LZ_ID" ]; then
  echo "Error: Failed to retrieve Landing Zone ID from SSM parameter /landingzone_id"
  exit 1
fi

echo "Landing Zone ID: $LZ_ID"

# Get root OU ID
echo "Fetching Root OU ID..."
ROOT_ID=$(aws organizations list-roots --query 'Roots[0].Id' --output text)

if [ -z "$ROOT_ID" ]; then
  echo "Error: Failed to retrieve Root OU ID"
  exit 1
fi

echo "Root OU ID: $ROOT_ID"

# Get all OUs
OUS=$(aws organizations list-organizational-units-for-parent \
  --parent-id "$ROOT_ID" \
  --query 'OrganizationalUnits[*].Id' --output text)

if [ -z "$OUS" ]; then
  echo "Warning: No Organizational Units found under Root ID $ROOT_ID"
  exit 0  # Exit gracefully if no OUs exist
fi

# Get AWSControlTowerBaseline ARN (needed for re-registration)
echo "Fetching AWSControlTowerBaseline ARN..."
CONTROL_TOWER_BASELINE_ARN=$(aws controltower list-baselines \
  --query 'baselines[?name==`AWSControlTowerBaseline`].arn' --output text)
if [ -z "$CONTROL_TOWER_BASELINE_ARN" ]; then
  echo "Error: Failed to retrieve AWSControlTowerBaseline ARN"
  exit 1
fi
echo "AWSControlTowerBaseline ARN: $CONTROL_TOWER_BASELINE_ARN"

# Loop through OUs
for OU_ID in $OUS; do
  echo "Processing OU: $OU_ID"

  #  Get the ARN of the target OU to re-register.
  OU_ARN=$(aws organizations describe-organizational-unit --organizational-unit-id $OU_ID --query 'OrganizationalUnit.[Arn]' --output text)
  if [ -z "$OU_ARN" ]; then
    echo "Error: Failed to retrieve ARN for OU $OU_ID"
    continue
  fi
  echo "OU ARN: $OU_ARN"

  # Get the ARN of the EnabledBaseline resource for the target OU.
  echo "Getting the enabled baseline ARN for $OU_ARN"
  ENABLED_BASELINE_ARN=$(aws controltower list-enabled-baselines --query 'enabledBaselines[?targetIdentifier==`'$OU_ARN'`].[arn]' --output text)
  
  # If there is an enabled baseline, reset it
  if [ -z "$ENABLED_BASELINE_ARN" ]; then
    echo "Warning: No enabled baseline found for OU $OU_ID, skipping reset"
    continue
  fi
  echo "Enabled Baseline ARN: $ENABLED_BASELINE_ARN"

  # Reset the Enabled Baseline
  echo "Resetting Enabled Baseline."
  aws controltower reset-enabled-baseline --enabled-baseline-identifier "$ENABLED_BASELINE_ARN"

  # Wait for the reset operation to complete
  echo "Waiting for baseline reset to complete..."
  MAX_WAIT=120  # Maximum wait time: 120 iterations * 5 seconds = 10 minutes
  COUNT=0
  while true; do
    STATUS=$(aws controltower get-enabled-baseline --enabled-baseline-identifier "$ENABLED_BASELINE_ARN" --query 'enabledBaselineDetails.statusSummary.status' --output text)
    if [ "$STATUS" == "SUCCEEDED" ] || [ "$STATUS" == "FAILED" ]; then
      echo "Baseline reset completed with status: $STATUS"
      break
    fi
    if [ $COUNT -ge $MAX_WAIT ]; then
      echo "Error: Timeout waiting for baseline reset to complete"
      exit 1
    fi
    echo "Current status: $STATUS. Waiting..."
    sleep 5
    COUNT=$((COUNT + 1))
  done
done

echo "Script execution completed"
