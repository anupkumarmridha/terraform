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

# Create keys directory
resource "local_file" "keys_directory" {
  content  = ""
  filename = "${path.module}/keys/.gitkeep"
}

# Generate private key for Jenkins Master
resource "tls_private_key" "jenkins_master_key" {
  count = var.create_master_key_pair ? 1 : 0
  
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create AWS key pair for Master
resource "aws_key_pair" "jenkins_master_key" {
  count = var.create_master_key_pair ? 1 : 0
  
  key_name   = var.master_key_name
  public_key = tls_private_key.jenkins_master_key[0].public_key_openssh

  tags = merge(var.common_tags, {
    Name = "${local.name_prefix}-jenkins-master-key"
  })
}

# Save Master private key to local file
resource "local_file" "jenkins_master_private_key" {
  count = var.create_master_key_pair ? 1 : 0
  
  content         = tls_private_key.jenkins_master_key[0].private_key_pem
  filename        = "${path.module}/keys/${var.master_key_name}.pem"
  file_permission = "0600"

  depends_on = [local_file.keys_directory]
}

# Generate private key for Jenkins Agents
resource "tls_private_key" "jenkins_agent_key" {
  count = var.create_agent_key_pair && var.enable_agents ? 1 : 0
  
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create AWS key pair for Agents
resource "aws_key_pair" "jenkins_agent_key" {
  count = var.create_agent_key_pair && var.enable_agents ? 1 : 0
  
  key_name   = var.agent_key_name
  public_key = tls_private_key.jenkins_agent_key[0].public_key_openssh

  tags = merge(var.common_tags, {
    Name = "${local.name_prefix}-jenkins-agent-key"
  })
}

# Save Agent private key to local file
resource "local_file" "jenkins_agent_private_key" {
  count = var.create_agent_key_pair && var.enable_agents ? 1 : 0
  
  content         = tls_private_key.jenkins_agent_key[0].private_key_pem
  filename        = "${path.module}/keys/${var.agent_key_name}.pem"
  file_permission = "0600"

  depends_on = [local_file.keys_directory]
}

# Security group for Jenkins Master
resource "aws_security_group" "jenkins_master" {
  name        = "${local.name_prefix}-jenkins-master-sg"
  description = "Security group for Jenkins master server"
  vpc_id      = var.vpc_id

  tags = merge(var.common_tags, {
    Name = "${local.name_prefix}-jenkins-master-sg"
    Tier = "Management"
    Role = "JenkinsMaster"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Security group for Jenkins Agents
resource "aws_security_group" "jenkins_agent" {
  count = var.enable_agents ? 1 : 0
  
  name        = "${local.name_prefix}-jenkins-agent-sg"
  description = "Security group for Jenkins agent servers"
  vpc_id      = var.vpc_id

  tags = merge(var.common_tags, {
    Name = "${local.name_prefix}-jenkins-agent-sg"
    Tier = "Management"
    Role = "JenkinsAgent"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Jenkins Master Security Group Rules
resource "aws_vpc_security_group_ingress_rule" "master_ssh_from_bastion" {
  security_group_id            = aws_security_group.jenkins_master.id
  referenced_security_group_id = var.bastion_security_group_id
  from_port                    = var.ssh_port
  ip_protocol                  = "tcp"
  to_port                      = var.ssh_port
  description                  = "SSH from bastion host"
}

resource "aws_vpc_security_group_ingress_rule" "master_http_from_bastion" {
  security_group_id            = aws_security_group.jenkins_master.id
  referenced_security_group_id = var.bastion_security_group_id
  from_port                    = var.jenkins_port
  ip_protocol                  = "tcp"
  to_port                      = var.jenkins_port
  description                  = "Jenkins HTTP from bastion host"
}

resource "aws_vpc_security_group_ingress_rule" "master_agent_port_from_agents" {
  count = var.enable_agents ? 1 : 0
  
  security_group_id            = aws_security_group.jenkins_master.id
  referenced_security_group_id = aws_security_group.jenkins_agent[0].id
  from_port                    = var.jenkins_agent_port
  ip_protocol                  = "tcp"
  to_port                      = var.jenkins_agent_port
  description                  = "Jenkins agent communication port"
}

resource "aws_vpc_security_group_egress_rule" "master_all_traffic" {
  security_group_id = aws_security_group.jenkins_master.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
  description       = "All outbound traffic"
}

# Jenkins Agent Security Group Rules
resource "aws_vpc_security_group_ingress_rule" "agent_ssh_from_bastion" {
  count = var.enable_agents ? 1 : 0
  
  security_group_id            = aws_security_group.jenkins_agent[0].id
  referenced_security_group_id = var.bastion_security_group_id
  from_port                    = var.ssh_port
  ip_protocol                  = "tcp"
  to_port                      = var.ssh_port
  description                  = "SSH from bastion host"
}

resource "aws_vpc_security_group_ingress_rule" "agent_ssh_from_master" {
  count = var.enable_agents ? 1 : 0
  
  security_group_id            = aws_security_group.jenkins_agent[0].id
  referenced_security_group_id = aws_security_group.jenkins_master.id
  from_port                    = var.ssh_port
  ip_protocol                  = "tcp"
  to_port                      = var.ssh_port
  description                  = "SSH from Jenkins master"
}

resource "aws_vpc_security_group_egress_rule" "agent_all_traffic" {
  count = var.enable_agents ? 1 : 0
  
  security_group_id = aws_security_group.jenkins_agent[0].id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
  description       = "All outbound traffic"
}

# CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "jenkins_master" {
  count = var.enable_cloudwatch_logs ? 1 : 0
  
  name              = "/aws/ec2/jenkins-master/${local.name_prefix}"
  retention_in_days = var.log_retention_days

  tags = merge(var.common_tags, {
    Name = "${local.name_prefix}-jenkins-master-logs"
  })
}

resource "aws_cloudwatch_log_group" "jenkins_agents" {
  count = var.enable_cloudwatch_logs && var.enable_agents ? 1 : 0
  
  name              = "/aws/ec2/jenkins-agents/${local.name_prefix}"
  retention_in_days = var.log_retention_days

  tags = merge(var.common_tags, {
    Name = "${local.name_prefix}-jenkins-agents-logs"
  })
}

# IAM role for Jenkins Master
resource "aws_iam_role" "jenkins_master_role" {
  name = "${local.name_prefix}-jenkins-master-role"

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
    Name = "${local.name_prefix}-jenkins-master-role"
  })
}

# IAM policy for Jenkins Master
resource "aws_iam_role_policy" "jenkins_master_policy" {
  name = "${local.name_prefix}-jenkins-master-policy"
  role = aws_iam_role.jenkins_master_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "autoscaling:*",
          "ec2:*",
          "logs:*",
          "cloudwatch:*",
          "ssm:*",
          "iam:PassRole",
          "iam:ListRoles",
          "iam:ListInstanceProfiles"
        ]
        Resource = "*"
      }
    ]
  })
}

# IAM role for Jenkins Agents
resource "aws_iam_role" "jenkins_agent_role" {
  count = var.enable_agents ? 1 : 0
  
  name = "${local.name_prefix}-jenkins-agent-role"

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
    Name = "${local.name_prefix}-jenkins-agent-role"
  })
}

# IAM policy for Jenkins Agents
resource "aws_iam_role_policy" "jenkins_agent_policy" {
  count = var.enable_agents ? 1 : 0
  
  name = "${local.name_prefix}-jenkins-agent-policy"
  role = aws_iam_role.jenkins_agent_role[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams",
          "logs:DescribeLogGroups",
          "cloudwatch:PutMetricData",
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceStatus"
        ]
        Resource = "*"
      }
    ]
  })
}

# Attach AWS managed policies to Master
resource "aws_iam_role_policy_attachment" "jenkins_master_ssm" {
  role       = aws_iam_role.jenkins_master_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "jenkins_master_cloudwatch" {
  role       = aws_iam_role.jenkins_master_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Attach AWS managed policies to Agents
resource "aws_iam_role_policy_attachment" "jenkins_agent_ssm" {
  count = var.enable_agents ? 1 : 0
  
  role       = aws_iam_role.jenkins_agent_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "jenkins_agent_cloudwatch" {
  count = var.enable_agents ? 1 : 0
  
  role       = aws_iam_role.jenkins_agent_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Instance profiles
resource "aws_iam_instance_profile" "jenkins_master_profile" {
  name = "${local.name_prefix}-jenkins-master-profile"
  role = aws_iam_role.jenkins_master_role.name

  tags = merge(var.common_tags, {
    Name = "${local.name_prefix}-jenkins-master-profile"
  })
}

resource "aws_iam_instance_profile" "jenkins_agent_profile" {
  count = var.enable_agents ? 1 : 0
  
  name = "${local.name_prefix}-jenkins-agent-profile"
  role = aws_iam_role.jenkins_agent_role[0].name

  tags = merge(var.common_tags, {
    Name = "${local.name_prefix}-jenkins-agent-profile"
  })
}

# Jenkins Master EC2 instance
resource "aws_instance" "jenkins_master" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = var.master_instance_type
  subnet_id              = var.private_subnet_ids[0]
  key_name               = var.create_master_key_pair ? aws_key_pair.jenkins_master_key[0].key_name : var.master_key_name
  vpc_security_group_ids = [aws_security_group.jenkins_master.id]
  monitoring             = var.enable_detailed_monitoring
  iam_instance_profile   = aws_iam_instance_profile.jenkins_master_profile.name

  root_block_device {
    volume_type           = var.master_root_volume_type
    volume_size           = var.master_root_volume_size
    encrypted             = true
    delete_on_termination = true

    tags = merge(var.common_tags, {
      Name = "${local.name_prefix}-jenkins-master-root"
    })
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
    instance_metadata_tags      = "enabled"
  }

  user_data = base64encode(templatefile("${path.module}/scripts/jenkins-master-userdata.sh", {
    jenkins_port = var.jenkins_port
    agent_port   = var.jenkins_agent_port
    log_group    = var.enable_cloudwatch_logs ? aws_cloudwatch_log_group.jenkins_master[0].name : ""
    JENKINS_HOME = var.jenkins_home
    ITEM_FULLNAME  = "${local.name_prefix}-jenkins-master"
    ITEM_ROOTDIR  = var.jenkins_home
  }))

  tags = merge(var.common_tags, {
    Name = "${local.name_prefix}-jenkins-master"
    Type = "JenkinsMaster"
    Tier = "Management"
  })

  lifecycle {
    create_before_destroy = true
    ignore_changes = [
      ami,
      user_data
    ]
  }
}

# Jenkins Agent EC2 instances
resource "aws_instance" "jenkins_agents" {
  count = var.enable_agents ? var.agent_count : 0

  ami                    = data.aws_ami.al2023.id
  instance_type          = var.agent_instance_type
  subnet_id              = var.private_subnet_ids[count.index % length(var.private_subnet_ids)]
  key_name               = var.create_agent_key_pair ? aws_key_pair.jenkins_agent_key[0].key_name : var.agent_key_name
  vpc_security_group_ids = [aws_security_group.jenkins_agent[0].id]
  monitoring             = var.enable_detailed_monitoring
  iam_instance_profile   = aws_iam_instance_profile.jenkins_agent_profile[0].name

  root_block_device {
    volume_type           = var.agent_root_volume_type
    volume_size           = var.agent_root_volume_size
    encrypted             = true
    delete_on_termination = true

    tags = merge(var.common_tags, {
      Name = "${local.name_prefix}-jenkins-agent-${count.index + 1}-root"
    })
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
    instance_metadata_tags      = "enabled"
  }

  user_data = base64encode(templatefile("${path.module}/scripts/jenkins-agent-userdata.sh", {
    master_ip    = aws_instance.jenkins_master.private_ip
    jenkins_port = var.jenkins_port
    agent_name   = "agent-${count.index + 1}"
    log_group    = var.enable_cloudwatch_logs ? aws_cloudwatch_log_group.jenkins_agents[0].name : ""
  }))

  tags = merge(var.common_tags, {
    Name = "${local.name_prefix}-jenkins-agent-${count.index + 1}"
    Type = "JenkinsAgent"
    Tier = "Management"
  })

  lifecycle {
    create_before_destroy = true
    ignore_changes = [
      ami,
      user_data
    ]
  }

  depends_on = [aws_instance.jenkins_master]
}

# Allow Jenkins to access ASG instances
resource "aws_vpc_security_group_ingress_rule" "app_from_jenkins_master" {
  security_group_id            = var.app_security_group_id
  referenced_security_group_id = aws_security_group.jenkins_master.id
  ip_protocol                  = "-1"
  description                  = "All traffic from Jenkins master"
}

resource "aws_vpc_security_group_ingress_rule" "app_from_jenkins_agents" {
  count = var.enable_agents ? 1 : 0
  
  security_group_id            = var.app_security_group_id
  referenced_security_group_id = aws_security_group.jenkins_agent[0].id
  ip_protocol                  = "-1"
  description                  = "All traffic from Jenkins agents"
}

# EBS Snapshot for backup (if enabled)
resource "aws_ebs_snapshot" "jenkins_master_backup" {
  count = var.enable_master_backup ? 1 : 0
  
  volume_id   = aws_instance.jenkins_master.root_block_device[0].volume_id
  description = "Jenkins master backup - ${formatdate("YYYY-MM-DD-hhmm", timestamp())}"

  tags = merge(var.common_tags, {
    Name = "${local.name_prefix}-jenkins-master-backup"
    Type = "Backup"
  })

  lifecycle {
    ignore_changes = [description]
  }
}