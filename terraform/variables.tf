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

variable "public_subnet_cidr" {
  description = "CIDR block for public subnet 1"
  type        = string
  default     = "10.0.1.0/24"
}


variable "private_subnet_cidr" {
  description = "CIDR block for private subnet 1"
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

variable "vpc_id" {
  description = "VPC ID for instances"
  type        = string
  default     = "vpc-0554333af64d61d92"
}

variable "key_name" {
  description = "EC2 Key Pair name for instances"
  type        = string
  default     = "jenkinskp"
}