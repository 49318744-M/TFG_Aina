#!/bin/bash
# Variables que el YAML rellenará con 'sed'
ROLE_ARN=""
REGION=""
BUCKET_NAME=""
ACCOUNT_ID=""
FUNCTION_NAME=""

# 1. Comprimir la función Lambda
zip -r function.zip lambda_function.py

# 2. Crear o actualizar la Lambda
aws lambda create-function --function-name $FUNCTION_NAME \
  --zip-file fileb://function.zip --handler lambda_function.lambda_handler \
  --runtime python3.8 --role $ROLE_ARN --region $REGION \
  || \
aws lambda update-function-code --function-name $FUNCTION_NAME \
  --zip-file fileb://function.zip --region $REGION

# 3. Dar permisos a S3 para invocar la Lambda
aws lambda add-permission --function-name $FUNCTION_NAME \
  --statement-id S3Invoke --action lambda:InvokeFunction \
  --principal s3.amazonaws.com --source-arn arn:aws:s3:::$BUCKET_NAME

# 4. Configurar la notificación del Bucket S3
cat <<EOT > s3_event_configuration.json
{
  "LambdaFunctionConfigurations": [
    {
      "LambdaFunctionArn": "arn:aws:lambda:$REGION:$ACCOUNT_ID:function:$FUNCTION_NAME",
      "Events": ["s3:ObjectCreated:*"],
      "Filter": { "Key": { "FilterRules": [{ "Name": "prefix", "Value": "input/" }] } }
    }
  ]
}
EOT

aws s3api put-bucket-notification-configuration --bucket $BUCKET_NAME \
  --notification-configuration file://s3_event_configuration.json