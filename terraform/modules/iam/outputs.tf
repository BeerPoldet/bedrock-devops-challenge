output "role_arn" {
  description = "ARN of the application IAM role for IRSA"
  value       = aws_iam_role.app_role.arn
}

output "role_name" {
  description = "Name of the application IAM role"
  value       = aws_iam_role.app_role.name
}

output "app_policy_arn" {
  description = "ARN of the application S3 access policy"
  value       = aws_iam_policy.s3_access_policy.arn
}

output "app_service_account_name" {
  description = "Name of the application Kubernetes service account"
  value       = var.app_service_account_name
}

output "app_namespace" {
  description = "Kubernetes namespace for the application"
  value       = var.app_namespace
}

output "prometheus_role_arn" {
  description = "ARN of the Prometheus service account IAM role for IRSA"
  value       = aws_iam_role.prometheus_role.arn
}

output "prometheus_role_name" {
  description = "Name of the Prometheus service account IAM role"
  value       = aws_iam_role.prometheus_role.name
}

output "prometheus_policy_arn" {
  description = "ARN of the Prometheus IAM policy"
  value       = aws_iam_policy.prometheus_policy.arn
}

output "prometheus_service_account_name" {
  description = "Name of the Prometheus Kubernetes service account"
  value       = var.prometheus_service_account_name
}

output "prometheus_namespace" {
  description = "Kubernetes namespace for Prometheus"
  value       = var.prometheus_namespace
}

# GitHub Actions Outputs
output "github_oidc_provider_arn" {
  description = "ARN of the GitHub OIDC provider"
  value       = var.github_repo != "" ? aws_iam_openid_connect_provider.github[0].arn : ""
}

output "github_actions_role_arn" {
  description = "ARN of the GitHub Actions IAM role"
  value       = var.github_repo != "" ? aws_iam_role.github_actions[0].arn : ""
}

output "github_actions_role_name" {
  description = "Name of the GitHub Actions IAM role"
  value       = var.github_repo != "" ? aws_iam_role.github_actions[0].name : ""
}

output "github_actions_policy_arn" {
  description = "ARN of the GitHub Actions ECR push policy"
  value       = var.github_repo != "" ? aws_iam_policy.ecr_push[0].arn : ""
}
