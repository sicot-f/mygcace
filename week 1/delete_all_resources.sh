#!/bin/bash
# 
# A script to delete all endpoints for a given project
# Usage: ./delete-endpoints.sh project-id

PROJECT=$1

ENDPOINTS=($(gcloud --project=${PROJECT} endpoints services list --format="value(serviceName)"))
for i in "${ENDPOINTS[@]}"
do
        gcloud -q endpoints services delete $i --async
done
