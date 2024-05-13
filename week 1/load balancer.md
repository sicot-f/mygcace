# load balancer

1. create ip address for lb

gcloud compute addresses create network-lb-ip-1 \
  --region europe-west4

2. create helth check

gcloud compute http-health-checks create basic-check

3. create target pool (lb) with health check and add instances

gcloud compute target-pools create www-pool \
  --region europe-west4 --http-health-check basic-check
gcloud compute target-pools add-instances www-pool \
    --instances www1,www2,www3

4. add forwarding rule

gcloud compute forwarding-rules create www-rule \
    --region  europe-west4 \
    --ports 80 \
    --address network-lb-ip-1 \
    --target-pool www-pool


# http lb

1. create tempalte

gcloud compute instance-templates create lb-backend-template \
   --region=europe-west4 \
   --network=default \
   --subnet=default \
   --tags=allow-health-check \
   --machine-type=e2-medium \
   --image-family=debian-11 \
   --image-project=debian-cloud \
   --metadata=startup-script='#!/bin/bash
     apt-get update
     apt-get install apache2 -y
     a2ensite default-ssl
     a2enmod ssl
     vm_hostname="$(curl -H "Metadata-Flavor:Google" \
     http://169.254.169.254/computeMetadata/v1/instance/name)"
     echo "Page served from: $vm_hostname" | \
     tee /var/www/html/index.html
     systemctl restart apache2'


gcloud compute instances create nucleus-jumphost-477 --machine-type=e2-micro --zone=us-east1-d

cat << EOF > startup.sh
#! /bin/bash
apt-get update
apt-get install -y nginx
service nginx start
sed -i -- 's/nginx/Google Cloud Platform - '"\$HOSTNAME"'/' /var/www/html/index.nginx-debian.html
EOF

gcloud compute instance-templates create nucleus-backend-templatelocal \
  --machine-type=e2-medium \
  --tags=allow-health-check \
  --metadata=startup-script=./startup.sh

gcloud compute instance-groups managed create nucleus-backend-group \
   --template=nucleus-backend-templatelocal --size=2 --zone=us-east1-d

gcloud compute firewall-rules create accept-tcp-rule-204 \
            --allow=tcp:80 \
            --description="Allow incoming traffic on TCP port 80" \
            --direction=INGRESS \
            --target-tags=allow-health-check
#             --source-ranges=130.211.0.0/22,35.191.0.0/16 \

test IP
rajouter source range après

gcloud compute health-checks create http nucleus-http-health

gcloud compute backend-services create nucleus-backend-service \
  --protocol=HTTP \
  --port-name=http \
  --health-checks=nucleus-http-health \
  --global
gcloud compute backend-services add-backend nucleus-backend-service \
  --instance-group=nucleus-backend-group \
  --instance-group-zone=us-east1-d \
  --global

gcloud compute url-maps create nucleus-map-http \
    --default-service nucleus-backend-service


gcloud compute target-http-proxies create nucleus-lb-proxy \
    --url-map nucleus-map-http


gcloud compute addresses create nucleus-lb-ipv4-1 \
  --ip-version=IPV4 \
  --global

  gcloud compute forwarding-rules create nucleus-http-content-rule \
   --address=nucleus-lb-ipv4-1\
   --global \
   --target-http-proxy=nucleus-lb-proxy \
   --ports=80


gcloud compute instance-groups managed set-named-ports nucleus-backend-group --named-ports=nucleus-port:8081
gcloud compute backend-services update nucleus-backend-service \
    --port-name=my-nucleus-port
