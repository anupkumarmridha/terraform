# Data source to get RDS credentials from Secrets Manager
data "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = var.db_credentials_secret_arn
}

# Create a null resource to handle the provisioning
resource "null_resource" "mysql_connection_provisioner" {
  count = var.enable_provisioner ? 1 : 0

  # Triggers to re-run provisioner when these values change
  triggers = {
    rds_endpoint = var.rds_endpoint
    launch_template_version = var.launch_template_latest_version
    mysql_connection_file = filemd5("${path.module}/../../scripts/mysql-connection.php")
  }

  # Connection to bastion host for remote provisioning
  connection {
    type        = "ssh"
    host        = var.bastion_public_ip
    user        = "ec2-user"
    private_key = file(var.bastion_private_key_path)
    timeout     = "5m"
  }

  # Upload the mysql-connection.php file to bastion
  provisioner "file" {
    source      = "${path.module}/../../scripts/mysql-connection.php"
    destination = "/tmp/mysql-connection.php"
  }

  # Upload the database configuration script
  provisioner "file" {
    content = templatefile("${path.module}/scripts/setup-mysql-connection.sh", {
      db_host = var.rds_endpoint
      db_user = local.db_credentials.username
      db_pass = local.db_credentials.password  
      db_name = var.db_name
      db_port = var.rds_port
      asg_name = var.asg_name
    })
    destination = "/tmp/setup-mysql-connection.sh"
  }

  # Execute deployment script
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/setup-mysql-connection.sh",
      "/tmp/setup-mysql-connection.sh"
    ]
  }

  depends_on = [var.asg_dependency]
}

# Create a local provisioner alternative for testing
resource "null_resource" "local_mysql_connection_provisioner" {
  count = var.enable_local_provisioner ? 1 : 0

  triggers = {
    rds_endpoint = var.rds_endpoint
    mysql_connection_file = filemd5("${path.module}/../../scripts/mysql-connection.php")
  }

  provisioner "local-exec" {
    command = templatefile("${path.module}/scripts/local-deploy.sh", {
      db_host = var.rds_endpoint
      db_user = local.db_credentials.username
      db_pass = local.db_credentials.password
      db_name = var.db_name
      db_port = var.rds_port
      asg_name = var.asg_name
      bastion_ip = var.bastion_public_ip
      bastion_key = var.bastion_private_key_path
    })
  }

  depends_on = [var.asg_dependency]
}