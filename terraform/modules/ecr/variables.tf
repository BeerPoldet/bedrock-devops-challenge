variable "repository_name" {
  description = "Name of the ECR repository"
  type        = string
}

variable "tags" {
  description = "Tags to apply to the ECR repository"
  type        = map(string)
  default     = {}
}

variable "aws_endpoint" {
  description = "AWS endpoint URL (if using LocalStack, ECR will be skipped)"
  type        = string
  default     = ""
}