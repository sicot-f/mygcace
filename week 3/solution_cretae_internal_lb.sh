export REGION=

export ZONE=

export ZONE2=

# Create a firewall rule to allow HTTP traffic on the 'my-internal-app' network for the 'lb-backend' target tags.
gcloud compute firewall-rules create app-allow-http --network my-internal-app --action allow --direction INGRESS --target-tags lb-backend --source-ranges 0.0.0.0/0 --rules tcp:80

# Create a firewall rule to allow health check traffic on the default network for the 'lb-backend' target tags.
gcloud compute firewall-rules create app-allow-health-check --network default --action allow --direction INGRESS --target-tags lb-backend --source-ranges 130.211.0.0/22,35.191.0.0/16 --rules tcp

# Create an instance template 'instance-template-1' with specific settings.
gcloud compute instance-templates create instance-template-1 --machine-type=e2-medium --network=my-internal-app --region $REGION --subnet=subnet-a --tags=lb-backend --metadata=startup-script-url=gs://cloud-training/gcpnet/ilb/startup.sh

# Create another instance template 'instance-template-2' with specific settings.
gcloud compute instance-templates create instance-template-2 --machine-type=e2-medium --network=my-internal-app --region $REGION --subnet=subnet-b --tags=lb-backend --metadata=startup-script-url=gs://cloud-training/gcpnet/ilb/startup.sh

# Create a managed instance group 'instance-group-1' based on 'instance-template-1'.
gcloud compute instance-groups managed create instance-group-1 --base-instance-name=instance-group-1 --template=instance-template-1 --zone=$ZONE --size=1

# Configure autoscaling for 'instance-group-1'.
gcloud compute instance-groups managed set-autoscaling instance-group-1 --zone=$ZONE --cool-down-period=45 --max-num-replicas=5 --min-num-replicas=1 --target-cpu-utilization=0.8

# Create another managed instance group 'instance-group-2' based on 'instance-template-2'.
gcloud compute instance-groups managed create instance-group-2 --base-instance-name=instance-group-2 --template=instance-template-2 --zone=$ZONE2 --size=1

# Configure autoscaling for 'instance-group-2'.
gcloud compute instance-groups managed set-autoscaling instance-group-2 --zone=$ZONE2 --cool-down-period=45 --max-num-replicas=5 --min-num-replicas=1 --target-cpu-utilization=0.8

# Create a utility VM instance.
gcloud compute instances create utility-vm --zone=$ZONE --machine-type=e2-micro --image-family=debian-10 --image-project=debian-cloud --boot-disk-size=10GB --boot-disk-type=pd-standard --network=my-internal-app --subnet=subnet-a --private-network-ip=10.10.20.50

# Create a health check for load balancing.
gcloud compute health-checks create tcp my-ilb-health-check \
--description="Subscribe To CloudHustlers" \
--check-interval=5s \
--timeout=5s \
--unhealthy-threshold=2 \
--healthy-threshold=2 \
--port=80 \
--proxy-header=NONE

# Obtain an access token.
TOKEN=$(gcloud auth application-default print-access-token)

# Create a JSON configuration file for the backend service.
cat > 1.json <<EOF
{
    "backends": [
      {
        "balancingMode": "CONNECTION",
        "group": "projects/$DEVSHELL_PROJECT_ID/zones/$ZONE/instanceGroups/instance-group-1"
      },
      {
        "balancingMode": "CONNECTION",
        "group": "projects/$DEVSHELL_PROJECT_ID/zones/$ZONE2/instanceGroups/instance-group-2"
      }
    ],
    "connectionDraining": {
      "drainingTimeoutSec": 300
    },
    "description": "",
    "healthChecks": [
      "projects/$DEVSHELL_PROJECT_ID/global/healthChecks/my-ilb-health-check"
    ],
    "loadBalancingScheme": "INTERNAL",
    "logConfig": {
      "enable": false
    },
    "name": "my-ilb",
    "network": "projects/$DEVSHELL_PROJECT_ID/global/networks/my-internal-app",
    "protocol": "TCP",
    "region": "projects/$DEVSHELL_PROJECT_ID/regions/$REGION",
    "sessionAffinity": "NONE"
  }
EOF

# Create a JSON configuration file for the forwarding rule.
cat > 2.json <<EOF
{
   "IPAddress": "10.10.30.5",
   "loadBalancingScheme": "INTERNAL",
   "allowGlobalAccess": false,
   "description": "SUBSCRIBE TO CLOUDHUSTLER",
   "ipVersion": "IPV4",
   "backendService": "projects/$DEVSHELL_PROJECT_ID/regions/$REGION/backendServices/my-ilb",
   "IPProtocol": "TCP",
   "networkTier": "PREMIUM",
   "name": "my-ilb-forwarding-rule",
   "ports": [
     "80"
   ],
   "region": "projects/$DEVSHELL_PROJECT_ID/regions/$REGION",
   "subnetwork": "projects/$DEVSHELL_PROJECT_ID/regions/$REGION/subnetworks/subnet-b"
 }
EOF

# Create the backend service with the JSON configuration.
curl -X POST -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d  @1.json \
  "https://compute.googleapis.com/compute/v1/projects/$DEVSHELL_PROJECT_ID/regions/$REGION/backendServices"

# Wait for 20 seconds.
sleep 20

# Create the forwarding rule with the JSON configuration.
curl -X POST -H "Content-Type: application/json" \
 -H "Authorization: Bearer $TOKEN" \
 -d @2.json \
 "https://compute.googleapis.com/compute/v1/projects/$DEVSHELL_PROJECT_ID/regions/$REGION/forwardingRules"
