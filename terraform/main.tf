terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"

  # Custom endpoint configuration - only apply when endpoint is provided
  access_key                  = var.aws_endpoint != "" ? "test" : null
  secret_key                  = var.aws_endpoint != "" ? "test" : null
  s3_use_path_style           = var.aws_endpoint != "" ? true : null
  skip_credentials_validation = var.aws_endpoint != "" ? true : null
  skip_metadata_api_check     = var.aws_endpoint != "" ? true : null
  skip_requesting_account_id  = var.aws_endpoint != "" ? true : null

  dynamic "endpoints" {
    for_each = var.aws_endpoint != "" ? [1] : []
    content {
      cloudwatch     = var.aws_endpoint
      cloudwatchlogs = var.aws_endpoint
      iam            = var.aws_endpoint
      s3             = var.aws_endpoint
      sts            = var.aws_endpoint
    }
  }

  default_tags {
    tags = var.tags
  }
}

module "s3" {
  source = "./modules/s3"

  bucket_name               = var.bucket_name
  environment               = var.environment
  lifecycle_expiration_days = var.lifecycle_expiration_days
  lifecycle_transition_days = var.lifecycle_transition_days
  versioning_enabled        = var.versioning_enabled
  tags                      = var.tags
}

module "iam" {
  source = "./modules/iam"

  role_name   = var.app_role_name
  bucket_arn  = module.s3.bucket_arn
  environment = var.environment
  tags        = var.tags

  # Shared EKS cluster configuration
  cluster_name      = var.cluster_name
  oidc_provider_arn = var.oidc_provider_arn
  oidc_provider_url = var.oidc_provider_url

  # Application IRSA configuration
  app_service_account_name = var.app_service_account_name
  app_namespace            = var.app_namespace
  app_labels               = var.app_labels

  # Prometheus IRSA configuration
  prometheus_service_account_name = var.prometheus_service_account_name
  prometheus_namespace            = var.prometheus_namespace
  prometheus_labels               = var.prometheus_labels

  # GitHub Actions OIDC configuration
  github_repo              = var.github_repo
  github_actions_role_name = var.github_actions_role_name
  ecr_repository_arn       = module.ecr.repository_arn
}


module "cloudwatch" {
  source = "./modules/cloudwatch"

  log_group_name    = var.log_group_name
  retention_in_days = var.retention_in_days
  environment       = var.environment
  tags              = var.tags
}

module "ecr" {
  source = "./modules/ecr"

  repository_name = var.ecr_repository_name
  aws_endpoint    = var.aws_endpoint
  tags            = var.tags
}

