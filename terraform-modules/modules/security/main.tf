# Default security group for VPC
resource "aws_default_security_group" "default" {
  vpc_id = var.vpc_id

  # Remove all default rules
  ingress = []
  egress  = []

  tags = merge(var.common_tags, {
    Name = "${local.name_prefix}-default-sg"
  })
}

# Web tier security group
resource "aws_security_group" "web" {
  name        = "${local.name_prefix}-web-sg"
  description = "Security group for web servers"
  vpc_id      = var.vpc_id

  tags = merge(var.common_tags, {
    Name = "${local.name_prefix}-web-sg"
    Tier = "Web"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Web tier security group rules
resource "aws_vpc_security_group_ingress_rule" "web_http" {
  security_group_id = aws_security_group.web.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = var.web_http_port
  ip_protocol       = "tcp"
  to_port           = var.web_http_port
  description       = "HTTP from anywhere"
}

resource "aws_vpc_security_group_ingress_rule" "web_https" {
  security_group_id = aws_security_group.web.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = var.web_https_port
  ip_protocol       = "tcp"
  to_port           = var.web_https_port
  description       = "HTTPS from anywhere"
}

resource "aws_vpc_security_group_egress_rule" "web_all_traffic" {
  security_group_id = aws_security_group.web.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
  description       = "All outbound traffic"
}

# Application tier security group
resource "aws_security_group" "app" {
  name        = "${local.name_prefix}-app-sg"
  description = "Security group for application servers"
  vpc_id      = var.vpc_id

  tags = merge(var.common_tags, {
    Name = "${local.name_prefix}-app-sg"
    Tier = "Application"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Application tier security group rules
resource "aws_vpc_security_group_ingress_rule" "app_from_web" {
  security_group_id            = aws_security_group.app.id
  referenced_security_group_id = aws_security_group.web.id
  from_port                    = var.app_port
  ip_protocol                  = "tcp"
  to_port                      = var.app_port
  description                  = "Application port from web tier"
}

resource "aws_vpc_security_group_ingress_rule" "app_ssh_from_bastion" {
  security_group_id            = aws_security_group.app.id
  referenced_security_group_id = aws_security_group.bastion.id
  from_port                    = var.ssh_port
  ip_protocol                  = "tcp"
  to_port                      = var.ssh_port
  description                  = "SSH from bastion host"
}

resource "aws_vpc_security_group_ingress_rule" "app_from_alb" {
  security_group_id            = aws_security_group.app.id
  referenced_security_group_id = aws_security_group.alb.id
  from_port                    = var.app_port
  ip_protocol                  = "tcp"
  to_port                      = var.app_port
  description                  = "Application port from ALB"
}

resource "aws_vpc_security_group_egress_rule" "app_all_traffic" {
  security_group_id = aws_security_group.app.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
  description       = "All outbound traffic"
}

# Database security group
resource "aws_security_group" "database" {
  name        = "${local.name_prefix}-db-sg"
  description = "Security group for database servers"
  vpc_id      = var.vpc_id

  tags = merge(var.common_tags, {
    Name = "${local.name_prefix}-db-sg"
    Tier = "Database"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Database security group rules
resource "aws_vpc_security_group_ingress_rule" "db_mysql_from_app" {
  security_group_id            = aws_security_group.database.id
  referenced_security_group_id = aws_security_group.app.id
  from_port                    = var.mysql_port
  ip_protocol                  = "tcp"
  to_port                      = var.mysql_port
  description                  = "MySQL from app tier"
}

resource "aws_vpc_security_group_ingress_rule" "db_postgresql_from_app" {
  security_group_id            = aws_security_group.database.id
  referenced_security_group_id = aws_security_group.app.id
  from_port                    = var.postgresql_port
  ip_protocol                  = "tcp"
  to_port                      = var.postgresql_port
  description                  = "PostgreSQL from app tier"
}

resource "aws_vpc_security_group_egress_rule" "db_vpc_traffic" {
  security_group_id = aws_security_group.database.id
  cidr_ipv4         = var.vpc_cidr_block
  ip_protocol       = "-1"
  description       = "Outbound traffic within VPC only"
}

# Bastion host security group
resource "aws_security_group" "bastion" {
  name        = "${local.name_prefix}-bastion-sg"
  description = "Security group for bastion host"
  vpc_id      = var.vpc_id

  tags = merge(var.common_tags, {
    Name = "${local.name_prefix}-bastion-sg"
    Tier = "Management"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Bastion security group rules
resource "aws_vpc_security_group_ingress_rule" "bastion_ssh" {
  for_each = toset(var.allowed_ssh_cidrs)

  security_group_id = aws_security_group.bastion.id
  cidr_ipv4         = each.value
  from_port         = var.ssh_port
  ip_protocol       = "tcp"
  to_port           = var.ssh_port
  description       = "SSH from allowed IP: ${each.value}"
}

# Conditional HTTP access for bastion
resource "aws_vpc_security_group_ingress_rule" "bastion_http" {
  count = var.enable_bastion_http ? 1 : 0

  security_group_id = aws_security_group.bastion.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = var.web_http_port
  ip_protocol       = "tcp"
  to_port           = var.web_http_port
  description       = "HTTP from anywhere"
}

resource "aws_vpc_security_group_egress_rule" "bastion_all_traffic" {
  security_group_id = aws_security_group.bastion.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
  description       = "All outbound traffic"
}

# Load Balancer security group (ALB/NLB)
resource "aws_security_group" "alb" {
  name        = "${local.name_prefix}-alb-sg"
  description = "Security group for Application Load Balancer"
  vpc_id      = var.vpc_id

  tags = merge(var.common_tags, {
    Name = "${local.name_prefix}-alb-sg"
    Tier = "LoadBalancer"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# ALB security group rules
resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = var.web_http_port
  ip_protocol       = "tcp"
  to_port           = var.web_http_port
  description       = "HTTP from internet"
}

resource "aws_vpc_security_group_ingress_rule" "alb_https" {
  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = var.web_https_port
  ip_protocol       = "tcp"
  to_port           = var.web_https_port
  description       = "HTTPS from internet"
}

resource "aws_vpc_security_group_egress_rule" "alb_to_app" {
  security_group_id            = aws_security_group.alb.id
  referenced_security_group_id = aws_security_group.app.id
  from_port                    = var.app_port
  ip_protocol                  = "tcp"
  to_port                      = var.app_port
  description                  = "Application port to app tier"
}