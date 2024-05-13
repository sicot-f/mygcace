#!/bin/bash

PROJECT_ID="qwiklabs-gcp-02-95312759aa28"
BUCKET_NAME="qwiklabs-gcp-02-95312759aa28-bucket"
BUCKET_FUNCTION_NAME="${PROJECT_ID}_myfunc"
REGION="us-central1"
REGION_CAPITAL="US-CENTRAL1"
ZONE="us-central1-a"
TOPIC_NAME="topic-memories-525"
CLOUD_FUNCTOIN_NAME="memories-thumbnail-creator"
TEAM="kraken"
CHALLENGE_FOLDER="challenge_function"

gcloud config set compute/region "$REGION"
gcloud config set compute/zone "$ZONE"
gcloud config set functions/region "$REGION"
gcloud config set functions/zone "$ZONE"

# Task 1 - Create a bucket
gsutil mb -p "$PROJECT_ID" -l "$REGION_CAPITAL" gs://"$BUCKET_NAME"
gsutil mb -p "$PROJECT_ID" -l "$REGION_CAPITAL" gs://"$BUCKET_FUNCTION_NAME"

# Task 2 - Create a Pub/Sub topic
gcloud pubsub topics create "$TOPIC_NAME"

# Task 3 - Create the thumbnail Cloud Function
mkdir $CHALLENGE_FOLDER
cd $CHALLENGE_FOLDER || exit
cat > index.js << EOF
const functions = require('@google-cloud/functions-framework');
const crc32 = require("fast-crc32c");
const { Storage } = require('@google-cloud/storage');
const gcs = new Storage();
const { PubSub } = require('@google-cloud/pubsub');
const imagemagick = require("imagemagick-stream");

functions.cloudEvent('', cloudEvent => {
  const event = cloudEvent.data;

  console.log(`Event: ${event}`);
  console.log(`Hello ${event.bucket}`);

  const fileName = event.name;
  const bucketName = event.bucket;
  const size = "64x64"
  const bucket = gcs.bucket(bucketName);
  const topicName = "";
  const pubsub = new PubSub();
  const port = process.env.PORT || 8080;
  app.listen(port, () => {
    console.log('Hello world listening on port', port);
  });
  if ( fileName.search("64x64_thumbnail") == -1 ){
    // doesn't have a thumbnail, get the filename extension
    var filename_split = fileName.split('.');
    var filename_ext = filename_split[filename_split.length - 1];
    var filename_without_ext = fileName.substring(0, fileName.length - filename_ext.length );
    if (filename_ext.toLowerCase() == 'png' || filename_ext.toLowerCase() == 'jpg'){
      // only support png and jpg at this point
      console.log(`Processing Original: gs://${bucketName}/${fileName}`);
      const gcsObject = bucket.file(fileName);
      let newFilename = filename_without_ext + size + '_thumbnail.' + filename_ext;
      let gcsNewObject = bucket.file(newFilename);
      let srcStream = gcsObject.createReadStream();
      let dstStream = gcsNewObject.createWriteStream();
      let resize = imagemagick().resize(size).quality(90);
      srcStream.pipe(resize).pipe(dstStream);
      return new Promise((resolve, reject) => {
        dstStream
          .on("error", (err) => {
            console.log(`Error: ${err}`);
            reject(err);
          })
          .on("finish", () => {
            console.log(`Success: ${fileName} → ${newFilename}`);
              // set the content-type
              gcsNewObject.setMetadata(
              {
                contentType: 'image/'+ filename_ext.toLowerCase()
              }, function(err, apiResponse) {});
              pubsub
                .topic(topicName)
                .publisher()
                .publish(Buffer.from(newFilename))
                .then(messageId => {
                  console.log(`Message ${messageId} published.`);
                })
                .catch(err => {
                  console.error('ERROR:', err);
                });
          });
      });
    }
    else {
      console.log(`gs://${bucketName}/${fileName} is not an image I can handle`);
    }
  }
  else {
    console.log(`gs://${bucketName}/${fileName} already has a thumbnail`);
  }
});
EOF

cat > package.json << EOF
{
  "name": "thumbnails",
  "version": "1.0.0",
  "description": "Create Thumbnail of uploaded image",
  "scripts": {
    "start": "node index.js"
  },
  "dependencies": {
    "@google-cloud/functions-framework": "^3.0.0",
    "@google-cloud/pubsub": "^2.0.0",
    "@google-cloud/storage": "^5.0.0",
    "fast-crc32c": "1.0.4",
    "imagemagick-stream": "4.1.1"
  },
  "devDependencies": {},
  "engines": {
    "node": ">=4.3.2"
  }
}
EOF

gcloud services disable cloudfunctions.googleapis.com
gcloud services enable cloudfunctions.googleapis.com
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
    --member="serviceAccount:$PROJECT_ID@appspot.gserviceaccount.com" \
    --role="roles/artifactregistry.reader"
gcloud functions deploy "$CLOUD_FUNCTOIN_NAME" \
    --gen2 \
    --region="$REGION" \
    --source=. \
    --trigger-event=providers/cloud.storage/eventTypes/object.change \
    --trigger-resource=$BUCKET_NAME \
    --stage-bucket=$BUCKET_FUNCTION_NAME \
    --runtime nodejs20
