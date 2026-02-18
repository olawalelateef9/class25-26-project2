# 1. VPC Configuration
resource "aws_vpc" "project_network" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "Techbleat-VPC"
  }
}

# 2. Internet Gateway (For Public Subnet Access)
resource "aws_internet_gateway" "project_igw" {
  vpc_id = aws_vpc.project_network.id

  tags = {
    Name = "project_igw"
  }
}

# 3. Public Subnet (For Bastion Host and Load Balancer)
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.project_network.id
  cidr_block              = var.public_subnet_1_cidr
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true

  tags = {
    Name = "Techbleat-Public-Subnet"
  }
}

# 4. Private Subnet 1 (For Backend App - AZ 'a')
resource "aws_subnet" "private_subnet_1" {
  vpc_id            = aws_vpc.project_network.id
  cidr_block        = var.private_subnet_1_cidr
  availability_zone = "${var.aws_region}a"

  tags = {
    Name = "Techbleat-Private-App"
  }
}

# 5. Private Subnet 2 (Required for RDS DB Subnet Group - AZ 'b')
# Note: You will need a variable for this CIDR, e.g., 10.0.3.0/24
resource "aws_subnet" "private_subnet_2" {
  vpc_id            = aws_vpc.project_network.id
  cidr_block        = "10.0.3.0/24" # Or use a variable: var.private_subnet_2_cidr
  availability_zone = "${var.aws_region}b"

  tags = {
    Name = "Techbleat-Private-DB-Backup-AZ"
  }
}

# 6. Public Route Table (Internet Access)
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

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# 7. Private Route Table (Isolated)
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.project_network.id

  tags = {
    Name = "private_rt"
  }
}

# Associate both private subnets with the private route table
resource "aws_route_table_association" "private_assoc_1" {
  subnet_id      = aws_subnet.private_subnet_1.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private_assoc_2" {
  subnet_id      = aws_subnet.private_subnet_2.id
  route_table_id = aws_route_table.private_rt.id
}

# 8. S3 Gateway Endpoint (Updates for Private Instances)
resource "aws_vpc_endpoint" "s3_gateway" {
  vpc_id            = aws_vpc.project_network.id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = [
    aws_route_table.public_rt.id,
    aws_route_table.private_rt.id
  ]

  tags = {
    Name = "s3-endpoint-for-updates"
  }
}