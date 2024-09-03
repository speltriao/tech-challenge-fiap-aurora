variable "db_master_username" {
  description = "The master username for the RDS cluster"
  type        = string
}

variable "db_master_password" {
  description = "The master password for the RDS cluster"
  type        = string
  sensitive   = true
}