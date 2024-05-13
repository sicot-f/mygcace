#!/bin/bash

REGION="us-west1"

export NETWORK_NAME="my-internal-app"
export LB_TAGS="lb-backend"

# Create the HTTP firewall rule
gcloud compute firewall-rules create app-allow-http\
    --network=$NETWORK_NAME \
    --allow=tcp:80 \
    --source-ranges=0.0.0.0/0 \
    --description="Allow incoming traffic on TCP port 80" \
    --target-tags=$LB_TAGS

# Create the health check firewall rules
gcloud compute firewall-rules create app-allow-health-check \
    --network=$NETWORK_NAME \
    --action=allow \
    --direction=ingress \
    --source-ranges=130.211.0.0/22,35.191.0.0/16 \
    --description="Allow incoming traffic on helath checks" \
    --target-tags=$LB_TAGS \
    --rules=tcp

## Create an instance template. 
gcloud compute instance-templates create instance-template-1 \
    --machine-type=e2-medium \
    --tags=$LB_TAGS \
    --metadata=startup-script-url=gs://cloud-training/gcpnet/ilb/startup.sh \
    --network=$NETWORK_NAME \
    --subnet="subnet-a" \
    --region=$REGION
gcloud compute instance-templates create instance-template-2 \
    --machine-type=e2-medium \
    --tags=$LB_TAGS \
    --metadata=startup-script-url=gs://cloud-training/gcpnet/ilb/startup.sh \
    --network=$NETWORK_NAME \
    --subnet="subnet-b"


## Create a managed instance group based on the template.
gcloud compute instance-groups managed create instance-group-1 \
   --template=instance-template-1 \
   --size=2 \
   --zone="$ZONE"





