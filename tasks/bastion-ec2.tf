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

resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.al2023.id
  instance_type               = var.bastion_instance_type
  subnet_id                   = aws_subnet.public[0].id
  associate_public_ip_address = true
  key_name                    = var.bastion_key_name
  vpc_security_group_ids      = [aws_security_group.bastion.id]
  tags = {
    Name        = "${var.project_name}-${var.environment}-bastion"
    Environment = var.environment
  }
  user_data = file("./scripts/bastion-userdata.sh")
  lifecycle {
    create_before_destroy = true
  }

  depends_on = [aws_security_group.bastion, aws_key_pair.bastion_key]

}
