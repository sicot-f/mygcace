#!/bin/bash

REGION="us-west1"

NETWORK_NAME="mynetwork"

# task 1 - Create custom mode VPC networks with firewall rules
gcloud compute networks create privatenet --subnet-mode=custom
gcloud compute networks subnets create privatesubnet-us \
    --network=privatenet \
    --region=US_Region \
    --range=172.16.0.0/24
gcloud compute networks subnets create privatesubnet-eu \
    --network=privatenet \
    --region=EU_Region \
    --range=172.20.0.0/20

gcloud compute networks list
gcloud compute networks subnets list --sort-by=NETWORK

# firewall rules
gcloud compute firewall-rules create managementnet-allow-icmp-ssh-rdp \
    --direction=INGRESS \
    --network=managementnet \
    --allow=tcp:22,tcp:3389,icmp \
    --source-ranges=0.0.0.0/0 \
    --description="Allow incoming traffic on TCP port 80"

gcloud compute --project=qwiklabs-gcp-03-a4994ac2479e firewall-rules create managementnet-allow-icmp-ssh-rdp \
 --direction=INGRESS --priority=1000 \
 --network=managementnet \
 --action=ALLOW \
 --rules=tcp:22,tcp:3389,icmp \
 --source-ranges=0.0.0.0/0

gcloud compute firewall-rules create privatenet-allow-icmp-ssh-rdp \
    --direction=INGRESS \
    --priority=1000 \
    --network=privatenet \
    --action=ALLOW \
    --rules=icmp,tcp:22,tcp:3389 \
    --source-ranges=0.0.0.0/0


# Task 2. Create VM instances
gcloud compute instances create  managementnet-us-vm \
    --zone $ZONE \
    --region $REGION \
    --machine-type=e2-micro \

# gcloud compute machine-types list



mynet-eu-vm             34.79.212.165       10.132.0.2
managementnet-us-vm     34.139.88.107       10.130.0.2
privatenet-us-vm        34.75.106.215       172.16.0.2
