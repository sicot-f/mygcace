#!/bin/bash

PROJECT_ID="qwiklabs-gcp-02-86f14de4afa9"
BUCKET_NAME=$PROJECT_ID
REGION="us-central1"

gcloud config set compute/region "$REGION"


# bucket
gsutil mb -p "$PROJECT_ID" gs://"$BUCKET_NAME"

# deploy
cd gcf_hello_world || exit
gcloud services disable cloudfunctions.googleapis.com
gcloud services enable cloudfunctions.googleapis.com
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
    --member="serviceAccount:$PROJECT_ID@appspot.gserviceaccount.com" \
    --role="roles/artifactregistry.reader"
gcloud functions deploy helloWorld \
  --stage-bucket "$BUCKET_NAME" \
  --trigger-topic hello_world \
  --runtime nodejs20
gcloud functions describe helloWorld

# test function
DATA=$(printf 'Hello World!'|base64) && gcloud functions call helloWorld --data '{"data":"'$DATA'"}'

# check logs
gcloud functions logs read helloWorld

