# Data source for latest Amazon Linux 2023 AMI
data "aws_ami" "al2023" {
  count       = var.ami_id == "" ? 1 : 0
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# CloudWatch Log Groups for application logs
resource "aws_cloudwatch_log_group" "app_logs" {
  count             = var.create_cloudwatch_logs ? 1 : 0
  name              = "/aws/ec2/app/${local.name_prefix}"
  retention_in_days = var.log_retention_days

  tags = merge(var.common_tags, {
    Name = "${local.name_prefix}-app-logs"
  })
}

resource "aws_cloudwatch_log_group" "app_access_logs" {
  count             = var.create_cloudwatch_logs ? 1 : 0
  name              = "/aws/ec2/app-access/${local.name_prefix}"
  retention_in_days = var.access_log_retention_days

  tags = merge(var.common_tags, {
    Name = "${local.name_prefix}-app-access-logs"
  })
}

# IAM role for EC2 instances
resource "aws_iam_role" "instance_role" {
  count = var.create_iam_role ? 1 : 0
  name  = "${local.name_prefix}-instance-role"

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
    Name = "${local.name_prefix}-instance-role"
  })
}

# IAM policy for CloudWatch and SSM
resource "aws_iam_role_policy" "instance_policy" {
  count = var.create_iam_role ? 1 : 0
  name  = "${local.name_prefix}-instance-policy"
  role  = aws_iam_role.instance_role[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData",
          "ec2:DescribeVolumes",
          "ec2:DescribeTags",
          "logs:PutLogEvents",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:DescribeLogStreams",
          "logs:DescribeLogGroups"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:PutParameter",
          "ssm:GetParameters",
          "ssm:UpdateInstanceInformation",
          "ssm:SendCommand"
        ]
        Resource = "*"
      }
    ]
  })
}

# Attach AWS managed policies
resource "aws_iam_role_policy_attachment" "ssm" {
  count      = var.create_iam_role ? 1 : 0
  role       = aws_iam_role.instance_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "cloudwatch" {
  count      = var.create_iam_role ? 1 : 0
  role       = aws_iam_role.instance_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Attach additional IAM policies if provided
resource "aws_iam_role_policy_attachment" "additional_policies" {
  count      = var.create_iam_role ? length(var.additional_iam_policies) : 0
  role       = aws_iam_role.instance_role[0].name
  policy_arn = var.additional_iam_policies[count.index]
}

# Instance profile
resource "aws_iam_instance_profile" "instance_profile" {
  count = var.create_iam_role ? 1 : 0
  name  = "${local.name_prefix}-instance-profile"
  role  = aws_iam_role.instance_role[0].name

  tags = merge(var.common_tags, {
    Name = "${local.name_prefix}-instance-profile"
  })
}

# Generate private key for instances (conditional)
resource "tls_private_key" "instance_key" {
  count = var.create_key_pair ? 1 : 0
  
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create AWS key pair (conditional)
resource "aws_key_pair" "instance_key" {
  count = var.create_key_pair ? 1 : 0
  
  key_name   = var.key_name
  public_key = tls_private_key.instance_key[0].public_key_openssh

  tags = merge(var.common_tags, {
    Name = "${local.name_prefix}-key"
  })
}

# Create keys directory
resource "local_file" "keys_directory" {
  count = var.create_key_pair ? 1 : 0
  
  content  = ""
  filename = "${path.module}/keys/.gitkeep"
}

# Save private key to local file (conditional)
resource "local_file" "instance_private_key" {
  count = var.create_key_pair ? 1 : 0
  
  content         = tls_private_key.instance_key[0].private_key_pem
  filename        = "${path.module}/keys/${var.key_name}.pem"
  file_permission = "0600"

  depends_on = [local_file.keys_directory]
}

# Launch Template
resource "aws_launch_template" "main" {
  name_prefix   = "${local.name_prefix}-"
  image_id      = var.ami_id != "" ? var.ami_id : data.aws_ami.al2023[0].id
  instance_type = var.instance_type
  key_name      = var.create_key_pair ? aws_key_pair.instance_key[0].key_name : var.key_name

  vpc_security_group_ids = var.security_group_ids

  dynamic "iam_instance_profile" {
    for_each = var.create_iam_role ? [1] : (var.iam_instance_profile_name != "" ? [1] : [])
    content {
      name = var.create_iam_role ? aws_iam_instance_profile.instance_profile[0].name : var.iam_instance_profile_name
    }
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_type           = var.root_volume_type
      volume_size           = var.root_volume_size
      encrypted             = var.enable_ebs_encryption
      delete_on_termination = true
    }
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
    instance_metadata_tags      = "enabled"
  }

  monitoring {
    enabled = var.enable_detailed_monitoring
  }

  dynamic "placement" {
    for_each = var.placement_group != "" || var.placement_tenancy != "default" ? [1] : []
    content {
      group_name    = var.placement_group != "" ? var.placement_group : null
      tenancy  = var.placement_tenancy
    }
  }

  dynamic "enclave_options" {
    for_each = var.enable_nitro_enclave ? [1] : []
    content {
      enabled = true
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags = merge(var.common_tags, {
      Name = "${local.name_prefix}-instance"
    })
  }

  tag_specifications {
    resource_type = "volume"
    tags = merge(var.common_tags, {
      Name = "${local.name_prefix}-volume"
    })
  }

  tags = merge(var.common_tags, {
    Name = "${local.name_prefix}-launch-template"
  })

  user_data = var.user_data_base64 != "" ? var.user_data_base64 : (
    var.user_data_script_path != "" ? filebase64(var.user_data_script_path) : 
    base64encode(templatefile("${path.module}/scripts/app-userdata.sh", {
      log_group_name = var.create_cloudwatch_logs ? aws_cloudwatch_log_group.app_logs[0].name : ""
    }))
  )

  lifecycle {
    create_before_destroy = true
  }
}
