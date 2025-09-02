variable "role_name" {
  description = "Name of the IAM role (legacy - kept for compatibility)"
  type        = string
}

variable "bucket_arn" {
  description = "ARN of the S3 bucket"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

# EKS Cluster Configuration (shared)
variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "oidc_provider_arn" {
  description = "ARN of the OIDC provider for the EKS cluster"
  type        = string
}

variable "oidc_provider_url" {
  description = "URL of the OIDC provider for the EKS cluster (without https://)"
  type        = string
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

variable "prometheus_service_account_name" {
  description = "Name of the Prometheus service account"
  type        = string
  default     = "prometheus"
}

variable "prometheus_namespace" {
  description = "Kubernetes namespace for the service account"
  type        = string
  default     = "monitoring"
}

variable "prometheus_labels" {
  description = "Labels to apply to Kubernetes resources"
  type        = map(string)
  default     = {}
}
