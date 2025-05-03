# Provider Configuration
provider "aws" {
  region = "us-west-2"  # Update with your desired AWS region
}

# Variables
variable "ami_id" {
  description = "AMI ID for the EC2 instances"
  default     = "ami-075686beab831bb7f"  # Update with your desired AMI ID
}

variable "instance_type" {
  description = "EC2 instance type"
  default     = "t2.medium"  # Update with your desired instance type
}

# VPC Creation
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

# Subnet Creation
resource "aws_subnet" "main" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-west-2a"  # Update with the availability zone
}

# Security Group for Kubernetes Nodes
resource "aws_security_group" "k8s_sg" {
  name   = "k8s-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 6443
    to_port     = 6553
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 10250
    to_port     = 10252
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EC2 Instance for Kubernetes Master
resource "aws_instance" "k8s_master" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.main.id
  key_name                    = "suresh-key"  # Updated to match the key you uploaded
  vpc_security_group_ids      = [aws_security_group.k8s_sg.id]
  associate_public_ip_address = true

  tags = {
    Name = "k8s-master"
  }
}

# EC2 Instances for Kubernetes Workers (using count)
resource "aws_instance" "k8s_worker" {
  count                       = 2
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.main.id
  key_name                    = "suresh-key"  # Updated to match the key you uploaded
  vpc_security_group_ids      = [aws_security_group.k8s_sg.id]
  associate_public_ip_address = true

  user_data = file("scripts/worker.sh")

  tags = {
    Name = "k8s-worker-${count.index + 1}"
  }
}


# Outputs
output "master_public_ip" {
  value = aws_instance.k8s_master.public_ip
}

output "worker_public_ips" {
  value = [for i in aws_instance.k8s_worker : i.public_ip]
}
