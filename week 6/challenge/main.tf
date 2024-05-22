terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "4.53.0"
    }
  }
}

provider "google" {

  project = var.project_id
  region  = var.region
  zone    = var.zone
}

#module "gcs-instances" {
#  source = "./modules/instances"
#
#  zone       = var.zone
#  project_id = var.project_id
#  region     = var.region
#}

# module "gcs-state-storage" {
#   source = "./modules/storage"
# 
#   bucket_name = var.bucketname
#   zone       = var.zone
#   project_id = var.project_id
#   region     = var.region
# }
# 
# terraform {
#   backend "gcs" {
#     bucket  = "tf-bucket-748916"
#     prefix  = "terraform/state"
#   }
# }

# 6
# module "test-vpc-module" {
#   source       = "terraform-google-modules/network/google"
#   version      = "6.0.0"
#   project_id   = var.project_id # Replace this with your project ID
#   network_name = var.vpcname
#   routing_mode = "GLOBAL"
# 
#   subnets = [
#     {
#       subnet_name   = "subnet-01"
#       subnet_ip     = "10.10.10.0/24"
#       subnet_region         = var.region
#     },
#     {
#       subnet_name           = "subnet-02"
#       subnet_ip             = "10.10.20.0/24"
#       subnet_region         = var.region
#     },
#   ]
# }

# 7
#resource "google_compute_firewall" "default" {
#  name    = var.firewall_name
#  network = "projects/PROJECT_ID/global/networks/VPC Name"
#  source_ranges = "0.0.0.0/0"
#
#  allow {
#    protocol = "tcp"
#    ports    = ["80"]
#  }
#}


