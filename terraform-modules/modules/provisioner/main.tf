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
  
  # Upload the setup_instance.sh script to bastion
  provisioner "file" {
    source      = "${path.module}/scripts/setup_instance.sh"
    destination = "/tmp/setup_instance.sh"
  }
  
  # Upload the dashboard.html file to bastion
  provisioner "file" {
    source      = "${path.module}/scripts/dashboard.html"
    destination = "/tmp/dashboard.html"
  }

  # Create a file with app key path information
  provisioner "remote-exec" {
    inline = [
      "echo '${var.app_private_key_path != "" ? "APP_KEY_PROVIDED=true" : "APP_KEY_PROVIDED=false"}' > /tmp/app_key_info.env"
    ]
  }

  # Upload the app private key to bastion if provided
  provisioner "file" {
    source      = var.app_private_key_path
    destination = "/tmp/${basename(var.app_private_key_path)}"
    when        = create
    on_failure  = continue
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
      app_key_path = var.app_private_key_path != "" ? "/tmp/${basename(var.app_private_key_path)}" : ""
      alb_dns_name = var.alb_dns_name
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
