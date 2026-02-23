variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-2"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

# Matches vpc.tf naming
variable "public_subnet_1_cidr" {
  description = "CIDR block for public subnet 1"
  type        = string
  default     = "10.0.1.0/24"
}

# Matches vpc.tf naming
variable "private_subnet_1_cidr" {
  description = "CIDR block for private subnet 1"
  type        = string
  default     = "10.0.2.0/24"
}

# NEW: Required for RDS Subnet Group (AZ 'b')
variable "private_subnet_2_cidr" {
  description = "CIDR block for private subnet 2"
  type        = string
  default     = "10.0.3.0/24"
}

variable "web_ami" {
  description = "AMI for web instances"
  type        = string
  default     = "ami-0c613eb0498cd4917"
}

variable "backend_ami" {
  description = "AMI for backend instances"
  type        = string
  default     = "ami-0d1bf736a548b7e67"
}

variable "instance_type" {
  description = "Instance type for EC2 instances"
  type        = string
  default     = "t2.small"
}

variable "key_name" {
  description = "EC2 Key Pair name for instances"
  type        = string
  default     = "jenkinskp"
}

variable "db_password" {
  description = "The password for the RDS database"
  type        = string
  sensitive   = true
}

variable "db_user" {
  description = "The username for the RDS database"
  type        = string
  default     = "postgres"
}

variable "db_name" {
  description = "The name of the database to create"
  type        = string
  default     = "mydb"
}