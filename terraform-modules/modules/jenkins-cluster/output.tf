# Jenkins Master Outputs
output "jenkins_master_instance_id" {
  description = "ID of the Jenkins master EC2 instance"
  value       = aws_instance.jenkins_master.id
}

output "jenkins_master_private_ip" {
  description = "Private IP address of the Jenkins master"
  value       = aws_instance.jenkins_master.private_ip
}

output "jenkins_master_security_group_id" {
  description = "ID of the Jenkins master security group"
  value       = aws_security_group.jenkins_master.id
}

# Jenkins Agent Outputs
output "jenkins_agent_instance_ids" {
  description = "List of Jenkins agent instance IDs"
  value       = var.enable_agents ? aws_instance.jenkins_agents[*].id : []
}

output "jenkins_agent_private_ips" {
  description = "List of Jenkins agent private IP addresses"
  value       = var.enable_agents ? aws_instance.jenkins_agents[*].private_ip : []
}

output "jenkins_agent_security_group_id" {
  description = "ID of the Jenkins agent security group"
  value       = var.enable_agents ? aws_security_group.jenkins_agent[0].id : null
}

# IAM Outputs
output "jenkins_master_iam_role_arn" {
  description = "ARN of the Jenkins master IAM role"
  value       = aws_iam_role.jenkins_master_role.arn
}

output "jenkins_agent_iam_role_arn" {
  description = "ARN of the Jenkins agent IAM role"
  value       = var.enable_agents ? aws_iam_role.jenkins_agent_role[0].arn : null
}

# Key Pair Outputs
output "master_key_name" {
  description = "Name of the key pair used for Jenkins master"
  value       = var.create_master_key_pair ? aws_key_pair.jenkins_master_key[0].key_name : var.master_key_name
}

output "agent_key_name" {
  description = "Name of the key pair used for Jenkins agents"
  value       = var.enable_agents && var.create_agent_key_pair ? aws_key_pair.jenkins_agent_key[0].key_name : var.agent_key_name
}

output "master_private_key_path" {
  description = "Path to the Jenkins master private key file"
  value       = var.create_master_key_pair ? local_file.jenkins_master_private_key[0].filename : null
  sensitive   = true
}

output "agent_private_key_path" {
  description = "Path to the Jenkins agent private key file"
  value       = var.enable_agents && var.create_agent_key_pair ? local_file.jenkins_agent_private_key[0].filename : null
  sensitive   = true
}

# Access Information
output "jenkins_master_ssh_command" {
  description = "SSH command to connect to Jenkins master via bastion"
  value       = "ssh -J ec2-user@<BASTION_PUBLIC_IP> ec2-user@${aws_instance.jenkins_master.private_ip}"
  sensitive   = true
}

output "jenkins_tunnel_command" {
  description = "SSH tunnel command to access Jenkins web UI"
  value       = "ssh -L 8080:${aws_instance.jenkins_master.private_ip}:${var.jenkins_port} ec2-user@<BASTION_PUBLIC_IP>"
  sensitive   = true
}

output "jenkins_access_url" {
  description = "URL to access Jenkins after setting up SSH tunnel"
  value       = "http://localhost:8080"
}

# CloudWatch Log Groups
output "jenkins_master_log_group" {
  description = "CloudWatch log group for Jenkins master"
  value       = var.enable_cloudwatch_logs ? aws_cloudwatch_log_group.jenkins_master[0].name : null
}

output "jenkins_agents_log_group" {
  description = "CloudWatch log group for Jenkins agents"
  value       = var.enable_cloudwatch_logs && var.enable_agents ? aws_cloudwatch_log_group.jenkins_agents[0].name : null
}

# Cluster Information
output "jenkins_cluster_info" {
  description = "Jenkins cluster information"
  value = {
    master_ip    = aws_instance.jenkins_master.private_ip
    agent_count  = var.enable_agents ? var.agent_count : 0
    agent_ips    = var.enable_agents ? aws_instance.jenkins_agents[*].private_ip : []
    jenkins_port = var.jenkins_port
    agent_port   = var.jenkins_agent_port
  }
}