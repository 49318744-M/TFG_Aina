#!/bin/bash
ACCOUNT_ID=""
ROLE_ARN=""
DATASTORE_ID=""
REGION=""
DOCKER_IMAGE_TAG=""

BUCKET_NAME=$1
OBJECT_KEY=$2

# 1. Login en ECR
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com

# 2. Descargar imagen de S3
aws s3 cp s3://$BUCKET_NAME/$OBJECT_KEY /home/ubuntu/input/

# 3. Ejecutar MONAI MAP
docker run --rm --gpus all \
  -v /home/ubuntu/input:/input \
  -v /home/ubuntu/output:/output \
  $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$DOCKER_IMAGE_TAG

# 4. Subir resultados y avisar a HealthImaging
aws s3 cp /home/ubuntu/output s3://$BUCKET_NAME/results/ --recursive
# Aquí iría el comando 'start-dicom-import-job' para HealthImaging