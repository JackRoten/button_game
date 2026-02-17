#!/bin/bash
# Update ALLOWED_HOSTS after Elastic Beanstalk environment is created

set -e

if [ $# -lt 2 ]; then
    echo "Usage: $0 <eb-app-name> <eb-env-name>"
    exit 1
fi

EB_APP_NAME=$1
EB_ENV_NAME=$2

echo "Getting CNAME for environment $EB_ENV_NAME..."

# Get the CNAME from EB environment
CNAME=$(aws elasticbeanstalk describe-environments \
    --application-name "$EB_APP_NAME" \
    --environment-names "$EB_ENV_NAME" \
    --query 'Environments[0].CNAME' \
    --output text)

if [ -z "$CNAME" ] || [ "$CNAME" = "None" ]; then
    echo "Error: Could not get CNAME for environment"
    exit 1
fi

echo "Found CNAME: $CNAME"

# Get current ALLOWED_HOSTS value
CURRENT_HOSTS=$(aws elasticbeanstalk describe-configuration-settings \
    --application-name "$EB_APP_NAME" \
    --environment-name "$EB_ENV_NAME" \
    --query "ConfigurationSettings[0].OptionSettings[?Namespace=='aws:elasticbeanstalk:application:environment' && OptionName=='ALLOWED_HOSTS'].Value" \
    --output text)

echo "Current ALLOWED_HOSTS: $CURRENT_HOSTS"

# Add CNAME to ALLOWED_HOSTS if not already present
if [[ ! "$CURRENT_HOSTS" =~ "$CNAME" ]]; then
    NEW_HOSTS="${CURRENT_HOSTS},${CNAME}"
    
    echo "Updating ALLOWED_HOSTS to: $NEW_HOSTS"
    
    aws elasticbeanstalk update-environment \
        --application-name "$EB_APP_NAME" \
        --environment-name "$EB_ENV_NAME" \
        --option-settings \
            Namespace=aws:elasticbeanstalk:application:environment,OptionName=ALLOWED_HOSTS,Value="$NEW_HOSTS"
    
    echo "✅ ALLOWED_HOSTS updated successfully"
else
    echo "✅ CNAME already in ALLOWED_HOSTS, no update needed"
fi
