# Auto Scaling Group
resource "aws_autoscaling_group" "main" {
  name                      = "${local.name_prefix}-asg"
  vpc_zone_identifier       = var.subnet_ids
  target_group_arns         = var.target_group_arns
  health_check_type         = var.health_check_type
  health_check_grace_period = var.health_check_grace_period
  default_cooldown          = var.default_cooldown

  min_size         = var.min_size
  max_size         = var.max_size
  desired_capacity = var.desired_capacity

  launch_template {
    id      = var.launch_template_id
    version = var.launch_template_version
  }

  # Instance refresh configuration
  dynamic "instance_refresh" {
    for_each = var.enable_instance_refresh ? [1] : []
    content {
      strategy = var.instance_refresh_strategy
      preferences {
        min_healthy_percentage = var.instance_refresh_min_healthy_percentage
        instance_warmup        = var.instance_refresh_instance_warmup
      }
    }
  }

  # Termination policies
  termination_policies = var.termination_policies

  # Instance protection
  protect_from_scale_in = var.protect_from_scale_in

  # Suspended processes
  suspended_processes = var.suspended_processes

  # CloudWatch metrics
  enabled_metrics = var.enabled_metrics

  # Placement group
  placement_group = var.placement_group != "" ? var.placement_group : null

  # Service linked role
  service_linked_role_arn = var.service_linked_role_arn != "" ? var.service_linked_role_arn : null

  tag {
    key                 = "Name"
    value               = "${local.name_prefix}-asg-instance"
    propagate_at_launch = true
  }

  dynamic "tag" {
    for_each = var.common_tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Auto Scaling Policies
resource "aws_autoscaling_policy" "policies" {
  for_each = { for idx, policy in local.all_policies : idx => policy }
  
  name                   = "${local.name_prefix}-${each.value.name}"
  autoscaling_group_name = aws_autoscaling_group.main.name
  
  # Common attributes
  policy_type        = each.value.policy_type
  adjustment_type    = each.value.adjustment_type
  
  # For SimpleScaling
  scaling_adjustment = each.value.policy_type == "SimpleScaling" ? each.value.scaling_adjustment : null
  cooldown           = each.value.policy_type == "SimpleScaling" ? each.value.cooldown : null
  
  # For StepScaling
  dynamic "step_adjustment" {
    for_each = each.value.policy_type == "StepScaling" ? each.value.step_adjustments : []
    content {
      metric_interval_lower_bound = step_adjustment.value.metric_interval_lower_bound
      metric_interval_upper_bound = step_adjustment.value.metric_interval_upper_bound
      scaling_adjustment          = step_adjustment.value.scaling_adjustment
    }
  }
  
  # For TargetTrackingScaling
  dynamic "target_tracking_configuration" {
    for_each = each.value.policy_type == "TargetTrackingScaling" ? [each.value.target_tracking_configuration] : []
    content {
      target_value       = target_tracking_configuration.value.target_value
      disable_scale_in   = target_tracking_configuration.value.disable_scale_in
      
      dynamic "predefined_metric_specification" {
        for_each = target_tracking_configuration.value.predefined_metric_type != null ? [1] : []
        content {
          predefined_metric_type = target_tracking_configuration.value.predefined_metric_type
        }
      }
      
      dynamic "customized_metric_specification" {
        for_each = target_tracking_configuration.value.customized_metric_specification != null ? [target_tracking_configuration.value.customized_metric_specification] : []
        content {
          metric_name = customized_metric_specification.value.metric_name
          namespace   = customized_metric_specification.value.namespace
          statistic   = customized_metric_specification.value.statistic
          unit        = customized_metric_specification.value.unit
          
          dynamic "metric_dimension" {
            for_each = customized_metric_specification.value.metric_dimension != null ? customized_metric_specification.value.metric_dimension : {}
            content {
              name  = metric_dimension.key
              value = metric_dimension.value
            }
          }
        }
      }
    }
  }
}

# CloudWatch Alarms for Auto Scaling
resource "aws_cloudwatch_metric_alarm" "alarms" {
  for_each = { 
    for idx, policy in local.all_policies : 
    idx => policy if policy.alarm != null && (policy.policy_type == "SimpleScaling" || policy.policy_type == "StepScaling")
  }
  
  alarm_name          = "${local.name_prefix}-${each.value.alarm.name}"
  comparison_operator = each.value.alarm.comparison_operator
  evaluation_periods  = each.value.alarm.evaluation_periods
  metric_name         = each.value.alarm.metric_name
  namespace           = each.value.alarm.namespace
  period              = each.value.alarm.period
  statistic           = each.value.alarm.statistic
  threshold           = each.value.alarm.threshold
  alarm_description   = each.value.alarm.description != null ? each.value.alarm.description : "Alarm for ${each.value.name}"
  alarm_actions       = [aws_autoscaling_policy.policies[each.key].arn]
  
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.main.name
  }
  
  tags = var.common_tags
}
