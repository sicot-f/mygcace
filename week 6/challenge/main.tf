terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "3.5.0"
    }
  }
}

provider "google" {

  project = var.project_id
  region  = var.region
  zone    = var.zone
}

# resource "google_compute_instance" "tf-instance-1" {}
# resource "google_compute_instance" "tf-instance-1" {
#   name         = "tf-instance-1"
#   machine_type = "e2-micro"
# 
#   boot_disk {
#     initialize_params {
#       image = "debian-cloud/debian-11"
#     }
#   }
# 
#   network_interface {
#     network = "default"
#     access_config {
#     }
#   }
#   metadata_startup_script = <<-EOT
#         #!/bin/bash
#     EOT
#   allow_stopping_for_update = true
# }
#resource "google_compute_instance" "tf-instance-2" {}

# metadata_startup_script = <<-EOT
#        #!/bin/bash
#    EOT
#allow_stopping_for_update = true


# module "gcs-static-website-bucket" {
#   source = "./modules/storage"
# 
#   name       = ""
#   project_id = var.project_id
#   location   = "REGION"
# }
# 
# terraform {
#   backend "gcs" {
#     bucket  = "# REPLACE WITH YOUR BUCKET NAME"
#     prefix  = "terraform/state"
#   }
# }

# 6
#module "test-vpc-module" {
#  source       = "terraform-google-modules/network/google"
#  version      = "6.0.0"
#  project_id   = var.project_id # Replace this with your project ID
#  network_name = ""
#  routing_mode = "GLOBAL"
#
#  subnets = [
#    {
#      subnet_name   = "subnet-01"
#      subnet_ip     = "10.10.10.0/24"
#      subnet_region         = var.region
#    },
#    {
#      subnet_name           = "subnet-02"
#      subnet_ip             = "10.10.20.0/24"
#      subnet_region         = var.Reion
#    },
#  ]
#}
#
# 7
#resource "google_compute_firewall" "default" {
#  name    = "test-firewall"
#  network = "projects/PROJECT_ID/global/networks/VPC Name"
#  source_ranges = "0.0.0.0/0"
#
#  allow {
#    protocol = "tcp"
#    ports    = ["80"]
#  }
#}


