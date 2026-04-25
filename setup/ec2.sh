#!/bin/bash
LOG_FILE="/home/ubuntu/script.log"
exec > >(tee -a $LOG_FILE) 2>&1

BUCKET_NAME_PARAM="s3_bucket_name"
OBJECT_KEY_PARAM="s3_object_key"

ACCOUNT_ID=""
ROLE_ARN=""
DATASTORE_ID=""
REGION=""
DOCKER_IMAGE_TAG=""

aws configure set region $REGION

BUCKET_NAME=$1
OBJECT_KEY=$2

INPUT_PATH="/home/ubuntu/input"
OUTPUT_PATH="/home/ubuntu/output"
mkdir -p $INPUT_PATH
mkdir -p $OUTPUT_PATH
sudo rm -rf $INPUT_PATH/*
sudo rm -rf $OUTPUT_PATH/*

aws s3 cp "s3://$BUCKET_NAME/$OBJECT_KEY" "$INPUT_PATH/$(basename $OBJECT_KEY)"

if [ -f "$INPUT_PATH/$(basename $OBJECT_KEY)" ]; then
    echo "File downloaded successfully to $INPUT_PATH"
else
    echo "Failed to download the file from S3"
    exit 1
fi

FILE_EXTENSION="${OBJECT_KEY##*.}"
if [ "$FILE_EXTENSION" == "zip" ]; then
    echo "The file is a zip file. Unzipping..."
    unzip "$INPUT_PATH/$(basename $OBJECT_KEY)" -d $INPUT_PATH
    rm "$INPUT_PATH/$(basename $OBJECT_KEY)"
    if [ $? -ne 0 ]; then
        echo "Failed to unzip the file"
        exit 1
    fi
fi

aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com
docker pull $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$DOCKER_IMAGE_TAG

source /home/ubuntu/monai/bin/activate
monai-deploy run $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$DOCKER_IMAGE_TAG -i $INPUT_PATH -o $OUTPUT_PATH

BASE_NAME=$(basename "$OBJECT_KEY" .zip)
aws s3 cp $OUTPUT_PATH s3://$BUCKET_NAME/results/$BASE_NAME/ --recursive

if [ "$FILE_EXTENSION" == "zip" ]; then
    aws s3 cp $INPUT_PATH s3://$BUCKET_NAME/inferred/$BASE_NAME/ --recursive
    aws s3 rm s3://$BUCKET_NAME/$OBJECT_KEY
else
    aws s3 mv s3://$BUCKET_NAME/$OBJECT_KEY s3://$BUCKET_NAME/inferred/$(basename $OBJECT_KEY)
fi

aws medical-imaging start-dicom-import-job \
    --job-name "my-dicom-import-job" \
    --datastore-id "$DATASTORE_ID" \
    --data-access-role-arn "$ROLE_ARN" \
    --input-s3-uri "s3://$BUCKET_NAME/results/$BASE_NAME/" \
    --output-s3-uri "s3://$BUCKET_NAME/HealthImaging/"

attempt=1
max_attempts=10
while [ $attempt -le $max_attempts ]; do
    result=$(aws medical-imaging start-dicom-import-job \
        --job-name "my-dicom-import-job" \
        --datastore-id "$DATASTORE_ID" \
        --data-access-role-arn "$ROLE_ARN" \
        --input-s3-uri "s3://$BUCKET_NAME/input/$BASE_NAME/" \
        --output-s3-uri "s3://$BUCKET_NAME/HealthImaging/" 2>&1)
    if [[ $result == *"Too Many Requests"* ]]; then
        retry=$((attempt * 10))
        echo "Throttling exception encountered. Retrying in $retry seconds..."
        sleep $retry
        attempt=$((attempt + 1))
    else
        echo "DICOM import job started successfully."
        break
    fi
done