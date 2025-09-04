#!/bin/bash

# Backup script for Bedrock DevOps Challenge
# Backs up S3 data, Prometheus metrics, and Grafana configuration

set -e # Exit on any error

# Configuration
BACKUP_DIR="./backups"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_NAME="backup_${TIMESTAMP}"

# AWS/LocalStack configuration
AWS_ENDPOINT="http://localhost:4566"
AWS_REGION="us-east-1"
AWS_ACCESS_KEY_ID="test"
AWS_SECRET_ACCESS_KEY="test"
S3_BUCKET_NAME="app"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() {
  echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
  echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

error() {
  echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
  exit 1
}

# Create backup directory
create_backup_dir() {
  log "Creating backup directory: ${BACKUP_DIR}/${BACKUP_NAME}"
  mkdir -p "${BACKUP_DIR}/${BACKUP_NAME}"
}

# Check if LocalStack is running
check_localstack() {
  log "Checking LocalStack availability..."
  if ! curl -sf "${AWS_ENDPOINT}/_localstack/health" >/dev/null 2>&1; then
    error "LocalStack is not running or not accessible at ${AWS_ENDPOINT}"
  fi
  log "LocalStack is running"
}

# Check if Docker containers are running
check_containers() {
  log "Checking if required containers are running..."

  if ! docker ps --filter "name=prometheus" --filter "status=running" | grep -q prometheus; then
    warn "Prometheus container is not running"
  fi

  if ! docker ps --filter "name=grafana" --filter "status=running" | grep -q grafana; then
    warn "Grafana container is not running"
  fi
}

# Backup S3 data from LocalStack
backup_s3() {
  log "Starting S3 data backup..."

  local s3_backup_dir="${BACKUP_DIR}/${BACKUP_NAME}/s3"
  mkdir -p "${s3_backup_dir}"

  # Set AWS CLI environment for LocalStack
  export AWS_ENDPOINT_URL="${AWS_ENDPOINT}"
  export AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID}"
  export AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY}"
  export AWS_DEFAULT_REGION="${AWS_REGION}"

  # Check if bucket exists
  if aws s3api head-bucket --bucket "${S3_BUCKET_NAME}" --endpoint-url "${AWS_ENDPOINT}" 2>/dev/null; then
    log "Backing up S3 bucket: ${S3_BUCKET_NAME}"

    # Sync all objects from the bucket
    aws s3 sync "s3://${S3_BUCKET_NAME}" "${s3_backup_dir}" --endpoint-url "${AWS_ENDPOINT}"

    # Create metadata file
    echo "Bucket: ${S3_BUCKET_NAME}" >"${s3_backup_dir}/backup_info.txt"
    echo "Backup Date: $(date)" >>"${s3_backup_dir}/backup_info.txt"
    echo "AWS Endpoint: ${AWS_ENDPOINT}" >>"${s3_backup_dir}/backup_info.txt"

    log "S3 backup completed successfully"
  else
    warn "S3 bucket '${S3_BUCKET_NAME}' not found or not accessible"
    echo "S3 bucket not found" >"${s3_backup_dir}/backup_info.txt"
  fi
}

# Backup Prometheus data
backup_prometheus() {
  log "Starting Prometheus data backup..."

  local prom_backup_dir="${BACKUP_DIR}/${BACKUP_NAME}/prometheus"
  mkdir -p "${prom_backup_dir}"

  # Create tar archive of prometheus data volume
  if docker volume inspect bedrock-devops-challenge_prometheus-data >/dev/null 2>&1; then
    log "Backing up Prometheus volume..."
    docker run --rm \
      -v bedrock-devops-challenge_prometheus-data:/source:ro \
      -v "$(pwd)/${prom_backup_dir}":/backup \
      alpine:latest \
      tar czf /backup/prometheus-data.tar.gz -C /source .

    # Create metadata file
    echo "Volume: bedrock-devops-challenge_prometheus-data" >"${prom_backup_dir}/backup_info.txt"
    echo "Backup Date: $(date)" >>"${prom_backup_dir}/backup_info.txt"

    log "Prometheus backup completed successfully"
  else
    warn "Prometheus volume 'bedrock-devops-challenge_prometheus-data' not found"
    echo "Volume not found" >"${prom_backup_dir}/backup_info.txt"
  fi
}

# Backup Grafana data
backup_grafana() {
  log "Starting Grafana data backup..."

  local grafana_backup_dir="${BACKUP_DIR}/${BACKUP_NAME}/grafana"
  mkdir -p "${grafana_backup_dir}"

  # Create tar archive of grafana data volume
  if docker volume inspect bedrock-devops-challenge_grafana-data >/dev/null 2>&1; then
    log "Backing up Grafana volume..."
    docker run --rm \
      -v bedrock-devops-challenge_grafana-data:/source:ro \
      -v "$(pwd)/${grafana_backup_dir}":/backup \
      alpine:latest \
      tar czf /backup/grafana-data.tar.gz -C /source .

    # Create metadata file
    echo "Volume: bedrock-devops-challenge_grafana-data" >"${grafana_backup_dir}/backup_info.txt"
    echo "Backup Date: $(date)" >>"${grafana_backup_dir}/backup_info.txt"

    log "Grafana backup completed successfully"
  else
    warn "Grafana volume 'bedrock-devops-challenge_grafana-data' not found"
    echo "Volume not found" >"${grafana_backup_dir}/backup_info.txt"
  fi
}

# Create backup summary
create_summary() {
  local summary_file="${BACKUP_DIR}/${BACKUP_NAME}/backup_summary.txt"

  log "Creating backup summary..."

  cat >"${summary_file}" <<EOF
Bedrock DevOps Challenge - Backup Summary
=========================================

Backup Name: ${BACKUP_NAME}
Backup Date: $(date)
Backup Location: ${BACKUP_DIR}/${BACKUP_NAME}

Components Backed Up:
- S3 Data (LocalStack): $([ -f "${BACKUP_DIR}/${BACKUP_NAME}/s3/backup_info.txt" ] && echo "✓ Success" || echo "✗ Failed")
- Prometheus Data: $([ -f "${BACKUP_DIR}/${BACKUP_NAME}/prometheus/prometheus-data.tar.gz" ] && echo "✓ Success" || echo "✗ Failed")
- Grafana Data: $([ -f "${BACKUP_DIR}/${BACKUP_NAME}/grafana/grafana-data.tar.gz" ] && echo "✓ Success" || echo "✗ Failed")

Backup Size: $(du -sh "${BACKUP_DIR}/${BACKUP_NAME}" | cut -f1)
EOF

  log "Backup summary created: ${summary_file}"
}

# Main backup function
main() {
  log "Starting Bedrock DevOps Challenge backup..."
  log "Backup timestamp: ${TIMESTAMP}"

  create_backup_dir
  check_localstack
  check_containers

  backup_s3
  backup_prometheus
  backup_grafana

  create_summary

  log "Backup completed successfully!"
  log "Backup location: ${BACKUP_DIR}/${BACKUP_NAME}"
  log "To restore this backup, run: ./scripts/restore.sh ${BACKUP_NAME}"
}

# Run main function
main "$@"

