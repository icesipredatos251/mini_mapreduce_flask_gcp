#!/bin/bash

# Check if project ID is provided
if [ -z "$1" ]; then
    echo "Usage: ./cleanup.sh <GCP_PROJECT_ID>"
    exit 1
fi

PROJECT_ID=$1
export TF_VAR_project=$PROJECT_ID

echo "Destroying infrastructure..."
cd terraform
terraform destroy -auto-approve

echo "Infrastructure destroyed."
