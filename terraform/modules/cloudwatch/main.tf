resource "aws_cloudwatch_log_group" "main" {
  name              = var.log_group_name
  retention_in_days = var.retention_in_days

  tags = merge(var.tags, {
    Name        = var.log_group_name
    Environment = var.environment
  })
}

resource "aws_cloudwatch_log_group" "application_logs" {
  name              = "${var.log_group_name}/application"
  retention_in_days = var.retention_in_days

  tags = merge(var.tags, {
    Name        = "${var.log_group_name}/application"
    Environment = var.environment
    LogType     = "application"
  })
}

resource "aws_cloudwatch_log_group" "access_logs" {
  name              = "${var.log_group_name}/access"
  retention_in_days = var.retention_in_days

  tags = merge(var.tags, {
    Name        = "${var.log_group_name}/access"
    Environment = var.environment
    LogType     = "access"
  })
}