#!/bin/bash

# https://cloud.google.com/load-balancing/docs/internal/setting-up-internal

PROJECT_ID=""
PROJECT_NUMBER=""
REGION=""
ZONE1=""
ZONE2=""

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
    --network "default" \
    --action allow \
    --direction ingress \
    --source-ranges 130.211.0.0/22,35.191.0.0/16 \
    --description "Allow incoming traffic on helath checks" \
    --target-tags $LB_TAGS \
    --rules tcp

## Create an instance template. 
gcloud compute instance-templates create instance-template-1 \
    --machine-type=e2-medium \
    --tags=$LB_TAGS \
    --metadata=startup-script-url=gs://cloud-training/gcpnet/ilb/startup.sh \
    --network $NETWORK_NAME \
    --subnet "subnet-a"
gcloud compute instance-templates create instance-template-2 \
    --machine-type e2-medium \
    --tags $LB_TAGS \
    --metadata startup-script-url=gs://cloud-training/gcpnet/ilb/startup.sh \
    --network $NETWORK_NAME \
    --subnet "subnet-b"


## Create managed instance group based on the template.
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
   --member serviceAccount:service-"$PROJECT_NUMBER"@compute-system.iam.gserviceaccount.com \
   --role roles/compute.serviceAgent

gcloud compute instance-groups managed create instance-group-1 \
   --template=instance-template-1 \
   --zone="$ZONE1" \
   --size 1
gcloud compute instance-groups managed set-autoscaling instance-group-1 \
    --max-num-replicas 5 \
    --min-num-replicas 1 \
    --target-cpu-utilization 0.80 \
    --cool-down-period 45

gcloud compute instance-groups managed create instance-group-2 \
   --template=instance-template-2 \
   --zone="$ZONE2" \
   --size 1
gcloud compute instance-groups managed set-autoscaling instance-group-2 \
    --max-num-replicas 5 \
    --min-num-replicas 1 \
    --target-cpu-utilization 0.80 \
    --cool-down-period 45

gcloud compute instances create utility-vm \
    --zone "$ZONE1" \
    --machine-type e2-micro \
    --network my-internal-app \
    --subnet subnet-a \
    --address 10.10.20.50

# create load balancer

gcloud compute health-checks create tcp my-ilb-health-check \
    --port 80 \
    --region "$REGION"
 gcloud compute backend-services create lb_backend_services \
    --health-checks my-ilb-health-check \
    --load-balancing-scheme INTERNAL \
    --protocol TCP \
    --region "$REGION" \
    --network my-internal-app
gcloud compute backend-services add-backend lb_backend_services \
    --instance-group=instance-group-2 \
    --balancing-mode=CONNECTION

# frontend
gcloud compute forwarding-rules create my-ilb \
    --region "$REGION" \
    --load-balancing-scheme=internal \
    --network my-internal-app \
    --subnet subnet-b \
    --address=10.10.30.5 \
    --ip-protocol=TCP \
    --ports=80 \
    --backend-service=lb_backend_services \
    --backend-service-region="$REGION"
