provider "aws" {
  region = "us-east-1"
}

resource "aws_rds_cluster" "aurora_cluster" {
  cluster_identifier      = "aurora-cluster"
  engine                  = "aurora-mysql"
  engine_version          = "5.7.mysql_aurora.2.03.4"
  master_username         = var.db_username
  master_password         = var.db_password
  database_name           = var.db_name
  backup_retention_period = 5
  preferred_backup_window = "07:00-09:00"
  skip_final_snapshot     = true

  vpc_security_group_ids  = var.vpc_security_group_ids
  db_subnet_group_name    = aws_db_subnet_group.main.name
}

resource "aws_db_subnet_group" "main" {
  name       = "aurora-subnet-group"
  subnet_ids = var.db_subnet_ids
}

resource "aws_rds_cluster_instance" "aurora_instance" {
  count              = 2
  identifier         = "aurora-instance-${count.index + 1}"
  cluster_identifier = aws_rds_cluster.aurora_cluster.id
  instance_class     = var.db_instance_class
}
