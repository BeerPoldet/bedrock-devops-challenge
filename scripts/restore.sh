#!/bin/bash

# Restore script for Bedrock DevOps Challenge
# Restores S3 data, Prometheus metrics, and Grafana configuration from backup

set -e # Exit on any error

# Configuration
BACKUP_DIR="./backups"

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
BLUE='\033[0;34m'
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

info() {
  echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $1${NC}"
}

# Show usage
usage() {
  echo "Usage: $0 [BACKUP_NAME]"
  echo ""
  echo "Restores S3 data, Prometheus metrics, and Grafana configuration from backup"
  echo ""
  echo "Arguments:"
  echo "  BACKUP_NAME    Name of the backup to restore (e.g., backup_20240101_120000)"
  echo "                 If not provided, will list available backups"
  echo ""
  echo "Examples:"
  echo "  $0                           # List available backups"
  echo "  $0 backup_20240101_120000    # Restore specific backup"
}

# List available backups
list_backups() {
  log "Available backups in ${BACKUP_DIR}:"

  if [ ! -d "${BACKUP_DIR}" ]; then
    warn "Backup directory not found: ${BACKUP_DIR}"
    return 1
  fi

  local count=0
  for backup in "${BACKUP_DIR}"/backup_*; do
    if [ -d "${backup}" ]; then
      local backup_name=$(basename "${backup}")
      local backup_date=""

      # Try to extract date from backup summary
      if [ -f "${backup}/backup_summary.txt" ]; then
        backup_date=$(grep "Backup Date:" "${backup}/backup_summary.txt" | cut -d' ' -f3-)
      fi

      echo "  - ${backup_name} ${backup_date:+($backup_date)}"
      count=$((count + 1))
    fi
  done

  if [ $count -eq 0 ]; then
    warn "No backups found in ${BACKUP_DIR}"
    return 1
  fi

  echo ""
  info "To restore a backup, run: $0 <BACKUP_NAME>"
}

# Validate backup exists and structure
validate_backup() {
  local backup_name="$1"
  local backup_path="${BACKUP_DIR}/${backup_name}"

  log "Validating backup: ${backup_name}"

  if [ ! -d "${backup_path}" ]; then
    error "Backup directory not found: ${backup_path}"
  fi

  # Check for backup components
  local s3_dir="${backup_path}/s3"
  local prom_dir="${backup_path}/prometheus"
  local grafana_dir="${backup_path}/grafana"

  if [ ! -d "${s3_dir}" ]; then
    warn "S3 backup directory not found: ${s3_dir}"
  fi

  if [ ! -d "${prom_dir}" ]; then
    warn "Prometheus backup directory not found: ${prom_dir}"
  fi

  if [ ! -d "${grafana_dir}" ]; then
    warn "Grafana backup directory not found: ${grafana_dir}"
  fi

  log "Backup validation completed"
}

# Check if LocalStack is running
check_localstack() {
  log "Checking LocalStack availability..."
  if ! curl -sf "${AWS_ENDPOINT}/_localstack/health" >/dev/null 2>&1; then
    error "LocalStack is not running or not accessible at ${AWS_ENDPOINT}. Please start the services first."
  fi
  log "LocalStack is running"
}

# Confirm restore operation
confirm_restore() {
  local backup_name="$1"

  echo ""
  warn "IMPORTANT: This will overwrite existing data!"
  echo "  - S3 bucket '${S3_BUCKET_NAME}' will be cleared and restored"
  echo "  - Prometheus data volume will be replaced"
  echo "  - Grafana data volume will be replaced"
  echo ""

  read -p "Are you sure you want to restore from '${backup_name}'? (y/N): " -r
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    info "Restore cancelled by user"
    exit 0
  fi
}

# Restore S3 data to LocalStack
restore_s3() {
  local backup_name="$1"
  local s3_backup_dir="${BACKUP_DIR}/${backup_name}/s3"

  if [ ! -d "${s3_backup_dir}" ]; then
    warn "S3 backup directory not found, skipping S3 restore"
    return
  fi

  log "Starting S3 data restore..."

  # Set AWS CLI environment for LocalStack
  export AWS_ENDPOINT_URL="${AWS_ENDPOINT}"
  export AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID}"
  export AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY}"
  export AWS_DEFAULT_REGION="${AWS_REGION}"

  # Create bucket if it doesn't exist
  if ! aws s3api head-bucket --bucket "${S3_BUCKET_NAME}" --endpoint-url "${AWS_ENDPOINT}" 2>/dev/null; then
    log "Creating S3 bucket: ${S3_BUCKET_NAME}"
    aws s3api create-bucket --bucket "${S3_BUCKET_NAME}" --endpoint-url "${AWS_ENDPOINT}"
  fi

  # Clear existing bucket contents
  log "Clearing existing S3 bucket contents..."
  aws s3 rm "s3://${S3_BUCKET_NAME}" --recursive --endpoint-url "${AWS_ENDPOINT}" || true

  # Restore files (exclude backup_info.txt)
  if [ "$(ls -A "${s3_backup_dir}" 2>/dev/null | grep -v backup_info.txt || true)" ]; then
    log "Restoring S3 data from backup..."
    aws s3 sync "${s3_backup_dir}" "s3://${S3_BUCKET_NAME}" --endpoint-url "${AWS_ENDPOINT}" --exclude "backup_info.txt"
  else
    info "No S3 files to restore (backup was empty)"
  fi

  log "S3 restore completed successfully"
}

# Restore Prometheus data
restore_prometheus() {
  local backup_name="$1"
  local prom_backup_dir="${BACKUP_DIR}/${backup_name}/prometheus"
  local prom_archive="${prom_backup_dir}/prometheus-data.tar.gz"

  if [ ! -f "${prom_archive}" ]; then
    warn "Prometheus backup archive not found, skipping Prometheus restore"
    return
  fi

  log "Starting Prometheus data restore..."

  # Stop Prometheus container if running
  if docker ps --filter "name=prometheus" --filter "status=running" | grep -q prometheus; then
    log "Stopping Prometheus container..."
    docker stop prometheus || true
  fi

  # Remove existing volume data
  log "Clearing existing Prometheus data..."
  docker run --rm \
    -v bedrock-devops-challenge_prometheus-data:/data \
    alpine:latest \
    sh -c "rm -rf /data/* /data/..?* /data/.[!.]*" 2>/dev/null || true

  # Restore data from archive
  log "Restoring Prometheus data from backup..."
  docker run --rm \
    -v bedrock-devops-challenge_prometheus-data:/data \
    -v "$(pwd)/${prom_backup_dir}":/backup \
    alpine:latest \
    tar xzf /backup/prometheus-data.tar.gz -C /data

  log "Prometheus restore completed successfully"
  info "Please restart the Prometheus container to use restored data"
}

# Restore Grafana data
restore_grafana() {
  local backup_name="$1"
  local grafana_backup_dir="${BACKUP_DIR}/${backup_name}/grafana"
  local grafana_archive="${grafana_backup_dir}/grafana-data.tar.gz"

  if [ ! -f "${grafana_archive}" ]; then
    warn "Grafana backup archive not found, skipping Grafana restore"
    return
  fi

  log "Starting Grafana data restore..."

  # Stop Grafana container if running
  if docker ps --filter "name=grafana" --filter "status=running" | grep -q grafana; then
    log "Stopping Grafana container..."
    docker stop grafana || true
  fi

  # Remove existing volume data
  log "Clearing existing Grafana data..."
  docker run --rm \
    -v bedrock-devops-challenge_grafana-data:/data \
    alpine:latest \
    sh -c "rm -rf /data/* /data/..?* /data/.[!.]*" 2>/dev/null || true

  # Restore data from archive
  log "Restoring Grafana data from backup..."
  docker run --rm \
    -v bedrock-devops-challenge_grafana-data:/data \
    -v "$(pwd)/${grafana_backup_dir}":/backup \
    alpine:latest \
    tar xzf /backup/grafana-data.tar.gz -C /data

  log "Grafana restore completed successfully"
  info "Please restart the Grafana container to use restored data"
}

# Show restore summary
show_summary() {
  local backup_name="$1"
  local summary_file="${BACKUP_DIR}/${backup_name}/backup_summary.txt"

  echo ""
  log "Restore Summary:"

  if [ -f "${summary_file}" ]; then
    cat "${summary_file}"
  else
    echo "Restored from backup: ${backup_name}"
    echo "Restore date: $(date)"
  fi

  echo ""
  info "Restore completed! You may need to restart the Docker services:"
  info "  docker compose restart prometheus grafana"
}

# Main restore function
main() {
  local backup_name="$1"

  # Show usage if no arguments or help requested
  if [ $# -eq 0 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    if [ $# -eq 0 ]; then
      list_backups
      echo ""
    fi
    usage
    exit 0
  fi

  log "Starting Bedrock DevOps Challenge restore..."
  log "Backup to restore: ${backup_name}"

  validate_backup "${backup_name}"
  check_localstack
  confirm_restore "${backup_name}"

  restore_s3 "${backup_name}"
  restore_prometheus "${backup_name}"
  restore_grafana "${backup_name}"

  show_summary "${backup_name}"

  log "Restore process completed successfully!"
}

# Run main function
main "$@"

