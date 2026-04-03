import boto3

# Variables que el YAML rellenará con 'sed'
region = ""
static_instance_id = ""

ec2 = boto3.client('ec2', region_name=region)
ssm = boto3.client('ssm', region_name=region)

def lambda_handler(event, context):
    bucket_name = event['Records'][0]['s3']['bucket']['name']
    object_key = event['Records'][0]['s3']['object']['key']
    
    # Encender la instancia si está apagada
    ec2.start_instances(InstanceIds=[static_instance_id])
    waiter = ec2.get_waiter('instance_running')
    waiter.wait(InstanceIds=[static_instance_id])
    
    # Enviar comando de ejecución vía SSM
    ssm.send_command(
        InstanceIds=[static_instance_id],
        DocumentName="AWS-RunShellScript",
        Parameters={
            'commands': [f'sudo su ubuntu -c "/home/ubuntu/ec2.sh {bucket_name} {object_key}"']
        }
    )
    return {"status": "Command sent"}