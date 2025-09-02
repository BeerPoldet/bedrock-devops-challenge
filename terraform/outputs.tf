output "s3_bucket_name" {
  description = "Name of the S3 bucket"
  value       = module.s3.bucket_name
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = module.s3.bucket_arn
}

output "app_role_arn" {
  description = "ARN of the application IAM role"
  value       = module.iam.role_arn
}

output "prometheus_role_arn" {
  description = "ARN of the Prometheus service account IAM role for IRSA"
  value       = module.iam.prometheus_role_arn
}

output "prometheus_role_name" {
  description = "Name of the Prometheus service account IAM role"
  value       = module.iam.prometheus_role_name
}

output "prometheus_service_account_name" {
  description = "Name of the Prometheus Kubernetes service account"
  value       = module.iam.prometheus_service_account_name
}

output "prometheus_namespace" {
  description = "Kubernetes namespace for Prometheus"
  value       = module.iam.prometheus_namespace
}

output "cloudwatch_log_group_name" {
  description = "Name of the main CloudWatch log group"
  value       = module.cloudwatch.log_group_name
}

output "application_log_group_name" {
  description = "Name of the application CloudWatch log group"
  value       = module.cloudwatch.application_log_group_name
}

output "access_log_group_name" {
  description = "Name of the access CloudWatch log group"
  value       = module.cloudwatch.access_log_group_name
}

