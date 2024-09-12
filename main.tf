provider "aws" {
  region = "us-east-1"
}

# Define the DB subnet group with the public subnet
resource "aws_db_subnet_group" "aurora_subnet_group" {
  name        = "aurora-subnet-group"
  subnet_ids   = [
    "subnet-080e0b47975c79ef1",  # us-east-1a
    "subnet-0078f4bc5eacaa4fb"   # us-east-1b
  ]
  tags = {
    Name = "aurora-subnet-group"
  }
}

# Define the RDS cluster
resource "aws_rds_cluster" "aurora_postgres" {
  engine             = "aurora-postgresql"
  engine_version     = "14.6"
  cluster_identifier = "galega-db-aurora"
  master_username    = var.db_master_username
  master_password    = var.db_master_password
  skip_final_snapshot = true
  db_subnet_group_name = aws_db_subnet_group.aurora_subnet_group.name  # Link the subnet group

  # Optional tags for resource identification
  tags = {
    Name = "galega-db-aurora"
  }
}

# Define the RDS cluster instance
resource "aws_rds_cluster_instance" "aurora_postgres_instance" {
  identifier           = "aurora-db-instance-1"
  cluster_identifier   = aws_rds_cluster.aurora_postgres.id
  instance_class       = "db.t4g.medium"
  engine               = aws_rds_cluster.aurora_postgres.engine
}

# Output the endpoint of the RDS cluster
output "endpoint" {
  value = aws_rds_cluster.aurora_postgres.endpoint
}
