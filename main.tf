provider "aws" {
  region = "us-east-1"
}

# Reference to an existing VPC
data "aws_vpc" "existing_vpc" {
  id = "vpc-01fc04d120eab4343"
}

# Reference to the existing public subnet
data "aws_subnet" "public_subnet" {
  id = "subnet-0dd8d163c6bb3ad67"
}

# Create a new private subnet in the existing VPC
resource "aws_subnet" "private_subnet_aurora_a" {
  vpc_id            = data.aws_vpc.existing_vpc.id
  cidr_block        = "10.1.11.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "private_subnet_aurora_a"
  }
}

resource "aws_subnet" "private_subnet_aurora_b" {
  vpc_id            = data.aws_vpc.existing_vpc.id
  cidr_block        = "10.1.12.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "private_subnet_aurora_b"
  }
}

# Create a new security group in the existing VPC
resource "aws_security_group" "sg_for_aurora" {
  vpc_id = data.aws_vpc.existing_vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "aurora-security-group"
  }
}

# Define the DB subnet group with the existing and new private subnets
resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "aurora-subnet-group-unique"  # Updated unique name
  subnet_ids = [
    aws_subnet.private_subnet_aurora_a.id,
    aws_subnet.private_subnet_aurora_b.id
  ]

  tags = {
    Name = "aurora-subnet-group-unique"  # Updated unique name
  }
}

# Define the Aurora Serverless v1 RDS cluster
resource "aws_rds_cluster" "serverless_aurora_pg" {
  engine             = "aurora-postgresql"
  engine_version     = "13.12"
  cluster_identifier = "serverless-aurora-pg-cluster"  # Unique identifier
  master_username    = var.db_master_username
  master_password    = var.db_master_password
  skip_final_snapshot = true
  db_subnet_group_name = aws_db_subnet_group.db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.sg_for_aurora.id]
  database_name      = "galega"
  engine_mode        = "serverless"  # Mode for Serverless v1

  scaling_configuration {
    min_capacity = 2  # Minimum Aurora Capacity Units (ACUs)
    max_capacity = 6  # Maximum Aurora Capacity Units (ACUs)
  }

  tags = {
    Name = "serverless_aurora_pg"
  }
}

# Output the endpoint of the RDS cluster
output "endpoint" {
  value = aws_rds_cluster.serverless_aurora_pg.endpoint
}
