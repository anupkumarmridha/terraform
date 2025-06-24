# Get current AWS account ID and region
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_elb_service_account" "main" {}

# Application Load Balancer
resource "aws_lb" "app_alb" {
  name               = "${local.name_prefix}-app-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_security_group_id]
  subnets            = var.public_subnet_ids

  enable_deletion_protection = var.enable_deletion_protection

  dynamic "access_logs" {
    for_each = var.enable_access_logs ? [1] : []
    content {
      bucket  = aws_s3_bucket.alb_logs[0].bucket
      prefix  = "alb-logs"
      enabled = true
    }
  }

  tags = merge(var.common_tags, {
    Name = "${local.name_prefix}-app-alb"
  })
}

# S3 bucket for ALB access logs
resource "aws_s3_bucket" "alb_logs" {
  count         = var.enable_access_logs ? 1 : 0
  bucket        = "${local.name_prefix}-alb-logs-${local.bucket_suffix}"
  force_destroy = var.bucket_force_destroy
  
  tags = merge(var.common_tags, {
    Name = "${local.name_prefix}-alb-logs"
  })
}

resource "aws_s3_bucket_versioning" "alb_logs_versioning" {
  count  = var.enable_access_logs ? 1 : 0
  bucket = aws_s3_bucket.alb_logs[0].id
  
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "alb_logs_encryption" {
  count  = var.enable_access_logs ? 1 : 0
  bucket = aws_s3_bucket.alb_logs[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "alb_logs_pab" {
  count  = var.enable_access_logs ? 1 : 0
  bucket = aws_s3_bucket.alb_logs[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ALB logs bucket policy
resource "aws_s3_bucket_policy" "alb_logs_policy" {
  count  = var.enable_access_logs ? 1 : 0
  bucket = aws_s3_bucket.alb_logs[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = data.aws_elb_service_account.main.arn
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.alb_logs[0].arn}/alb-logs/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
      },
      {
        Effect = "Allow"
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.alb_logs[0].arn}/alb-logs/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      },
      {
        Effect = "Allow"
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.alb_logs[0].arn
      }
    ]
  })
}

# Target Group
resource "aws_lb_target_group" "app_tg" {
  name     = "${local.name_prefix}-app-tg"
  port     = var.target_group_port
  protocol = var.target_group_protocol
  vpc_id   = var.vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = var.health_check_healthy_threshold
    interval            = var.health_check_interval
    matcher             = "200"
    path                = var.health_check_path
    port                = "traffic-port"
    protocol            = var.target_group_protocol
    timeout             = var.health_check_timeout
    unhealthy_threshold = var.health_check_unhealthy_threshold
  }

  tags = merge(var.common_tags, {
    Name = "${local.name_prefix}-app-tg"
  })
}

# ALB Listener
resource "aws_lb_listener" "app_listener" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = var.listener_port
  protocol          = var.listener_protocol

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }

  tags = merge(var.common_tags, {
    Name = "${local.name_prefix}-app-listener"
  })
}