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

# --- 1. WEB INSTANCES (Public) ---
resource "aws_instance" "web" {
  count                       = 1
  ami                         = var.web_ami
  instance_type               = var.instance_type
  subnet_id                   = count.index == 0 ? aws_subnet.public_subnet.id 
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  key_name                    = var.key_name
  associate_public_ip_address = true

  tags = { Name = "web-instance-${count.index + 1}" }
}

# --- 2. BACKEND INSTANCES (Private) ---
resource "aws_instance" "backend" {
  count                  = 1
  ami                    = var.backend_ami
  instance_type          = var.instance_type
  subnet_id              = count.index == 0 ? aws_subnet.private_subnet.id 
  vpc_security_group_ids = [aws_security_group.backend_sg.id]
  key_name               = var.key_name
  associate_public_ip_address = false

  tags = { Name = "backend-instance-${count.index + 1}" }

  # --- Automated Database Connection ---
  user_data = <<-EOF
  #!/bin/bash
  echo "DATABASE_URL=postgresql://postgres:Youngman9!@${aws_db_instance.project_db.endpoint}:5432/postgres" > /home/ec2-user/.env
  # IMPORTANT: Update the line below to match your service name!
  sudo systemctl restart app
  EOF
}

# --- 3. DATABASE RESOURCES ---

# NEW: DB Subnet Group (Fixes the "2 AZ requirement" error)
resource "aws_db_subnet_group" "project_db_subnet_group" {
  name       = "project-db-subnet-group"
  subnet_ids = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]

  tags = { Name = "Project DB Subnet Group" }
}

# The Database Instance
resource "aws_db_instance" "project_db" {
  identifier           = "project-database"
  engine               = "postgres"
  instance_class       = "db.t4g.micro"
  allocated_storage    = 20
  username             = "postgres"
  password             = "Youngman9!" 
  
  db_subnet_group_name = aws_db_subnet_group.project_db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  
  skip_final_snapshot  = true
  publicly_accessible  = false
}

# --- 4. SECURITY GROUPS ---

resource "aws_security_group" "web_sg" {
  name   = "web-sg"
  vpc_id = aws_vpc.project_network.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
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

resource "aws_security_group" "jenkins_sg" {
  name   = "jenkins-sg"
  vpc_id = aws_vpc.project_network.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
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

resource "aws_security_group" "backend_sg" {
  name   = "backend-sg"
  vpc_id = aws_vpc.project_network.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  ingress {
    from_port       = 8000
    to_port         = 8000
    protocol        = "tcp"
    security_groups = [aws_security_group.web_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "db_sg" {
  name        = "db-sg"
  description = "Allow inbound traffic from backend only"
  vpc_id      = aws_vpc.project_network.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.backend_sg.id] # Handshake
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