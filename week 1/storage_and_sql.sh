#!/bin/bash

ZONE="us-central1-c"
REGION="us-central1"
INSTANCE_NAME="bloghost"


# TASK 3
export LOCATION=US
gcloud storage buckets create -l $LOCATION gs://$DEVSHELL_PROJECT_ID
gcloud storage cp gs://cloud-training/gcpfci/my-excellent-blog.png gs://$DEVSHELL_PROJECT_ID/my-excellent-blog.png
gsutil acl ch -u allUsers:R gs://$DEVSHELL_PROJECT_ID/my-excellent-blog.png

# TASK 4
35.222.12.21
