#!/bin/bash
# Update ALLOWED_HOSTS after Elastic Beanstalk environment is created

set -e

if [ $# -lt 3 ]; then
    echo "Usage: $0 <eb-app-name> <eb-env-name> <custom-domain>"
    exit 1
fi

EB_APP_NAME=$1
EB_ENV_NAME=$2
CUSTOM_DOMAIN=$3

echo "============================================"
echo "Updating ALLOWED_HOSTS for $EB_ENV_NAME"
echo "============================================"

# Wait for environment to be ready
echo "Waiting for environment to be ready..."
aws elasticbeanstalk wait environment-updated \
    --application-name "$EB_APP_NAME" \
    --environment-names "$EB_ENV_NAME" 2>/dev/null || {
    echo "⚠️  Environment may not be fully ready yet"
}

# Wait a bit more for CNAME to be available
sleep 10

# Get the CNAME from EB environment with retries
MAX_RETRIES=5
RETRY_COUNT=0
CNAME=""

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    echo "Attempting to get CNAME (attempt $((RETRY_COUNT + 1))/$MAX_RETRIES)..."
    
    CNAME=$(aws elasticbeanstalk describe-environments \
        --application-name "$EB_APP_NAME" \
        --environment-names "$EB_ENV_NAME" \
        --query 'Environments[0].CNAME' \
        --output text 2>/dev/null || echo "")
    
    # Check if we got a valid CNAME
    if [ -n "$CNAME" ] && [ "$CNAME" != "None" ] && [ "$CNAME" != "null" ]; then
        echo "✅ Found CNAME: $CNAME"
        break
    fi
    
    RETRY_COUNT=$((RETRY_COUNT + 1))
    if [ $RETRY_COUNT -lt $MAX_RETRIES ]; then
        echo "Waiting 15 seconds before retry..."
        sleep 15
    fi
done

# Check if we got a valid CNAME
if [ -z "$CNAME" ] || [ "$CNAME" = "None" ] || [ "$CNAME" = "null" ]; then
    echo "❌ Could not retrieve CNAME after $MAX_RETRIES attempts"
    echo ""
    echo "This is not critical - your application will still work via: $CUSTOM_DOMAIN"
    echo "Django settings automatically allow *.elasticbeanstalk.com domains"
    echo ""
    echo "You can run this script again later after the environment is fully ready:"
    echo "  $0 $EB_APP_NAME $EB_ENV_NAME $CUSTOM_DOMAIN"
    exit 0
fi

# Get current ALLOWED_HOSTS value
echo "Getting current ALLOWED_HOSTS..."
CURRENT_HOSTS=$(aws elasticbeanstalk describe-configuration-settings \
    --application-name "$EB_APP_NAME" \
    --environment-name "$EB_ENV_NAME" \
    --query "ConfigurationSettings[0].OptionSettings[?Namespace=='aws:elasticbeanstalk:application:environment' && OptionName=='ALLOWED_HOSTS'].Value" \
    --output text 2>/dev/null || echo "$CUSTOM_DOMAIN")

echo "Current ALLOWED_HOSTS: $CURRENT_HOSTS"

# Check if CNAME is already in ALLOWED_HOSTS
if echo "$CURRENT_HOSTS" | grep -q "$CNAME"; then
    echo "✅ CNAME already in ALLOWED_HOSTS, no update needed"
    exit 0
fi

# Create new ALLOWED_HOSTS value
NEW_HOSTS="$CUSTOM_DOMAIN,$CNAME"

echo "Updating ALLOWED_HOSTS to: $NEW_HOSTS"

# Update the environment variable
aws elasticbeanstalk update-environment \
    --application-name "$EB_APP_NAME" \
    --environment-name "$EB_ENV_NAME" \
    --option-settings \
        "Namespace=aws:elasticbeanstalk:application:environment,OptionName=ALLOWED_HOSTS,Value=$NEW_HOSTS"

echo ""
echo "✅ ALLOWED_HOSTS updated successfully!"
echo ""
echo "Your application is now accessible via:"
echo "  - https://$CUSTOM_DOMAIN (custom domain)"
echo "  - http://$CNAME (Elastic Beanstalk CNAME)"
echo "============================================"

