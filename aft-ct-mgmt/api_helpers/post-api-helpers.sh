# © 2025 Amazon Web Services, Inc. or its affiliates. All Rights Reserved.
#
# This AWS Content is provided subject to the terms of the AWS Customer Agreement available at
# http://aws.amazon.com/agreement or other written agreement between Customer and either
# Amazon Web Services, Inc. or Amazon Web Services EMEA SARL or both.
#!/bin/bash

echo "Executing Post-API Helpers"
echo "---------------------"
echo "---------------------"
echo "---------------------Change AWS_PROFILE=AFT-TARGET-admin---------------------"
export AWS_PROFILE=aft-target
echo "aws sts get-caller-identity"
aws sts get-caller-identity
echo "aws sts get-caller-identity"
echo "---------------------"
echo "---------------------"
echo "---------------------Access folder: CD \API_Helpers---------------------"
cd $DEFAULT_PATH/$CUSTOMIZATION/api_helpers/
echo "---------------------"
echo "---------------------Executing ./enable_ct_regions.py---------------------"
python3 enable_ct_regions.py
echo "---------------------Done!---------------------"
echo "---------------------"
echo "---------------------"
