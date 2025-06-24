locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# Get the latest Amazon Linux 2023 AMI
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-kernel-*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Generate private key for bastion (conditional)
resource "tls_private_key" "bastion_key" {
  count = var.create_key_pair ? 1 : 0
  
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create AWS key pair (conditional)
resource "aws_key_pair" "bastion_key" {
  count = var.create_key_pair ? 1 : 0
  
  key_name   = var.key_name
  public_key = tls_private_key.bastion_key[0].public_key_openssh

  tags = merge(var.common_tags, {
    Name = "${local.name_prefix}-bastion-key"
  })
}

# Create keys directory
resource "local_file" "keys_directory" {
  count = var.create_key_pair ? 1 : 0
  
  content  = ""
  filename = "${path.module}/keys/.gitkeep"
}

# Save private key to local file (conditional)
resource "local_file" "bastion_private_key" {
  count = var.create_key_pair ? 1 : 0
  
  content         = tls_private_key.bastion_key[0].private_key_pem
  filename        = "${path.module}/keys/${var.key_name}.pem"
  file_permission = "0600"

  depends_on = [local_file.keys_directory]
}

# Elastic IP for bastion (conditional)
resource "aws_eip" "bastion" {
  count = var.enable_eip ? 1 : 0
  
  domain = "vpc"

  tags = merge(var.common_tags, {
    Name = "${local.name_prefix}-bastion-eip"
  })
}

# Bastion EC2 instance
resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.al2023.id
  instance_type               = var.instance_type
  subnet_id                   = var.public_subnet_id
  associate_public_ip_address = var.enable_eip ? false : true
  key_name                    = var.create_key_pair ? aws_key_pair.bastion_key[0].key_name : var.key_name
  vpc_security_group_ids      = var.security_group_ids
  monitoring                  = var.enable_detailed_monitoring
  ipv6_address_count          = var.enable_ipv6 ? 1 : 0

  root_block_device {
    volume_type           = var.root_volume_type
    volume_size           = var.root_volume_size
    encrypted             = true
    delete_on_termination = true
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
    instance_metadata_tags      = "enabled"
  }

  user_data = var.user_data_script_path != "" ? file(var.user_data_script_path) : null

  tags = merge(var.common_tags, {
    Name = "${local.name_prefix}-bastion"
    Type = "Bastion"
    Tier = "Management"
  })

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [aws_key_pair.bastion_key]
}

# Associate Elastic IP with bastion instance (conditional)
resource "aws_eip_association" "bastion" {
  count = var.enable_eip ? 1 : 0
  
  instance_id   = aws_instance.bastion.id
  allocation_id = aws_eip.bastion[0].id
}