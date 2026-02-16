#!/bin/bash

# Post-deployment script for Elastic Beanstalk
# This runs after the application is deployed

# Activate virtual environment
source /var/app/venv/*/bin/activate

# Navigate to application directory
cd /var/app/current

# Run any additional post-deployment tasks
echo "Post-deployment tasks completed successfully"
