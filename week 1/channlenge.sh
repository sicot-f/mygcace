#!/bin/bash

INSTANCE_NAME="nucleus-jumphost-213"
FIREWALL_RULE="accept-tcp-rule-763"
ZONE="us-west1-c"
REGION="us-west1"
PRT_NUMBER=8083

PROJECT_NAME="nucleus"
INSTANCE_TEMPLATE_NAME="$PROJECT_NAME-instance-template"
MANAGED_GROUP_NAME="$PROJECT_NAME-managed-group"
HEALTH_CHECK_NAME="$PROJECT_NAME-health-check"
BACKEND_SERVICE_NAME="$PROJECT_NAME-backend-service"
URL_MAP_NAME="$PROJECT_NAME-url-map"
HTTP_PROXY_NAME="$PROJECT_NAME-http-proxy"
LB_ADDRESS_NAME="$PROJECT_NAME-lb-address"
FORWARD_RULE_NAME="$PROJECT_NAME-forward-rule"

# Task 1 - Create a project jumphost instance
gcloud compute instances create $INSTANCE_NAME \
    --machine-type=e2-micro \
    --zone="$ZONE"

# Task 2. Set up an HTTP load balancer

## startup script
cat << EOF > startup.sh
#! /bin/bash
apt-get update
apt-get install -y nginx
service nginx start
sed -i -- 's/nginx/Google Cloud Platform - '"\$HOSTNAME"'/' /var/www/html/index.nginx-debian.html
EOF

## Create an instance template. 
## Don't use the default machine type. Make sure you specify e2-medium as the machine type.
gcloud compute instance-templates create $INSTANCE_TEMPLATE_NAME \
    --machine-type=e2-medium \
    --tags=allow-health-check \
    --metadata-from-file startup-script=startup.sh

## Create a managed instance group based on the template.
gcloud compute instance-groups managed create $MANAGED_GROUP_NAME \
   --template=$INSTANCE_TEMPLATE_NAME \
   --size=2 \
   --region $REGION

## Create a firewall rule 
gcloud compute firewall-rules create "$FIREWALL_RULE" \
            --allow=tcp:80 \
            --description="Allow incoming traffic on TCP port 80" \
            --direction=INGRESS \
            --target-tags=allow-health-check
#             --source-ranges=130.211.0.0/22,35.191.0.0/16 \

# TODO: test IP
# TODO: rajouter source range après

## Create a health check.
gcloud compute health-checks create http $HEALTH_CHECK_NAME

## Create a backend service and add your instance group as the backend to the backend
## service group with named port (http:80).
gcloud compute instance-groups managed set-named-ports $MANAGED_GROUP_NAME \
    --named-ports http:80 \
    --region $REGION

gcloud compute backend-services create $BACKEND_SERVICE_NAME \
  --protocol=HTTP \
  --health-checks=nucleus-http-health \
  --global
  # --port-name=http \
 

gcloud compute backend-services add-backend $BACKEND_SERVICE_NAME \
  --instance-group=$MANAGED_GROUP_NAME \
  --instance-group-zone="$ZONE" \
  --global

## Create a URL map, and target the HTTP proxy to route the incoming 
## requests to the default backend service.
gcloud compute url-maps create $URL_MAP_NAME \
    --default-service $BACKEND_SERVICE_NAME

## Create a target HTTP proxy to route requests to your URL map
gcloud compute target-http-proxies create $HTTP_PROXY_NAME \
    --url-map $URL_MAP_NAME

## Create a forwarding rule.
### create static IP adress
gcloud compute addresses create $LB_ADDRESS_NAME \
  --ip-version=IPV4 \
  --global
LB_IP_ADDRESS=$(gcloud compute addresses describe $LB_ADDRESS_NAME \
  --format="get(address)" \
  --global)  

  gcloud compute forwarding-rules create $FORWARD_RULE_NAME \
   --address="$LB_IP_ADDRESS" \
   --global \
   --target-http-proxy=$HTTP_PROXY_NAME \
   --ports=80


#gcloud compute instance-groups managed set-named-ports nucleus-backend-group --named-ports=nucleus-port:8081
#gcloud compute backend-services update nucleus-backend-service \
#    --port-name=my-nucleus-port
