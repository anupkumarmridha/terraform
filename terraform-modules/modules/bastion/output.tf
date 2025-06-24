output "bastion_instance_id" {
  description = "ID of the bastion instance"
  value       = aws_instance.bastion.id
}

output "bastion_instance_arn" {
  description = "ARN of the bastion instance"
  value       = aws_instance.bastion.arn
}

output "bastion_public_ip" {
  description = "Public IP of the bastion instance"
  value       = var.enable_eip ? aws_eip.bastion[0].public_ip : aws_instance.bastion.public_ip
}

output "bastion_private_ip" {
  description = "Private IP of the bastion instance"
  value       = aws_instance.bastion.private_ip
}

output "bastion_public_dns" {
  description = "Public DNS name of the bastion instance"
  value       = aws_instance.bastion.public_dns
}

output "bastion_private_dns" {
  description = "Private DNS name of the bastion instance"
  value       = aws_instance.bastion.private_dns
}

output "key_pair_name" {
  description = "Name of the key pair used by bastion"
  value       = var.create_key_pair ? aws_key_pair.bastion_key[0].key_name : var.key_name
}

output "private_key_path" {
  description = "Path to the private key file"
  value       = var.create_key_pair ? local_file.bastion_private_key[0].filename : null
  sensitive   = true
}

output "ssh_connection_command" {
  description = "SSH command to connect to bastion"
  value       = var.create_key_pair ? "ssh -i ${local_file.bastion_private_key[0].filename} ec2-user@${var.enable_eip ? aws_eip.bastion[0].public_ip : aws_instance.bastion.public_ip}" : "ssh -i /path/to/${var.key_name}.pem ec2-user@${var.enable_eip ? aws_eip.bastion[0].public_ip : aws_instance.bastion.public_ip}"
}

output "elastic_ip_id" {
  description = "ID of the Elastic IP (if enabled)"
  value       = var.enable_eip ? aws_eip.bastion[0].id : null
}

output "elastic_ip_allocation_id" {
  description = "Allocation ID of the Elastic IP (if enabled)"
  value       = var.enable_eip ? aws_eip.bastion[0].allocation_id : null
}

output "bastion_security_group_id" {
  description = "ID of the bastion security group"
  value       = length(var.security_group_ids) > 0 ? var.security_group_ids[0] : null
}

output "bastion_availability_zone" {
  description = "Availability zone of the bastion instance"
  value       = aws_instance.bastion.availability_zone
}

output "bastion_subnet_id" {
  description = "Subnet ID where bastion is deployed"
  value       = aws_instance.bastion.subnet_id
}