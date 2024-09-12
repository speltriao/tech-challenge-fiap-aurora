provider "aws" {
  region = "us-east-1"
}

# Reference to an existing VPC
data "aws_vpc" "existing_vpc" {
  id = "vpc-00a9a81b9e176bda7"
}

# Create new private subnets in the existing VPC
resource "aws_subnet" "private_subnet_aurora_a" {
  vpc_id            = data.aws_vpc.existing_vpc.id
  cidr_block        = "10.1.7.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "private_subnet_aurora_a"
  }
}

resource "aws_subnet" "private_subnet_aurora_b" {
  vpc_id            = data.aws_vpc.existing_vpc.id
  cidr_block        = "10.1.6.0/24"
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

# Define the DB subnet group with the updated private subnets
resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "aurora-subnet-group"
  subnet_ids = [
    aws_subnet.private_subnet_aurora_a.id,
    aws_subnet.private_subnet_aurora_b.id
  ]

  tags = {
    Name = "aurora-subnet-group"
  }
}

# Define the Aurora Serverless RDS cluster
resource "aws_rds_cluster" "serverless_aurora_pg" {
  engine             = "aurora-postgresql"
  engine_mode        = "serverless"
  engine_version     = "14.6"
  cluster_identifier = "serverless_aurora_pg_cluster"
  master_username    = var.db_master_username
  master_password    = var.db_master_password
  skip_final_snapshot = true
  db_subnet_group_name = aws_db_subnet_group.db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.sg_for_aurora.id]
  database_name      = "my_database"

  tags = {
    Name = "serverless_aurora_pg"
  }

  scaling_configuration {
    auto_pause               = true
    min_capacity             = 1
    max_capacity             = 2
    seconds_until_auto_pause = 600
  }
}

# Output the endpoint of the RDS cluster
output "endpoint" {
  value = aws_rds_cluster.serverless_aurora_pg.endpoint
}
