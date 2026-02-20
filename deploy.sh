#!/bin/bash

# Check if project ID is provided
if [ -z "$1" ]; then
    echo "Usage: ./deploy.sh <GCP_PROJECT_ID>"
    exit 1
fi

PROJECT_ID=$1
export TF_VAR_project=$PROJECT_ID

echo "Initializing Terraform..."
cd terraform
terraform init

echo "Building infrastructure..."
terraform apply -auto-approve

# Get outputs
MASTER_IP=$(terraform output -raw master_ip)
WORKER_IPS=$(terraform output -raw worker_ips)
BUCKET_NAME=$(terraform output -raw bucket_name)

echo "------------------------------------------------"
echo "Infrastructure built successfully!"
echo "Master IP: $MASTER_IP"
echo "Worker IPs: $WORKER_IPS"
echo "Bucket Name: $BUCKET_NAME"
echo "------------------------------------------------"
echo "Follow the instructions in README.md to deploy the code and run the task."
