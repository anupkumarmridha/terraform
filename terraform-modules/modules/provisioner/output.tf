output "deployment_status" {
  description = "Status of MySQL connection deployment"
  value = var.enable_provisioner ? "Remote provisioner executed" : (
    var.enable_local_provisioner ? "Local provisioner executed" : "No provisioner enabled"
  )
}

output "mysql_connection_url" {
  description = "URL to test MySQL connection"
  value = "http://<alb-dns-name>/mysql-connection.php"
}

output "deployment_method" {
  description = "Deployment method used"
  value = var.enable_provisioner ? "remote" : (var.enable_local_provisioner ? "local" : "none")
}