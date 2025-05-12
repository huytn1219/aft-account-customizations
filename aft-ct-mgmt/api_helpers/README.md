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
```

- **regions**: A list of AWS regions to enable in AWS Control Tower.
- **ous_to_skip**: A list of OU names to skip during the re-registration process.
Ensure that the config.yaml file is correctly formatted and contains the desired regions and OUs to skip.

## Usage
To run the script, execute the following command in the terminal:

```bash
python enable_ct_regions.py
```

Make sure that the `config.yaml` file is present in the same directory as the script and is properly configured.

## Functionality

### Enabling Regions
- trieves the current AWS Control Tower landing zone configuration using the `controltower` client.
- Identifies the single active landing zone (exits if none or multiple are found).
- Compares the current governed regions with the desired regions from `config.yaml`.
- Updates the landing zone manifest to reflect the desired regions by adding or removing regions as needed.
- Monitors the update operation using the `get_landing_zone_operation` API, polling every 60 seconds until completion (success or failure).

  ### Reregistering OUs
- Retrieves all OUs in the AWS Organization using the organizations client, including nested OUs through recursive pagination.
- Filters out OUs listed in ous_to_skip.
- For each remaining OU:
  -- Retrieves the OU's ARN and the ARN of its enabled baseline.
  -- Initiates re-registration using the reset_enabled_baseline API.
  -- Monitors the operation status using the get_baseline_operation API, polling every 60 seconds until completion (success or failure).
- Processes OUs sequentially to avoid concurrency issues or rate limiting.
