# Bedrock DevOps Challenge

A development environment setup using LocalStack for AWS service emulation with Docker Compose.

## Overview

This project provides a containerized development environment that uses LocalStack to emulate AWS services locally. It's designed for testing and development of AWS-based applications without incurring cloud costs.

## Prerequisites

### Install Docker

Choose one of the following options:

**Option 1: Docker Desktop**
- Follow the installation guide: https://docs.docker.com/desktop/

**Option 2: OrbStack (macOS - Recommended)**
- Better resource utilization on macOS
- Installation guide: https://docs.orbstack.dev/install

### Install Terraform

**Installation Guide:** https://developer.hashicorp.com/terraform/install

**macOS (Homebrew):**
```bash
brew tap hashicorp/tap
brew install hashicorp/tap/terraform
```

**Alternative Installation Methods:**
- Direct binary download from HashiCorp releases
- Package managers (apt, yum, etc.) for Linux
- Chocolatey for Windows

### Install AWS CLI

**Installation Guide:** https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html

**macOS:**
```bash
# Option 1: Homebrew
brew install awscli

# Option 2: Official installer
curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
sudo installer -pkg AWSCLIV2.pkg -target /
```

## Getting Started

### Prerequisites

**Verify Required Tools Installation:**
```bash
# Check all required tools are installed
terraform --version  # Should return v1.5+
docker --version     # Should return 20.10+
aws --version        # Should return aws-cli/2.0+
```

**Install LocalStack**

Follow the installation guide:
https://docs.localstack.cloud/aws/getting-started/installation/

### Setup Process

**1. Start LocalStack**

Start LocalStack using Docker Compose:
```bash
docker compose up -d
```

**2. Verify LocalStack Installation**

Validate that LocalStack is running correctly:
```bash
localstack config validate
```

Check LocalStack status:
```bash
localstack status services
```

**For OrbStack users:**
```bash
export LOCALSTACK_HOST=localstack.orb.local
localstack status services
```

**3. Configure AWS CLI**

Configure AWS CLI to use LocalStack:
```bash
aws configure set aws_access_key_id test
aws configure set aws_secret_access_key test
aws configure set region us-east-1
```

Test the configuration:
```bash
# For Docker Desktop users
aws --endpoint-url=http://localhost:4566 s3 ls

# For OrbStack users
aws --endpoint-url=http://localstack.orb.local:4566 s3 ls
```

**4. Initialize and Deploy Infrastructure**

Initialize Terraform:
```bash
cd terraform
terraform init
```

Ensure LocalStack is running, then deploy infrastructure:
```bash
# Make sure LocalStack is running
docker compose up -d

# Plan deployment
terraform plan -var-file="environments/dev/terraform.tfvars"

# Apply changes
terraform apply -var-file="environments/dev/terraform.tfvars"
```

**5. Start Monitoring Stack**

```bash
docker compose -f monitoring/docker-compose.yml up -d
```

### Access Points

- **LocalStack Gateway**: http://localhost:4566
- **Prometheus**: http://localhost:9090
- **Grafana**: http://localhost:3000 (admin/admin)
- **External Services**: Ports 4510-4559 are available for additional services

**Note for OrbStack users**: Use convenient domain names:
- **LocalStack Gateway**: http://localstack.orb.local:4566
- **Or using service name**: http://localstack.bedrock-devops-challenge.orb.local:4566

## API Documentation

The application provides a REST API with the following endpoints:

### Base URL
- **Local Development**: http://localhost:3000

### Endpoints

#### GET `/`
Returns basic application information and available endpoints.

**Response:**
```json
{
  "message": "Bedrock DevOps Challenge Application",
  "version": "1.0.0",
  "endpoints": {
    "health": "/health",
    "metrics": "/metrics", 
    "upload": "POST /upload"
  }
}
```

#### GET `/health`
Health check endpoint that returns application status and uptime.

**Response:**
```json
{
  "uptime": 123.45,
  "message": "OK",
  "timestamp": "2024-01-15T10:30:00.000Z",
  "environment": "development"
}
```

#### GET `/metrics`
Prometheus metrics endpoint exposing application and system metrics.

**Response:** Prometheus format metrics including:
- `http_request_duration_seconds` - HTTP request duration histogram
- `http_requests_total` - Total HTTP request counter
- `file_uploads_total` - File upload counter (success/error)
- `file_upload_size_bytes` - File upload size histogram
- Default Node.js metrics (memory, CPU, etc.)

**Content-Type:** `text/plain; version=0.0.4; charset=utf-8`

#### POST `/upload`
File upload endpoint that stores files in S3-compatible storage.

**Request:**
- **Content-Type:** `multipart/form-data`
- **Body:** Form data with `file` field containing the file to upload
- **File Size Limit:** 50MB

**Example using curl:**
```bash
curl -X POST http://localhost:3000/upload \
  -F "file=@example.txt"
```

**Success Response (200):**
```json
{
  "message": "File uploaded successfully",
  "fileName": "uploads/1642248600000-example.txt",
  "size": 1024,
  "location": "http://localhost:4566/app/uploads/1642248600000-example.txt",
  "etag": "\"d41d8cd98f00b204e9800998ecf8427e\"",
  "uploadedAt": "2024-01-15T10:30:00.000Z"
}
```

**Error Response (400):**
```json
{
  "error": "No file provided"
}
```

**Error Response (500):**
```json
{
  "error": "Upload failed",
  "message": "Detailed error message"
}
```

### Environment Variables

The application uses the following environment variables:

| Variable | Default | Description |
|----------|---------|-------------|
| `PORT` | `3000` | Application port |
| `NODE_ENV` | `development` | Environment (development/staging/production) |
| `AWS_ENDPOINT` | `http://localhost:4566` | AWS/LocalStack endpoint |
| `AWS_REGION` | `us-east-1` | AWS region |
| `AWS_ACCESS_KEY_ID` | `test` | AWS access key |
| `AWS_SECRET_ACCESS_KEY` | `test` | AWS secret key |
| `S3_BUCKET_NAME` | `app` | S3 bucket name for file storage |

### Security Features

- **Helmet.js** for security headers
- **CORS** enabled for cross-origin requests
- **Request size limit** of 50MB for JSON and file uploads
- **Input validation** using Zod schemas
- **Structured logging** with Winston

### Monitoring & Observability

- **Structured JSON logging** to console and S3
- **Prometheus metrics** for monitoring
- **Request tracking** with duration and status codes
- **File upload metrics** with size and success/failure tracking
- **Health checks** for readiness probes

### Example Usage

**Test the application:**
```bash
# Check health
curl http://localhost:3000/health

# View metrics  
curl http://localhost:3000/metrics

# Upload a file
curl -X POST http://localhost:3000/upload -F "file=@test.txt"

# Get application info
curl http://localhost:3000/
```

## Configuration

The Docker Compose setup includes:
- **Container Name**: `localstack`
- **LocalStack Version**: 4.7
- **Debug Mode**: Disabled by default (enable with `DEBUG=1`)
- **Volume Mapping**: Docker named volume `localstack-data` for persistence

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `DEBUG` | `0` | Enable debug mode (set to `1`) |


## Troubleshooting

### Common Issues

**LocalStack not starting:**
- Ensure Docker is running
- Check port 4566 is not in use: `lsof -i :4566` (Docker Desktop) or `curl http://localstack.orb.local:4566` (OrbStack)
- Review logs: `docker compose logs localstack`

**Permission issues:**
- Ensure Docker socket is accessible
- On Linux, add user to docker group: `sudo usermod -aG docker $USER`

**Port conflicts:**
- Modify port mappings in `docker-compose.yml` if needed
- Default ports: 4566 (gateway), 4510-4559 (services)

**Terraform State Lock**
```bash
# Force unlock if needed
terraform force-unlock <LOCK_ID>
```

**LocalStack Connection Issues**
```bash
# Check LocalStack status
localstack status services

# Restart LocalStack
docker compose restart localstack
```

**Monitoring Data Missing**
```bash
# Check Prometheus targets
curl http://localhost:9090/api/v1/targets

# Verify application metrics
curl http://localhost:3000/metrics
```

### Useful Commands

```bash
# View logs
docker compose logs -f localstack

# Restart services
docker compose restart

# Stop services
docker compose down

# Remove volumes (clean reset)
docker compose down -v
```

### Debugging Steps

1. **Check Application Logs**
   ```bash
   docker compose logs -f app
   ```

2. **Verify Infrastructure**
   ```bash
   terraform show
   terraform state list
   ```

3. **Monitor Resource Usage**
   ```bash
   docker stats
   ```

## Infrastructure Documentation

### Architecture Overview

This project implements a complete DevOps infrastructure with:

- **LocalStack**: AWS service emulation for local development
- **Terraform**: Infrastructure as Code for AWS resources
- **Docker Compose**: Container orchestration
- **Monitoring Stack**: Prometheus, Grafana, and CloudWatch integration
- **Application**: Sample Node.js application with health checks

### Terraform Infrastructure

The infrastructure is organized into reusable modules:

#### Core Modules

**S3 Module** (`terraform/modules/s3/`)
- Creates S3 buckets for application storage
- Configures versioning and lifecycle policies
- Implements proper IAM permissions

**IAM Module** (`terraform/modules/iam/`)
- Defines service roles and policies
- Implements least privilege access
- Creates application-specific permissions

**CloudWatch Module** (`terraform/modules/cloudwatch/`)
- Sets up log groups and metric filters
- Configures alarms and dashboards
- Integrates with application monitoring

**Prometheus Module** (`terraform/modules/prometheus/`)
- Deploys Prometheus server
- Configures service discovery
- Sets up metric collection rules

#### Environment Configuration

Three environments are configured:
- **Development**: `terraform/environments/dev/`
- **Staging**: `terraform/environments/staging/`
- **Production**: `terraform/environments/prod/`

Each environment has specific resource sizing and configuration.

### Application Structure

The sample Node.js application (`application/`) includes:
- Health check endpoints (`/health`, `/ready`)
- Metrics exposition (`/metrics`)
- Structured logging
- Graceful shutdown handling

### Monitoring & Observability

#### Metrics Collection

The application exposes metrics at `/metrics` endpoint:
- HTTP request duration and count
- Application health status
- Custom business metrics

#### Prometheus Configuration

Located in `monitoring/prometheus/`:
- Service discovery for dynamic targets
- Alerting rules for critical metrics
- Data retention and storage configuration

#### Grafana Dashboards

Pre-configured dashboards for:
- Application performance metrics
- Infrastructure monitoring
- Alert management

#### Custom Prometheus Exporters

**S3 Metrics Generator** (`monitoring/s3-metrics-generator/`)

A custom Prometheus exporter that provides S3 storage metrics for the application:

**Features:**
- **Real-time S3 metrics**: Connects to LocalStack S3 to collect actual bucket metrics
- **Prometheus format**: Exposes metrics at `/metrics` endpoint (port 9107)
- **Comprehensive metrics**:
  - `aws_s3_bucket_size_bytes_average` - Current bucket size in bytes
  - `aws_s3_number_of_objects_average` - Number of objects in bucket
  - `aws_s3_bytes_uploaded_sum` - Total bytes uploaded (simulated)
  - `aws_s3_bytes_downloaded_sum` - Total bytes downloaded (simulated)
  - `aws_s3_all_requests_sum` - Total S3 requests (simulated)

**Configuration:**
- Automatically discovers S3 bucket contents via LocalStack API
- Configurable via environment variables:
  - `AWS_ENDPOINT`: S3 endpoint (default: `http://localstack:4566`)
  - `S3_BUCKET_NAME`: Target bucket name (default: `app`)
  - `AWS_REGION`: AWS region (default: `us-east-1`)

**Health Monitoring:**
- Health check endpoint at `/health`
- Docker health checks configured with 30-second intervals
- Graceful error handling for S3 connectivity issues

**Usage:**
```bash
# Start the S3 metrics generator
docker compose -f monitoring/docker-compose.yml up -d s3-metrics-generator

# View metrics
curl http://localhost:9107/metrics

# Check health
curl http://localhost:9107/health
```

The S3 metrics generator integrates seamlessly with Prometheus and provides visibility into storage utilization, helping monitor application data growth and S3 usage patterns in the development environment.

## CI/CD Pipeline

This project includes a comprehensive GitHub Actions CI/CD pipeline that supports both local testing with LocalStack and production deployment to AWS ECR.

### Pipeline Overview

The CI/CD pipeline consists of three main jobs:

1. **`lint-and-test`** - Code quality and testing
2. **`build-and-push`** - Docker image building and deployment
3. **`security-scan`** - Security vulnerability scanning

### Pipeline Jobs

#### 1. Lint and Test Job

**Triggers:** All pushes and pull requests
- Sets up Node.js 22 environment
- Installs dependencies with `npm ci --include=dev`
- Runs ESLint for code quality checks
- Executes test suite with `npm test`

#### 2. Build and Push Job

**Dual Mode Operation:**

**LocalStack Mode** (`USE_LOCALSTACK: 'true'`):
- Builds Docker images locally for testing
- Creates images tagged with Git SHA and `latest`
- No AWS authentication or pushing required
- Perfect for CI simulation and local development

**Production Mode** (`USE_LOCALSTACK: 'false'`):
- Uses OIDC role assumption for secure AWS authentication
- Logs into Amazon ECR registry
- Builds, tags, and pushes images to production ECR
- Performs vulnerability scanning on pushed images

**Environment Variables:**
```yaml
AWS_REGION: us-east-1
USE_LOCALSTACK: 'true'  # Set to 'false' for production
ECR_REPOSITORY_NAME: ${{ vars.ECR_REPOSITORY_NAME || 'bedrock-devops-app' }}
AWS_ROLE_ARN: ${{ secrets.AWS_ROLE_ARN }}  # For production only
```

#### 3. Security Scan Job

**Security Scanning Features:**
- **npm audit** - Checks for known vulnerabilities in dependencies
- **Trivy scanner** - Comprehensive vulnerability scanning
- **SARIF output** - Security results in standard format

**Dual Output Mode:**
- **GitHub Remote**: Uploads SARIF results to GitHub Security tab
- **Local Testing**: Displays scan results in terminal using `jq`

### Configuration

#### For Local Testing

The pipeline is pre-configured for local testing with `act`:

```bash
# Run the entire pipeline locally
act --env-file .env

# Run specific jobs
act -j lint-and-test --env-file .env
act -j build-and-push --env-file .env
act -j security-scan --env-file .env
```

#### For Production Deployment

1. **Set GitHub Repository Variables:**
   - Navigate to Settings → Secrets and variables → Actions → Variables
   - Add: `ECR_REPOSITORY_NAME` = `bedrock-devops-app`

2. **Set GitHub Repository Secrets:**
   - Navigate to Settings → Secrets and variables → Actions → Secrets  
   - Add: `AWS_ROLE_ARN` = `arn:aws:iam::YOUR_ACCOUNT:role/github-actions-ecr-prod`

3. **Update Pipeline Configuration:**
   ```yaml
   USE_LOCALSTACK: 'false'  # Enable production mode
   ```

### Infrastructure as Code Integration

The pipeline works seamlessly with the Terraform infrastructure:

**ECR Repository Creation:**
- Created via Terraform ECR module (`terraform/modules/ecr/`)
- Repository names match between Terraform and GitHub Actions
- Supports environment-specific repositories (dev, staging, prod)

**IAM Role for GitHub Actions:**
- Created via Terraform (`terraform/modules/github-actions/`)
- Uses OIDC for secure, keyless authentication
- Scoped to specific GitHub repository with least-privilege access

**Example Terraform Output:**
```bash
# After terraform apply
terraform output github_actions_role_arn
# Output: arn:aws:iam::123456789:role/github-actions-ecr-prod
```

### Security Features

#### Authentication Methods
- **Local/Testing**: Simple test credentials for LocalStack
- **Production**: OIDC role assumption (no long-lived keys)

#### Access Control
- Repository-scoped GitHub OIDC trust policy
- Least-privilege ECR permissions (push, scan, auth only)
- Environment-specific IAM roles

#### Vulnerability Management
- Automated dependency scanning with `npm audit`
- Container image scanning with Trivy
- SARIF integration with GitHub Security tab
- Continuous monitoring of security findings

### Pipeline Triggers

```yaml
on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]
```

- **Push to main/develop**: Full pipeline execution
- **Pull requests to main**: Full pipeline for validation
- **Manual trigger**: Available via GitHub Actions UI

### Example Usage

**Local Development Workflow:**
```bash
# 1. Make changes to application
git add .
git commit -m "Add new feature"

# 2. Test pipeline locally
act --env-file .env

# 3. Push when ready
git push origin feature-branch
```

**Production Deployment:**
```bash
# 1. Update pipeline for production
# Set USE_LOCALSTACK: 'false' in workflow

# 2. Ensure AWS infrastructure is deployed
cd terraform
terraform apply -var-file="environments/prod/terraform.tfvars"

# 3. Deploy via GitHub
git push origin main
```

### Monitoring and Observability

The pipeline provides comprehensive visibility:
- **GitHub Actions UI**: Real-time job progress and logs
- **GitHub Security Tab**: Vulnerability scan results
- **ECR Console**: Container image repository and scan results
- **CloudWatch**: AWS resource utilization and metrics

### Security

1. **Network Security (Docker Network Isolation)**
   - Custom isolated Docker networks separate components from default bridge
   - Subnet isolation with CIDR block configuration
   - Service discovery within secure network boundaries
   - Health checks ensure only healthy services communicate
   
   **Implementation from `docker-compose.yml`:**
   ```yaml
   networks:
     bedrock-network:
       driver: bridge
       ipam:
         config:
           - subnet: 172.20.0.0/16
   
   services:
     app:
       networks:
         - bedrock-network
     prometheus:
       networks:
         - bedrock-network  # Same network for metrics scraping
     grafana:
       networks:
         - bedrock-network  # Access to Prometheus data source
   ```

2. **Credential Management**
   - Environment variables sourced from `.env` files (git-ignored)
   - No hardcoded secrets in configuration files
   - LocalStack test credentials for development environment
   - Separate credential management per environment
   
   **Implementation from `.env`:**
   ```bash
   # AWS Configuration
   AWS_REGION=us-east-1
   AWS_ACCESS_KEY_ID=test
   AWS_SECRET_ACCESS_KEY=test
   AWS_ENDPOINT=http://localstack.orb.local:4566
   
   # S3 Configuration - matches Terraform bucket name
   S3_BUCKET_NAME=app
   
   # Slack Webhook for Grafana Alerts
   SLACK_WEBHOOK_URL=https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK
   ```

3. **Resource Access Control (IAM Least Privilege)**
   - Specific IAM policies with minimal required permissions
   - Resource-based access control with ARN restrictions
   - Conditional access using prefix-based S3 permissions
   - Separate roles for different service components
   
   **Implementation from `terraform/modules/iam/main.tf`:**
   ```hcl
   resource "aws_iam_policy" "s3_access_policy" {
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
             "s3:ListBucket"
           ]
           Resource = [
             var.bucket_arn,
             "${var.bucket_arn}/*"
           ]
         },
         {
           Sid    = "S3PrefixedAccess"
           Effect = "Allow"
           Action = ["s3:ListBucket"]
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
   }
   ```
   ```

## Backup and Restore

This project includes automated backup and restore scripts for critical data components.

### Data Components

The backup/restore system handles:
- **S3 Data (LocalStack)**: Uploaded files and application logs
- **Prometheus Data**: Time-series metrics and monitoring data (15-day retention)
- **Grafana Data**: Dashboards, data sources, and configuration

### Backup Script

The backup script (`scripts/backup.sh`) creates timestamped backups of all data components:

```bash
# Create a backup
./scripts/backup.sh
```

**What it does:**
1. **Validates prerequisites**: Checks LocalStack and container availability
2. **S3 Data Backup**: Uses AWS CLI to sync all objects from the S3 bucket to local files
3. **Prometheus Backup**: Creates tar.gz archive of the `prometheus-data` Docker volume
4. **Grafana Backup**: Creates tar.gz archive of the `grafana-data` Docker volume
5. **Creates summary**: Generates backup metadata and size information

**Output Structure:**
```
backups/backup_YYYYMMDD_HHMMSS/
├── s3/                     # S3 bucket contents
│   ├── uploads/           # User uploaded files
│   ├── logs/              # Application logs
│   └── backup_info.txt    # S3 backup metadata
├── prometheus/
│   ├── prometheus-data.tar.gz  # Compressed volume data
│   └── backup_info.txt         # Prometheus backup metadata
├── grafana/
│   ├── grafana-data.tar.gz     # Compressed volume data
│   └── backup_info.txt         # Grafana backup metadata
└── backup_summary.txt          # Overall backup summary
```

### Restore Script

The restore script (`scripts/restore.sh`) restores data from backups with validation:

```bash
# List available backups
./scripts/restore.sh

# Restore from specific backup
./scripts/restore.sh backup_20240101_120000
```

**What it does:**
1. **Lists available backups** when run without arguments
2. **Validates backup** structure and components before restore
3. **Confirms operation** with user (destructive operation warning)
4. **S3 Data Restore**: Clears existing bucket and restores files from backup
5. **Volume Restore**: Stops containers, clears volumes, and restores from archives
6. **Post-restore guidance**: Provides instructions for restarting services

**Safety Features:**
- Interactive confirmation before destructive operations
- Backup validation before proceeding
- Graceful handling of missing backup components
- Clear status reporting throughout the process

### Usage Examples

**Daily Backup Workflow:**
```bash
# Start services
docker compose up -d

# Wait for services to be ready
sleep 30

# Create backup
./scripts/backup.sh

# Backup created at: backups/backup_20240315_143000/
```

**Disaster Recovery Workflow:**
```bash
# List available backups
./scripts/restore.sh

# Restore from latest backup
./scripts/restore.sh backup_20240315_143000

# Restart services after restore
docker compose restart prometheus grafana
```

**Backup Validation:**
```bash
# Check backup contents
ls -la backups/backup_20240315_143000/
cat backups/backup_20240315_143000/backup_summary.txt
```

### Prerequisites

**Required Tools:**
- AWS CLI (`aws`)
- Docker with volume access
- curl (for LocalStack health checks)

**Required Services:**
- LocalStack running on port 4566
- Docker volumes: `prometheus-data`, `grafana-data`

**Permissions:**
- Docker socket access for volume operations
- Read/write access to backup directory
- Network access to LocalStack endpoint

### Configuration

Both scripts use these configurable variables:

```bash
# Backup/Restore Configuration
BACKUP_DIR="./backups"              # Local backup storage location
AWS_ENDPOINT="http://localhost:4566" # LocalStack endpoint
AWS_REGION="us-east-1"              # AWS region
S3_BUCKET_NAME="app"                # S3 bucket name
```

**Environment Variables:**
The scripts can be customized using environment variables:
```bash
# Custom backup location
export BACKUP_DIR="/path/to/backups"

# Custom LocalStack endpoint
export AWS_ENDPOINT="http://localstack.orb.local:4566"

# Run backup
./scripts/backup.sh
```

### Monitoring and Logs

Both scripts provide comprehensive logging with:
- **Colored output**: Green for success, yellow for warnings, red for errors
- **Timestamps**: All log messages include timestamp
- **Progress tracking**: Clear indication of current operation
- **Error handling**: Immediate exit on critical errors with descriptive messages

### Troubleshooting

**Common Issues:**

1. **"LocalStack not accessible"**
   ```bash
   # Check LocalStack status
   curl http://localhost:4566/_localstack/health
   docker compose ps localstack
   ```

2. **"Docker volume not found"**
   ```bash
   # List existing volumes
   docker volume ls
   # Recreate missing volumes
   docker compose up -d
   ```

3. **"Permission denied"**
   ```bash
   # Ensure scripts are executable
   chmod +x scripts/backup.sh scripts/restore.sh
   ```

4. **"AWS CLI not found"**
   ```bash
   # Install AWS CLI
   # macOS: brew install awscli
   # Ubuntu: apt install awscli
   aws --version
   ```

5. **"Backup directory permissions"**
   ```bash
   # Ensure backup directory is writable
   mkdir -p backups
   chmod 755 backups
   ```

## Resources

- [LocalStack Documentation](https://docs.localstack.cloud/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [AWS CLI Configuration](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html)
- [Terraform Best Practices](https://www.terraform-best-practices.com/)
- [Prometheus Configuration](https://prometheus.io/docs/prometheus/latest/configuration/configuration/)
- [Grafana Dashboard Guide](https://grafana.com/docs/grafana/latest/dashboards/)
