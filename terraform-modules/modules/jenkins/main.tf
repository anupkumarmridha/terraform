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

# Create a directory for keys
resource "local_file" "keys_directory" {
  count = var.create_key_pair ? 1 : 0
  
  content  = ""
  filename = "${path.module}/keys/.gitkeep"
}

# Generate private key for Jenkins (conditional)
resource "tls_private_key" "jenkins_key" {
  count = var.create_key_pair ? 1 : 0
  
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create AWS key pair (conditional)
resource "aws_key_pair" "jenkins_key" {
  count = var.create_key_pair ? 1 : 0
  
  key_name   = var.key_name
  public_key = tls_private_key.jenkins_key[0].public_key_openssh

  tags = merge(var.common_tags, {
    Name = "${local.name_prefix}-jenkins-key"
  })
}

# Save private key to local file (conditional)
resource "local_file" "jenkins_private_key" {
  count = var.create_key_pair ? 1 : 0
  
  content         = tls_private_key.jenkins_key[0].private_key_pem
  filename        = "${path.module}/keys/${var.key_name}.pem"
  file_permission = "0600"

  depends_on = [local_file.keys_directory]
}

# Security group for Jenkins server
resource "aws_security_group" "jenkins" {
  name        = "${local.name_prefix}-jenkins-sg"
  description = "Security group for Jenkins server"
  vpc_id      = var.vpc_id

  tags = merge(var.common_tags, {
    Name = "${local.name_prefix}-jenkins-sg"
    Tier = "Management"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Jenkins security group rules - SSH from bastion only
resource "aws_vpc_security_group_ingress_rule" "jenkins_ssh_from_bastion" {
  security_group_id            = aws_security_group.jenkins.id
  referenced_security_group_id = var.bastion_security_group_id
  from_port                    = var.ssh_port
  ip_protocol                  = "tcp"
  to_port                      = var.ssh_port
  description                  = "SSH from bastion host"
}

# Jenkins security group rules - Jenkins port from bastion only (for SSH tunnel)
resource "aws_vpc_security_group_ingress_rule" "jenkins_http_from_bastion" {
  security_group_id            = aws_security_group.jenkins.id
  referenced_security_group_id = var.bastion_security_group_id
  from_port                    = var.jenkins_port
  ip_protocol                  = "tcp"
  to_port                      = var.jenkins_port
  description                  = "Jenkins port from bastion host (for SSH tunnel)"
}

# Jenkins security group rules - Allow outbound traffic
resource "aws_vpc_security_group_egress_rule" "jenkins_all_traffic" {
  security_group_id = aws_security_group.jenkins.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
  description       = "All outbound traffic"
}

# IAM role for Jenkins server
resource "aws_iam_role" "jenkins_role" {
  name = "${local.name_prefix}-jenkins-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(var.common_tags, {
    Name = "${local.name_prefix}-jenkins-role"
  })
}

# IAM policy for Jenkins server to access ASG instances
resource "aws_iam_role_policy" "jenkins_policy" {
  name = "${local.name_prefix}-jenkins-policy"
  role = aws_iam_role.jenkins_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
            "autoscaling:DescribeAutoScalingGroups",
            "autoscaling:DescribeAutoScalingInstances",
            "autoscaling:StartInstanceRefresh",
            "autoscaling:DescribeInstanceRefreshes",
            "autoscaling:CancelInstanceRefresh",
            "ec2:DescribeInstances",
            "ec2:DescribeInstanceStatus",
            "ec2:StartInstances",
            "ec2:StopInstances",
            "ec2:DescribeLaunchTemplates",
            "ec2:DescribeLaunchTemplateVersions",
            "ec2:GetLaunchTemplateData",
            "ec2:RunInstances", 
            "ec2:CreateTags", 
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents",
            "logs:DescribeLogStreams",
            "logs:DescribeLogGroups",
            "cloudwatch:PutMetricData",
            "ssm:SendCommand",
            
        ]
        Resource = "*"
      }
    ]
  })
}

# Attach AWS managed policies
resource "aws_iam_role_policy_attachment" "jenkins_ssm" {
  role       = aws_iam_role.jenkins_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "jenkins_cloudwatch" {
  role       = aws_iam_role.jenkins_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Instance profile for Jenkins
resource "aws_iam_instance_profile" "jenkins_profile" {
  name = "${local.name_prefix}-jenkins-profile"
  role = aws_iam_role.jenkins_role.name

  tags = merge(var.common_tags, {
    Name = "${local.name_prefix}-jenkins-profile"
  })
}

# Jenkins EC2 instance
resource "aws_instance" "jenkins" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = var.instance_type
  subnet_id              = var.private_subnet_id
  key_name               = var.create_key_pair ? aws_key_pair.jenkins_key[0].key_name : var.key_name
  vpc_security_group_ids = [aws_security_group.jenkins.id]
  monitoring             = var.enable_detailed_monitoring
  iam_instance_profile   = aws_iam_instance_profile.jenkins_profile.name

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
    Name = "${local.name_prefix}-jenkins"
    Type = "Jenkins"
    Tier = "Management"
  })

  lifecycle {
    create_before_destroy = true
    ignore_changes = [
      ami
    ]
  }

  depends_on = [aws_key_pair.jenkins_key]
}

# Security group rule to allow Jenkins to access ASG instances
resource "aws_vpc_security_group_ingress_rule" "app_from_jenkins" {
  security_group_id            = var.app_security_group_id
  referenced_security_group_id = aws_security_group.jenkins.id
  ip_protocol                  = "-1"
  description                  = "All traffic from Jenkins server"
}
