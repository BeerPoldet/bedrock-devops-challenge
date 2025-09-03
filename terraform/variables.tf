variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "bucket_name" {
  description = "Name of the S3 bucket"
  type        = string
}

variable "lifecycle_expiration_days" {
  description = "Number of days after which objects expire"
  type        = number
  default     = 90
}

variable "lifecycle_transition_days" {
  description = "Number of days after which objects transition to IA"
  type        = number
  default     = 30
}

variable "versioning_enabled" {
  description = "Enable versioning on the S3 bucket"
  type        = bool
  default     = true
}

variable "app_role_name" {
  description = "Name of the IAM role for application"
  type        = string
}

variable "log_group_name" {
  description = "Name of the CloudWatch log group"
  type        = string
}

variable "retention_in_days" {
  description = "Retention period for logs in days"
  type        = number
  default     = 30
}

variable "prometheus_service_account_name" {
  description = "Name of the Prometheus service account"
  type        = string
}

variable "enable_custom_metrics" {
  description = "Enable permissions for Prometheus custom application metrics"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "aws_endpoint" {
  description = "Custom AWS endpoint URL for services (leave empty for real AWS)"
  type        = string
  default     = ""
}

# EKS Cluster Configuration (shared by all services)
variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "bedrock-cluster"
}

variable "oidc_provider_arn" {
  description = "ARN of the OIDC provider for the EKS cluster"
  type        = string
  default     = ""
}

variable "oidc_provider_url" {
  description = "URL of the OIDC provider for the EKS cluster (without https://)"
  type        = string
  default     = ""
}

# Prometheus EKS Service Account Configuration
variable "prometheus_namespace" {
  description = "Kubernetes namespace for Prometheus"
  type        = string
  default     = "monitoring"
}

variable "prometheus_labels" {
  description = "Labels to apply to Prometheus Kubernetes resources"
  type        = map(string)
  default     = {}
}

# Application EKS Service Account Configuration
variable "app_service_account_name" {
  description = "Name of the application service account"
  type        = string
  default     = "app"
}

variable "app_namespace" {
  description = "Kubernetes namespace for the application"
  type        = string
  default     = "default"
}

variable "app_labels" {
  description = "Labels to apply to application Kubernetes resources"
  type        = map(string)
  default     = {}
}

variable "ecr_repository_name" {
  description = "Name of the ECR repository"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository in the format 'owner/repo'"
  type        = string
}

variable "github_actions_role_name" {
  description = "Name of the IAM role for GitHub Actions"
  type        = string
}

