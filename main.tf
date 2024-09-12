provider "aws" {
  region = "us-east-1"
}

# Reference to an existing VPC
data "aws_vpc" "existing_vpc" {
  id = "vpc-00a9a81b9e176bda7"
}

# Create new public subnets in the existing VPC
resource "aws_subnet" "public_subnet_1a" {
  vpc_id                  = data.aws_vpc.existing_vpc.id
  cidr_block              = "10.0.224.0/19"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "public_subnet_1a"
  }
}

resource "aws_subnet" "public_subnet_1b" {
  vpc_id                  = data.aws_vpc.existing_vpc.id
  cidr_block              = "10.0.192.0/19"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "public_subnet_1b"
  }
}

# Create a new security group in the existing VPC
resource "aws_security_group" "new_sg" {
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

# Define the DB subnet group with the newly created subnets
resource "aws_db_subnet_group" "aurora_subnet_group" {
  name        = "aurora-subnet-group"
  subnet_ids  = [
    aws_subnet.public_subnet_1a.id,
    aws_subnet.public_subnet_1b.id
  ]
  tags = {
    Name = "aurora-subnet-group"
  }
}

# Define the RDS cluster
resource "aws_rds_cluster" "aurora_postgres" {
  engine             = "aurora-postgresql"
  engine_version     = "14.6"
  cluster_identifier = "galega-db-aurora1"
  master_username    = var.db_master_username
  master_password    = var.db_master_password
  skip_final_snapshot = true
  db_subnet_group_name = aws_db_subnet_group.aurora_subnet_group.name
  vpc_security_group_ids = [aws_security_group.new_sg.id]

  tags = {
    Name = "galega-db-aurora2"
  }
}

# Define the RDS cluster instance
resource "aws_rds_cluster_instance" "aurora_postgres_instance" {
  identifier           = "aurora-db-instance-3"
  cluster_identifier   = aws_rds_cluster.aurora_postgres.id
  instance_class       = "db.t4g.medium"
  engine               = aws_rds_cluster.aurora_postgres.engine
}

# Output the endpoint of the RDS cluster
output "endpoint" {
  value = aws_rds_cluster.aurora_postgres.endpoint
}
