# 1. VPC Configuration
resource "aws_vpc" "project_network" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "Project_network"
  }
}

# 2. Internet Gateway (For Public Subnet)
resource "aws_internet_gateway" "project_igw" {
  vpc_id = aws_vpc.project_network.id

  tags = {
    Name = "project_igw"
  }
}

# 3. Public Subnet (For Web)
resource "aws_subnet" "public_subnet_1" {
  vpc_id            = aws_vpc.project_network.id
  cidr_block        = var.public_subnet_1_cidr
  availability_zone = "${var.aws_region}a"

  tags = {
    Name = "public_project_subnet_1"
    Tier = "Web App Tier"
  }
}


# 4. Private Subnet (For Backend/Database)
resource "aws_subnet" "private_subnet_1" {
  vpc_id            = aws_vpc.project_network.id
  cidr_block        = var.private_subnet_1_cidr
  availability_zone = "${var.aws_region}a"

  tags = {
    Name = "private_project_subnet_1"
    Tier = "Application Tier"
  }
}


# 5. Public Route Table (Connected to Internet)
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.project_network.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.project_igw.id
  }

  tags = {
    Name = "public_rt"
  }
}

resource "aws_route_table_association" "public_subnet_1_assoc" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_rt.id
}


# 6. Private Route Table
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.project_network.id

  tags = {
    Name = "private_rt"
  }
}

resource "aws_route_table_association" "private_subnet_1_assoc" {
  subnet_id      = aws_subnet.private_subnet_1.id
  route_table_id = aws_route_table.private_rt.id
}


# 7. S3 GATEWAY ENDPOINT 
# This allows private instances to download Linux updates directly from AWS internal network
resource "aws_vpc_endpoint" "s3_gateway" {
  vpc_id            = aws_vpc.project_network.id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"

  # Links the endpoint to your route tables so instances know how to use it
  route_table_ids = [
    aws_route_table.public_rt.id,
    aws_route_table.private_rt.id
  ]

  tags = {
    Name = "s3-endpoint-for-updates"
  }
}