variable "aws_region" {}
variable "instance_name" {}
variable "key_name" {}
variable "ssh_key_path" {}

provider "aws" {
  region = var.aws_region
}

resource "aws_key_pair" "deployer" {
  key_name   = var.key_name
  public_key = file(var.ssh_key_path)
}

resource "aws_instance" "monai_instance" {
  ami           = "ami-0e2c8ccd4e122313a" # Ubuntu 22.04 en us-east-1
  instance_type = "g4dn.xlarge"
  key_name      = aws_key_pair.deployer.key_name

  tags = { Name = var.instance_name }

  root_block_device {
    volume_size = 40
  }
}

output "instance_id" { value = aws_instance.monai_instance.id }
output "instance_public_ip" { value = aws_instance.monai_instance.public_ip }