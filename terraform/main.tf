

# --- 1. TERRAFORM CONFIGURATION ---
terraform {
  backend "s3" {
    bucket  = "olawale-s3-devops-bucket"
    key     = "envs/dev/terraform.tfstate"
    region  = "us-east-2"
    encrypt = true
  }
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# --- 2. COMPUTE RESOURCES ---

# BASTION HOST (Public Subnet)
# Provides secure administrative access (SSH) to private instances [cite: 26, 43]
resource "aws_instance" "bastion" {
  ami                         = var.web_ami
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.public_subnet.id
  vpc_security_group_ids      = [aws_security_group.bastion_sg.id]
  key_name                    = var.key_name
  associate_public_ip_address = true

  tags = { Name = "Techbleat-Bastion" }
}

# BACKEND INSTANCE (Private Subnet)
# Runs the FastAPI application portal [cite: 25, 28]
resource "aws_instance" "backend" {
  count                  = 1
  ami                    = var.backend_ami
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.private_subnet_1.id 
  vpc_security_group_ids = [aws_security_group.backend_sg.id]
  key_name               = var.key_name
  associate_public_ip_address = false

  tags = { Name = "backend-instance-${count.index + 1}" }

  # Automated Database Connection String 
  user_data = <<-EOF
  #!/bin/bash
  echo "DATABASE_URL=postgresql://postgres:Youngman9!@${aws_db_instance.project_db.endpoint}:5432/postgres" > /home/ubuntu/.env
  sudo systemctl restart app
  EOF
}

# --- 3. DATABASE RESOURCES (Private Tier) ---

resource "aws_db_subnet_group" "project_db_subnet_group" {
  name       = "project-db-subnet-group"
  subnet_ids = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]
  tags = { Name = "Project DB Subnet Group" }
}

resource "aws_db_instance" "project_db" {
  identifier           = "project-database"
  engine               = "postgres"
  instance_class       = "db.t4g.micro"
  allocated_storage    = 20
  username             = "postgres"
  password             = "var.db_password" 
  db_subnet_group_name = aws_db_subnet_group.project_db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  skip_final_snapshot  = true
  publicly_accessible  = false
}

# --- 4. SECURITY GROUPS (Firewalls) ---

# Bastion SG: Entrance for Admin/Ops [cite: 21, 22]
resource "aws_security_group" "bastion_sg" {
  name   = "bastion-sg"
  vpc_id = aws_vpc.project_network.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Suggestion: Change to your specific IP for better security
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Backend SG: Allows traffic from Load Balancer and Bastion only [cite: 41, 43]
resource "aws_security_group" "backend_sg" {
  name   = "backend-sg"
  vpc_id = aws_vpc.project_network.id

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id] 
  }

  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["10.0.1.0/24"] # Traffic from public subnet (ALB tier)
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# DB SG: Allows SQL queries only from the backend app [cite: 13, 19]
resource "aws_security_group" "db_sg" {
  name        = "db-sg"
  description = "Allow inbound traffic from backend only"
  vpc_id      = aws_vpc.project_network.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.backend_sg.id] 
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# --- 5. OUTPUTS ---
output "rds_endpoint" {
  value = aws_db_instance.project_db.endpoint
}

output "db_name" {
  value = aws_db_instance.project_db.db_name
}

output "bastion_public_ip" {
  value = aws_instance.bastion.public_ip
}

output "backend_private_ip" {
  value = aws_instance.backend[0].private_ip
}