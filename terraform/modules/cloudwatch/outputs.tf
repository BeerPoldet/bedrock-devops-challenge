output "log_group_name" {
  description = "Name of the main CloudWatch log group"
  value       = aws_cloudwatch_log_group.main.name
}

output "log_group_arn" {
  description = "ARN of the main CloudWatch log group"
  value       = aws_cloudwatch_log_group.main.arn
}

output "application_log_group_name" {
  description = "Name of the application CloudWatch log group"
  value       = aws_cloudwatch_log_group.application_logs.name
}

output "application_log_group_arn" {
  description = "ARN of the application CloudWatch log group"
  value       = aws_cloudwatch_log_group.application_logs.arn
}

output "access_log_group_name" {
  description = "Name of the access CloudWatch log group"
  value       = aws_cloudwatch_log_group.access_logs.name
}

output "access_log_group_arn" {
  description = "ARN of the access CloudWatch log group"
  value       = aws_cloudwatch_log_group.access_logs.arn
}