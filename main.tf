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
    Name = "aurora-security-group-new-private"
  }
}

# Define the DB subnet group with the updated private subnets
resource "aws_db_subnet_group" "aurora_subnet_group_new" {
  name       = "aurora-subnet-group-new"
  subnet_ids = [
    aws_subnet.private_subnet_aurora_a.id,
    aws_subnet.private_subnet_aurora_b.id
  ]

  tags = {
    Name = "aurora-subnet-group-new-private"
  }
}

# Define the RDS cluster with a new name to avoid conflict
resource "aws_rds_cluster" "aurora_postgres_new" {
  engine             = "aurora-postgresql"
  engine_version     = "14.6"
  cluster_identifier = "tech-galega-db-aurora-new"
  master_username    = var.db_master_username
  master_password    = var.db_master_password
  skip_final_snapshot = true
  db_subnet_group_name = aws_db_subnet_group.aurora_subnet_group_new.name
  vpc_security_group_ids = [aws_security_group.new_sg.id]

  tags = {
    Name = "tech-galega-db-aurora-new"
  }
}

# Define the RDS cluster instance
resource "aws_rds_cluster_instance" "aurora_postgres_instance" {
  identifier           = "aurora-db-instance-new"
  cluster_identifier   = aws_rds_cluster.aurora_postgres_new.id
  instance_class       = "db.t4g.medium"
  engine               = aws_rds_cluster.aurora_postgres_new.engine
}

# Output the endpoint of the RDS cluster
output "endpoint" {
  value = aws_rds_cluster.aurora_postgres_new.endpoint
}
