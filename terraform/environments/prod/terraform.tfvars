environment = "prod"
bucket_name = "app"

# S3 Configuration
lifecycle_expiration_days = 365
lifecycle_transition_days = 30
versioning_enabled        = true

# IAM Configuration
app_role_name = "app-role"

# CloudWatch Configuration
log_group_name    = "/aws/application/prod"
retention_in_days = 90

# Prometheus Configuration
prometheus_service_account_name = "prometheus"
custom_aws_endpoint_enabled     = false
enable_custom_metrics           = true

# EKS Cluster Configuration (shared)
cluster_name        = "bedrock-prod-cluster"
oidc_provider_arn   = ""
oidc_provider_url   = ""

# Prometheus EKS Service Account Configuration
prometheus_namespace                           = "monitoring"
prometheus_labels                              = {}

# Application EKS Service Account Configuration
app_service_account_name                 = "app"
app_namespace                           = "default"
app_labels                              = {}

# Tags
tags = {
  Environment = "prod"
  Project     = "bedrock-devops-challenge"
  ManagedBy   = "terraform"
}
