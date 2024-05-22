#!/bin/bash

export PROJECT_ID="qwiklabs-gcp-01-6cf129908b08"
export REGION="us-central1"
export ZONE="us-central1-b"

# init terraform
terraform init

terraform import "module.gcs-instances.google_compute_instance.tf-instance-1" "$PROJECT_ID/$PNE/tf-instance-1"
terraform import "module.gcs-instances.google_compute_instance.tf-instance-2" "$PROJECT_ID/$PNE/tf-instance-2"

terraform plan
terraform apply

# 3
terraform init -migrate-state
