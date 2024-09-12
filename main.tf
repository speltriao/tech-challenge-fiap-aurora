provider "aws" {
  region = "us-east-1"
}

# Define the RDS cluster
resource "aws_rds_cluster" "aurora_postgres" {
  engine             = "aurora-postgresql"
  engine_version     = "14.6"
  cluster_identifier = "galega-aurora"
  master_username    = var.db_master_username
  master_password    = var.db_master_password
  skip_final_snapshot = true

  # Optional tags for resource identification
  tags = {
    Name = "galega-aurora"
  }
}

# Define the RDS cluster instance
resource "aws_rds_cluster_instance" "aurora_postgres_instance" {
  identifier           = "aurora-instance-1"
  cluster_identifier   = aws_rds_cluster.aurora_postgres.id
  instance_class       = "db.t4g.medium"
  engine               = aws_rds_cluster.aurora_postgres.engine
}

# Output the endpoint of the RDS cluster
output "endpoint" {
  value = aws_rds_cluster.aurora_postgres.endpoint
}

# Optional output to debug and confirm other important details
output "cluster_id" {
  value = aws_rds_cluster.aurora_postgres.id
}

output "cluster_status" {
  value = aws_rds_cluster.aurora_postgres.status
}

output "instance_id" {
  value = aws_rds_cluster_instance.aurora_postgres_instance.id
}

output "instance_status" {
  value = aws_rds_cluster_instance.aurora_postgres_instance.status
}
