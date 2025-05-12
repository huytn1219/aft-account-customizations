# AWS Control Tower Region and OU Management Script

## Overview

This Python script automates the process of enabling specified AWS regions in AWS Control Tower and re-registering Organizational Units (OUs) to ensure they are properly managed under the new region configurations. It reads the desired regions and OUs to skip from a configuration file (`config.yaml`), updates the Control Tower landing zone to match the desired regions, and then re-registers the OUs that are not in the skip list.

## Prerequisites

- **AWS CLI**: Configured with appropriate permissions to access AWS Organizations and AWS Control Tower.
- **Python 3.x**: Installed on your local machine or the environment where the script will run.
- **Boto3**: AWS SDK for Python, installed via `pip install boto3`.
- **PyYAML**: YAML parser for Python, installed via `pip install pyyaml`.
- **Permissions**: Ensure that the AWS credentials used have the necessary permissions to:
  - Read and update AWS Control Tower landing zones (`controltower:ListLandingZones`, `controltower:GetLandingZone`, `controltower:UpdateLandingZone`).
  - List and describe AWS Organizations OUs (`organizations:ListRoots`, `organizations:ListOrganizationalUnitsForParent`, `organizations:DescribeOrganizationalUnit`).
  - Reset enabled baselines in AWS Control Tower (`controltower:ResetEnabledBaseline`, `controltower:ListEnabledBaselines`, `controltower:GetBaselineOperation`).

## Configuration

The script requires a `config.yaml` file in the same directory with the following structure:

```yaml
regions:
  - us-east-1
  - us-west-2
  - eu-west-1
ous_to_skip:
  - Security
  - Infrastructure

- **regions**: A list of AWS regions to enable in AWS Control Tower.
