provider "aws" {
  region = "us-east-1"
}

resource "aws_rds_cluster" "aurora_postgres" {
  engine             = "aurora-postgresql"
  engine_version     = "14.6"
  cluster_identifier = "galega-aurora"
  master_username    = var.db_master_username
  master_password    = var.db_master_password
  skip_final_snapshot = true
  tags = {
    Name = "galega-aurora"
  }
}

resource "aws_rds_cluster_instance" "aurora_postgres_instance" {
  identifier        = "aurora-instance-1"
  cluster_identifier = aws_rds_cluster.aurora_postgres.id
  instance_class    = "db.t4g.medium"
  engine            = aws_rds_cluster.aurora_postgres.engine
}

output "endpoint" {
  value = aws_rds_cluster.aurora_postgres.endpoint
}
