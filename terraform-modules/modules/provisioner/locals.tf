
locals {
  db_credentials = jsondecode(data.aws_secretsmanager_secret_version.db_credentials.secret_string)
  
  # Create environment variables for database connection
  db_env_vars = {
    DB_HOST = var.rds_endpoint
    DB_USER = local.db_credentials.username
    DB_PASS = local.db_credentials.password
    DB_NAME = var.db_name
    DB_PORT = var.rds_port
  }
}