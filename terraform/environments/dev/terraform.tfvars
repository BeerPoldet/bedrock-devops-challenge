environment = "dev"
bucket_name = "app"

# S3 Configuration
lifecycle_expiration_days = 30
lifecycle_transition_days = 7
versioning_enabled        = true

# IAM Configuration
app_role_name = "app-role"

# CloudWatch Configuration
log_group_name    = "/aws/bedrock/dev"
retention_in_days = 7

# Prometheus Configuration
prometheus_service_account_name = "prometheus"
enable_custom_metrics           = true

# EKS Cluster Configuration
cluster_name      = "bedrock-cluster"
oidc_provider_arn = ""
oidc_provider_url = ""

# Prometheus EKS Service Account Configuration
prometheus_namespace = "monitoring"
prometheus_labels    = {}

# Application EKS Service Account Configuration
app_service_account_name = "app"
app_namespace            = "default"
app_labels               = {}

# Custom AWS Endpoint Configuration
# Use "http://localhost:4566" for Docker Desktop/Podman
# Use "http://orbstack.orb.local:4566" for OrbStack
aws_endpoint = "http://localstack.orb.local:4566"

# ECR Configuration
ecr_repository_name = "bedrock-devops-app"

# GitHub Actions Configuration
github_repo = "bedrock/devops-challenge"
github_actions_role_name = "github-actions-ecr"

# Tags
tags = {
  Environment = "dev"
  Project     = "bedrock-devops-challenge"
  ManagedBy   = "terraform"
}
