provider "aws" {
  region = "us-east-1"
}

resource "aws_rds_cluster" "aurora_postgres" {
  engine             = "aurora-postgresql"
  engine_version     = "14.6"
  cluster_identifier = "my-aurora-cluster"
  master_username    = "postgres"
  master_password    = "postgres"
  skip_final_snapshot = true
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