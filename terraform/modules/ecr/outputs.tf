output "repository_arn" {
  description = "Full ARN of the repository"
  value       = var.aws_endpoint == "" ? aws_ecr_repository.repository[0].arn : ""
}

output "repository_name" {
  description = "Name of the repository"
  value       = var.repository_name
}

output "repository_url" {
  description = "The URL of the repository"
  value       = var.aws_endpoint == "" ? aws_ecr_repository.repository[0].repository_url : ""
}

output "registry_id" {
  description = "The registry ID where the repository was created"
  value       = var.aws_endpoint == "" ? aws_ecr_repository.repository[0].registry_id : ""
}