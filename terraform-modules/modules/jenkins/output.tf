# Instance outputs
output "jenkins_instance_id" {
  description = "ID of the Jenkins EC2 instance"
  value       = aws_instance.jenkins.id
}

output "jenkins_private_ip" {
  description = "Private IP address of the Jenkins server"
  value       = aws_instance.jenkins.private_ip
}

# Security group outputs
output "jenkins_security_group_id" {
  description = "ID of the Jenkins security group"
  value       = aws_security_group.jenkins.id
}

output "jenkins_security_group_arn" {
  description = "ARN of the Jenkins security group"
  value       = aws_security_group.jenkins.arn
}

# IAM outputs
output "jenkins_iam_role_arn" {
  description = "ARN of the Jenkins IAM role"
  value       = aws_iam_role.jenkins_role.arn
}

output "jenkins_iam_role_name" {
  description = "Name of the Jenkins IAM role"
  value       = aws_iam_role.jenkins_role.name
}

output "jenkins_instance_profile_arn" {
  description = "ARN of the Jenkins instance profile"
  value       = aws_iam_instance_profile.jenkins_profile.arn
}

# Key pair outputs
output "key_name" {
  description = "Name of the key pair used for Jenkins"
  value       = var.create_key_pair ? aws_key_pair.jenkins_key[0].key_name : var.key_name
}

output "private_key_path" {
  description = "Path to the private key file (if created)"
  value       = var.create_key_pair ? local_file.jenkins_private_key[0].filename : null
}

# Access information
output "ssh_command" {
  description = "SSH command to connect to Jenkins via bastion host"
  value       = "ssh -J ec2-user@<BASTION_PUBLIC_IP> ec2-user@${aws_instance.jenkins.private_ip}"
}

output "tunnel_command" {
  description = "SSH tunnel command to access Jenkins web UI"
  value       = "ssh -L 8080:${aws_instance.jenkins.private_ip}:${var.jenkins_port} ec2-user@<BASTION_PUBLIC_IP>"
}

output "access_url" {
  description = "URL to access Jenkins after setting up SSH tunnel"
  value       = "http://localhost:8080"
}
