import boto3
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Estas variables las configurará el workflow de GitHub
region = ""
static_instance_id = ""

ec2 = boto3.client('ec2', region_name=region)
ssm = boto3.client('ssm', region_name=region)

def lambda_handler(event, context):
    # Extraer datos del archivo subido a S3
    bucket_name = event['Records'][0]['s3']['bucket']['name']
    object_key = event['Records'][0]['s3']['object']['key']
    
    # 1. Asegurarse de que la instancia EC2 esté encendida
    response = ec2.describe_instances(InstanceIds=[static_instance_id])
    state = response['Reservations'][0]['Instances'][0]['State']['Name']
    
    if state != 'running':
        logger.info(f"Iniciando instancia {static_instance_id}...")
        ec2.start_instances(InstanceIds=[static_instance_id])
        waiter = ec2.get_waiter('instance_running')
        waiter.wait(InstanceIds=[static_instance_id])
    
    # 2. Enviar el comando para ejecutar ec2.sh mediante SSM
    ssm.send_command(
        InstanceIds=[static_instance_id],
        DocumentName="AWS-RunShellScript",
        Parameters={
            'commands': [
                f'sudo su ubuntu -c "/home/ubuntu/ec2.sh {bucket_name} {object_key}"'
            ]
        }
    )
    return {'statusCode': 200, 'body': 'Comando de inferencia enviado a EC2'}