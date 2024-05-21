#!/bin/bash

export PROJECT_ID=""
export REGION=""
export ZONE=""

# copy variables
cp variables.tf modules/storage/
cp variables.tf modules/instances/

# init terraform
terraform init

terraform import module.instances.google_compute_instance.tf-instance-1 "$PROJECT_ID/$PNE/tf-instance-1"ZO
terraform import module.instances.google_compute_instance.tf-instance-2 "$PROJECT_ID/$ZPNE/tf-instance-2"

terraform plan
terraform apply

# 3
terraform init -migrate-state

# 6
module "test-vpc-module" {
  source       = "terraform-google-modules/network/google"
  version      = "6.0.0"
  project_id   = var.project_id # Replace this with your project ID
  network_name = ""
  routing_mode = "GLOBAL"

  subnets = [
    {
      subnet_name   = "subnet-01"
      subnet_ip     = "10.10.10.0/24"
      subnet_region         = var.region
    },
    {
      subnet_name           = "subnet-02"
      subnet_ip             = "10.10.20.0/24"
      subnet_region         = var.Reion
    },
  ]
}

# 7
resource "google_compute_firewall" "default" {
  name    = "test-firewall"
  network = "projects/PROJECT_ID/global/networks/VPC Name"
  source_ranges = "0.0.0.0/0"

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_tags = ["web"]
}
