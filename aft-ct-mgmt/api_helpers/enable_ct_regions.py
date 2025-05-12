#!/usr/bin/python
# Copyright Amazon.com, Inc. or its affiliates. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

import boto3
import yaml
import time
import logging
import argparse
from botocore.exceptions import ClientError

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger()


def filter_core_ous(all_ous, ous_to_skip):
    """
    Filter out core OUs that should be skipped
    """
    logger.info(f"Filtering out core OUs: {ous_to_skip}")
    filtered_ous = [ou for ou in all_ous if ou['Name'] not in ous_to_skip]
    logger.info(f"Found {len(filtered_ous)} OUs to process after filtering: {filtered_ous}")
    return filtered_ous

def get_all_ous(organizations_client):
    """
    Get all OUs in the AWS Organization
    """
    logger.info("Retrieving all OUs in the organization")
    
    # Get the root ID first
    try:
        roots = organizations_client.list_roots()['Roots']
        if not roots:
            logger.error("No roots found in the organization")
            return []
        
        root_id = roots[0]['Id']
        
        # Get all OUs under the root
        all_ous = []
        paginator = organizations_client.get_paginator('list_organizational_units_for_parent')
        
        for page in paginator.paginate(ParentId=root_id):
            all_ous.extend(page['OrganizationalUnits'])
            
        # Get child OUs recursively
        for ou in list(all_ous):  # Create a copy to iterate over
            child_ous = get_child_ous(organizations_client, ou['Id'])
            all_ous.extend(child_ous)
            
        return all_ous
        
    except ClientError as e:
        logger.error(f"Error retrieving OUs: {e}")
        return []

def get_child_ous(organizations_client, parent_id):
    """
    Get all child OUs for a given parent OU
    """
    child_ous = []
    try:
        paginator = organizations_client.get_paginator('list_organizational_units_for_parent')
        
        for page in paginator.paginate(ParentId=parent_id):
            current_child_ous = page['OrganizationalUnits']
            child_ous.extend(current_child_ous)
            
            # Recursively get children of these OUs
            for child_ou in current_child_ous:
                child_ous.extend(get_child_ous(organizations_client, child_ou['Id']))
                
        return child_ous
        
    except ClientError as e:
        logger.error(f"Error retrieving child OUs for {parent_id}: {e}")
        return []

def get_ou_arn(organizations_client, ou_id):
    """
    Get the ARN for an OU
    """
    try:
        response = organizations_client.describe_organizational_unit(
            OrganizationalUnitId=ou_id
        )
        return response['OrganizationalUnit']['Arn']
    except ClientError as e:
        logger.error(f"Error getting ARN for OU {ou_id}: {e}")
        return None

def re_register_ou(controltower_client, organizations_client, ou_id, ou_name):
    """
    Re-register an OU with Control Tower using reset_enabled_baseline
    """
    logger.info(f"Starting re-registration for OU: {ou_name} (ID: {ou_id})")
    
    # Get the OU ARN
    ou_arn = get_ou_arn(organizations_client, ou_id)
    if not ou_arn:
        logger.error(f"Could not get ARN for OU {ou_name}. Skipping.")
        return None
        
    # Get the enabled baseline ARN
    baseline_arn = get_enabled_baseline_arn(controltower_client, ou_arn)
    if not baseline_arn:
        logger.error(f"Could not get enabled baseline ARN for OU {ou_name}. Skipping.")
        return None
    
    try:
        # Using the reset_enabled_baseline API with the baseline ARN
        response = controltower_client.reset_enabled_baseline(
            enabledBaselineIdentifier=baseline_arn
        )
        operation_id = response['operationIdentifier']
        logger.info(f"Re-registration initiated for OU {ou_name}, Operation ID: {operation_id}")
        return operation_id
    except ClientError as e:
        logger.error(f"Error re-registering OU {ou_name}: {e}")
        return None
    
def get_enabled_baseline_arn(controltower_client, ou_arn):
    """
    Get the enabled baseline ARN for an OU
    """
    try:
        # List enabled baselines to find the one for this OU
        response = controltower_client.list_enabled_baselines()
        
        for baseline in response.get('enabledBaselines', []):
            # Check if this baseline is for our OU
            if baseline.get('targetIdentifier') == ou_arn:
                return baseline.get('arn')
                
        # If pagination is needed
        next_token = response.get('nextToken')
        while next_token:
            response = controltower_client.list_enabled_baselines(
                nextToken=next_token
            )
            
            for baseline in response.get('enabledBaselines', []):
                if baseline.get('targetIdentifier') == ou_arn:
                    return baseline.get('arn')
                    
            next_token = response.get('nextToken')
            
        logger.warning(f"No enabled baseline found for OU ARN: {ou_arn}")
        return None
        
    except ClientError as e:
        logger.error(f"Error getting enabled baseline for OU ARN {ou_arn}: {e}")
        return None

def enable_regions(regions_to_enable, controltower_client):
    """
    Update the AWS Control Tower landing zone to match the desired regions specified in the config file.
    
    Args:
        regions_to_enable (list): List of desired AWS regions from the config file.
    """
    if not regions_to_enable:
        logger.warning("=== No Regions Specified ===")
        logger.warning("No regions found in config.yaml. Please add regions to enable.")
        return

    # Step 1: Retrieve the current landing zone configuration
    logger.info("=== Re-registering Organizational Units ===")
    try:
        # Get the landing zone ARN
        landing_zone_response = controltower_client.list_landing_zones()
        landing_zones = landing_zone_response.get('landingZones', [])
        if not landing_zones:
            raise ValueError("No landing zones found.")
        if len(landing_zones) > 1:
            raise ValueError("Multiple landing zones found. Please specify which one to use.")
        landing_zone_arn = landing_zones[0]['arn']
        logger.info(f"=== Landing Zone ARN: {landing_zone_arn} ===")

        # Get the landing zone details
        landing_zone_details = controltower_client.get_landing_zone(landingZoneIdentifier=landing_zone_arn)
        landing_zone = landing_zone_details.get('landingZone', {})
        manifest = landing_zone.get('manifest', {})
        current_regions = manifest.get('governedRegions', [])
        landing_zone_version = landing_zone.get('version')
        logger.info(f"- Current Governed Regions: {', '.join(current_regions)}")
        logger.info(f"- Landing Zone Version: {landing_zone_version}\n")
    except Exception as e:
        logger.error(f"Error retrieving landing zone configuration: {e}")
        return

    # Step 2: Determine changes
    desired_regions = regions_to_enable
    current_regions_set = set(current_regions)
    desired_regions_set = set(desired_regions)
    regions_to_add = list(desired_regions_set - current_regions_set)
    regions_to_remove = list(current_regions_set - desired_regions_set)

    if not regions_to_add and not regions_to_remove:
        logger.info("=== No Changes Needed ===")
        logger.info("The governed regions already match the config file.\n")
        logger.info("Exiting...\n")
        exit()

    logger.info("=== Changes to Governed Regions ===")
    if regions_to_add:
        logger.info(f"- Adding regions: {', '.join(regions_to_add)}")
    if regions_to_remove:
        logger.info(f"- Removing regions: {', '.join(regions_to_remove)}")
    print()

    # Step 3: Update the manifest
    manifest['governedRegions'] = desired_regions

    # Step 4: Update the landing zone
    logger.info("=== Updating Landing Zone ===")
    try:
        update_response = controltower_client.update_landing_zone(
            landingZoneIdentifier=landing_zone_arn,
            version=landing_zone_version,
            manifest=manifest  
        )
        operation_id = update_response['operationIdentifier']
        logger.info(f"- Update initiated. Operation ID: {operation_id}")
        logger.info("- Monitoring operation status...\n")

        # Poll the operation status until completion
        while True:
            status_response = controltower_client.get_landing_zone_operation(
                operationIdentifier=operation_id
            )
            status = status_response['operationDetails']['status']
            if status == "SUCCEEDED":
                logger.info(f"- Operation succeeded successfully.\n")
                break
            elif status in ["FAILED", "CANCELLED", "ERROR"]:
                error_message = status_response['operation'].get('errorMessage', 'Unknown error')
                logger.error(f"- Operation failed: {error_message}\n")
                break
            else:
                # Status is likely IN_PROGRESS or PENDING
                logger.info(f"- Still in progress. Waiting...")
                time.sleep(60)
    except Exception as e:
        logger.error(f"Error updating landing zone: {e}\n")
        return

def check_registration_status(controltower_client, operation_id):
    """
    Check the status of a Control Tower operation
    """
    try:
        # Using get_enabled_baseline_operation to check the status
        response = controltower_client.get_baseline_operation(
            operationIdentifier=operation_id
        )
        status = response['baselineOperation']['status']
        logger.info(f"Operation {operation_id} status: {status}")
        return status
    except ClientError as e:
        logger.error(f"Error checking operation status for {operation_id}: {e}")
        return "ERROR"

def main():
    """
    Main function to read regions from config.yaml and enable them in AWS Control Tower.
    """
    # Read and parse the config.yaml file
    try:
        with open('config.yaml', 'r') as file:
            config = yaml.safe_load(file)
        regions_to_enable = config['regions']
        ous_to_skip = config['ous_to_skip']
        logger.info(f"- Regions from config.yaml: {', '.join(regions_to_enable)}")
        logger.info(f"- OUs to skip from config.yaml: {', '.join(ous_to_skip)}")
    except FileNotFoundError:
        logger.error("Error: config.yaml not found.")
        return
    except yaml.YAMLError as e:
        logger.error(f"Error parsing config.yaml: {e}")
        return
    except KeyError:
        logger.error("Error: key not found in config.yaml.")
        return
    
    # Initialize AWS clients
    organizations_client = boto3.client('organizations')

    controltower_client = boto3.client('controltower')

    # Enable the specified regions
    enable_regions(regions_to_enable, controltower_client)

    logger.info("Starting OU reset process...")
    # Get all OUs
    all_ous = get_all_ous(organizations_client)
    if not all_ous:
        logger.error("No OUs found or error retrieving OUs. Exiting.")
        return
    
    # Filter out core OUs
    ous_to_process = filter_core_ous(all_ous, ous_to_skip)
    if not ous_to_process:
        logger.error("No OUs to process after filtering. Exiting.")
        return
    
    # Process each OU one by one
    for ou in ous_to_process:
        ou_id = ou['Id']
        ou_name = ou['Name']
        
        # Re-register the OU
        operation_id = re_register_ou(controltower_client, organizations_client, ou_id, ou_name)
        if not operation_id:
            logger.error(f"Failed to initiate re-registration for OU {ou_name}. Skipping.")
            continue
        
        # Check status until completion
        while True:
            status = check_registration_status(controltower_client, operation_id)
            
            if status == "SUCCEEDED":
                logger.info(f"Re-registration of OU {ou_name} completed successfully")
                break
            elif status in ["FAILED", "CANCELLED", "ERROR"]:
                logger.error(f"Re-registration of OU {ou_name} failed with status: {status}")
                break
            else:
                # Status is likely IN_PROGRESS or PENDING
                logger.info(f"Re-registration of OU {ou_name} is still in progress. Waiting...")
                time.sleep(60)  # Wait for 60 seconds before checking again
    
    logger.info("OU re-registration process completed")

if __name__ == "__main__":
    main()

