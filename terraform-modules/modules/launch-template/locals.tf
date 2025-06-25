
locals {
  name_prefix = var.template_name_prefix != "" ? var.template_name_prefix : "${var.project_name}-${var.environment}"
}
