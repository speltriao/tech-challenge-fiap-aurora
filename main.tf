provider "aws" {
  region = "us-east-1"
}

# Reference to an existing VPC
data "aws_vpc" "vpc_reference" {
  id = "vpc-00a9a81b9e176bda7"
}

# Create new private subnets in the existing VPC
resource "aws_subnet" "private_subnet_1" {
  vpc_id            = data.aws_vpc.vpc_reference.id
  cidr_block        = "10.1.8.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "private_subnet_1"
  }
}

resource "aws_subnet" "private_subnet_2" {
  vpc_id            = data.aws_vpc.vpc_reference.id
  cidr_block        = "10.1.9.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "private_subnet_2"
  }
}

# Create a new security group in the existing VPC
resource "aws_security_group" "sg_for_aurora" {
  vpc_id = data.aws_vpc.vpc_reference.id

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
    Name = "sg_for_aurora"
  }
}

# Define the DB subnet group with the updated private subnets
resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "db_subnet_group_name"
  subnet_ids = [
    aws_subnet.private_subnet_1.id,
    aws_subnet.private_subnet_2.id
  ]

  tags = {
    Name = "db_subnet_group_name"
  }
}

# Define the RDS cluster with Serverless mode and set the database name
resource "aws_rds_cluster" "serverless_aurora_pg" {
  engine             = "aurora-postgresql"
  engine_mode        = "serverless" # Use serverless mode
  engine_version     = "14.6"
  cluster_identifier = "serverless_aurora_pg_cluster"
  master_username    = var.db_admin_username
  master_password    = var.db_admin_password
  skip_final_snapshot = true
  db_subnet_group_name = aws_db_subnet_group.db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.sg_for_aurora.id]
  database_name      = "galega"

  tags = {
    Name = "serverless_aurora_pg"
  }

  scaling_configuration {
    auto_pause               = true
    min_capacity             = 1   # Set the minimum capacity to 1 ACU
    max_capacity             = 2   # Set the maximum capacity to 2 ACUs
    seconds_until_auto_pause = 600 # Auto-pause delay set to 10 minutes
  }
}

# Output the endpoint of the RDS cluster
output "aurora_cluster_endpoint" {
  value = aws_rds_cluster.serverless_aurora_pg.endpoint
}
