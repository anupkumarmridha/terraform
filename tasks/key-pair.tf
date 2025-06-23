# Generate private keys
resource "tls_private_key" "bastion_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "tls_private_key" "server_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create AWS key pairs
resource "aws_key_pair" "bastion_key" {
  key_name   = var.bastion_key_name
  public_key = tls_private_key.bastion_key.public_key_openssh

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-bastion-key"
  })
}

resource "aws_key_pair" "server_key" {
  key_name   = var.server_key_name
  public_key = tls_private_key.server_key.public_key_openssh

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-server-key"
  })
}

# Save private keys to local files (for local development only)
resource "local_file" "bastion_private_key" {
  content         = tls_private_key.bastion_key.private_key_pem
  filename        = "${path.module}/keys/${var.bastion_key_name}.pem"
  file_permission = "0600"
}

resource "local_file" "server_private_key" {
  content         = tls_private_key.server_key.private_key_pem
  filename        = "${path.module}/keys/${var.server_key_name}.pem"
  file_permission = "0600"
}