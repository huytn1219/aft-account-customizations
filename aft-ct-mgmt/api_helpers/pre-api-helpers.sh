#!/bin/bash
# Copyright Amazon.com, Inc. or its affiliates. All rights reserved.
# SPDX-License-Identifier: Apache-2.0
#

echo "Executing Pre-API Helpers"
LANDING_ZONE_ID=$(aws controltower list-landing-zones --query 'landingZones[0].arn' --output text)

export LANDING_ZONE_ID=$LANDING_ZONE_ID