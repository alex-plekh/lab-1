terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region                  = "us-east-1"
}

# Get the latest Amazon Linux AMI ID
data "aws_ami" "amazon_linux" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-kernel-5.10-hvm-*-x86_64-gp2"]
  }

  owners = ["amazon"]
}

# Create EC2 instance
resource "aws_instance" "web" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t2.micro"
  key_name               = "lab1-jenkins"
  vpc_security_group_ids = [aws_security_group.web_sg_jenkins_terraform.id]

  tags = {
    "Name" = "New webserver jenkins"
  }

  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum install httpd -y
              sudo systemctl start httpd
              sudo systemctl enable httpd
              echo "<html><h1>Your web server works!</h1></html>" > /var/www/html/index.html
              EOF
}

# Security group
resource "aws_security_group" "web_sg_jenkins_terraform" {
  name = "Ec2 instance sg jenkins"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["188.239.99.95/32"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["188.239.99.95/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

output "website_endpoint" {
  value = aws_instance.web.public_ip
}
