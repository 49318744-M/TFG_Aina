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
  ami           = "ami-08aa4c8884cdec81f" # Ubuntu 22.04 en us-east-1
  instance_type = "g4dn.xlarge"
  key_name      = aws_key_pair.deployer.key_name
  vpc_security_group_ids = [aws_security_group.monai_sg.id]

  tags = { Name = var.instance_name }

  root_block_device {
    volume_size = 40
  }
}
resource "aws_security_group" "monai_sg" {
  name_prefix       = "monai-build-sg"
  description = "Permetre SSH per al build de MONAI"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Permet l'accés des de GitHub Actions
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

output "instance_id" { value = aws_instance.monai_instance.id }
output "instance_public_ip" { value = aws_instance.monai_instance.public_ip }