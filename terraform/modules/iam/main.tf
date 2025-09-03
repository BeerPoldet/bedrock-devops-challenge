data "aws_iam_policy_document" "app_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    principals {
      identifiers = [var.oidc_provider_arn]
      type        = "Federated"
    }

    condition {
      test     = "StringEquals"
      variable = "${var.oidc_provider_url}:sub"
      values   = ["system:serviceaccount:${var.app_namespace}:${var.app_service_account_name}"]
    }

    condition {
      test     = "StringEquals"
      variable = "${var.oidc_provider_url}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "app_role" {
  name               = "${var.cluster_name}-app-${var.environment}-role"
  assume_role_policy = data.aws_iam_policy_document.app_assume_role_policy.json

  tags = merge(var.tags, {
    Name        = "${var.cluster_name}-app-${var.environment}-role"
    Environment = var.environment
    Purpose     = "EKS IRSA for Application"
  })
}

resource "aws_iam_policy" "s3_access_policy" {
  name        = "${var.cluster_name}-app-${var.environment}-s3-policy"
  description = "IAM policy for application service account to access S3"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3BucketAccess"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket",
          "s3:GetObjectVersion"
        ]
        Resource = [
          var.bucket_arn,
          "${var.bucket_arn}/*"
        ]
      },
      {
        Sid    = "S3PrefixedAccess"
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = var.bucket_arn
        Condition = {
          StringLike = {
            "s3:prefix" = [
              "logs/*",
              "uploads/*"
            ]
          }
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Environment = var.environment
    Purpose     = "EKS IRSA for Application S3 Access"
  })
}

resource "aws_iam_role_policy_attachment" "s3_access_attachment" {
  role       = aws_iam_role.app_role.name
  policy_arn = aws_iam_policy.s3_access_policy.arn
}

data "aws_iam_policy_document" "prometheus_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    principals {
      identifiers = [var.oidc_provider_arn]
      type        = "Federated"
    }

    condition {
      test     = "StringEquals"
      variable = "${var.oidc_provider_url}:sub"
      values   = ["system:serviceaccount:${var.prometheus_namespace}:${var.prometheus_service_account_name}"]
    }

    condition {
      test     = "StringEquals"
      variable = "${var.oidc_provider_url}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "prometheus_role" {
  name               = "${var.cluster_name}-prometheus-${var.environment}-role"
  assume_role_policy = data.aws_iam_policy_document.prometheus_assume_role_policy.json

  tags = merge(var.tags, {
    Name        = "${var.cluster_name}-prometheus-${var.environment}-role"
    Environment = var.environment
    Purpose     = "EKS IRSA for Prometheus"
  })
}

resource "aws_iam_policy" "prometheus_policy" {
  name        = "${var.cluster_name}-prometheus-${var.environment}-policy"
  description = "IAM policy for Prometheus service account in EKS"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "CloudWatchMetricsAccess"
        Effect = "Allow"
        Action = [
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:GetMetricData",
          "cloudwatch:ListMetrics",
          "cloudwatch:GetDashboard",
          "cloudwatch:ListDashboards"
        ]
        Resource = "*"
      },
      {
        Sid    = "CloudWatchLogsAccess"
        Effect = "Allow"
        Action = [
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:GetLogEvents",
          "logs:FilterLogEvents",
          "logs:DescribeQueries",
          "logs:GetLogGroupFields"
        ]
        Resource = "*"
      },
      {
        Sid    = "EC2MetricsAccess"
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeRegions",
          "ec2:DescribeAvailabilityZones",
          "ec2:DescribeTags"
        ]
        Resource = "*"
      },
      {
        Sid    = "EKSMetricsAccess"
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster",
          "eks:ListClusters",
          "eks:DescribeNodegroup",
          "eks:ListNodegroups"
        ]
        Resource = "*"
      },
      {
        Sid    = "S3MetricsAccess"
        Effect = "Allow"
        Action = [
          "s3:GetBucketLocation",
          "s3:GetBucketMetricsConfiguration",
          "s3:ListAllMyBuckets"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(var.tags, {
    Environment = var.environment
    Purpose     = "EKS IRSA for Prometheus"
  })
}

resource "aws_iam_role_policy_attachment" "prometheus_policy_attachment" {
  role       = aws_iam_role.prometheus_role.name
  policy_arn = aws_iam_policy.prometheus_policy.arn
}

# GitHub OIDC Provider
resource "aws_iam_openid_connect_provider" "github" {
  count = var.github_repo != "" ? 1 : 0
  url   = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com",
  ]

  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c58a3a8518e8759bf075b76b750d4f2df264fcd"
  ]

  tags = var.tags
}

# IAM Role for GitHub Actions
resource "aws_iam_role" "github_actions" {
  count = var.github_repo != "" ? 1 : 0
  name  = var.github_actions_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github[0].arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_repo}:*"
          }
        }
      }
    ]
  })

  tags = var.tags
}

# IAM Policy for ECR operations
resource "aws_iam_policy" "ecr_push" {
  count       = var.github_repo != "" ? 1 : 0
  name        = "${var.github_actions_role_name}-ecr-push"
  description = "Allow GitHub Actions to push images to ECR"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:DescribeRepositories",
          "ecr:DescribeImages",
          "ecr:BatchImportImage",
          "ecr:GetAuthorizationToken"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage",
          "ecr:StartImageScan"
        ]
        Resource = var.ecr_repository_arn != "" ? var.ecr_repository_arn : "*"
      }
    ]
  })

  tags = var.tags
}

# Attach the ECR policy to the role
resource "aws_iam_role_policy_attachment" "github_actions_ecr" {
  count      = var.github_repo != "" ? 1 : 0
  role       = aws_iam_role.github_actions[0].name
  policy_arn = aws_iam_policy.ecr_push[0].arn
}
