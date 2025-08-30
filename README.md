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

### Install LocalStack

Follow the installation guide:
https://docs.localstack.cloud/aws/getting-started/installation/

## Quick Start

### 1. Start the Development Environment

Start LocalStack using Docker Compose:
```bash
docker compose up -d
```

### 2. Verify Installation

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
export LOCALSTACK_HOST=localstack-main.orb.local
localstack status services
```

### 3. Access LocalStack

- **LocalStack Gateway**: http://localhost:4566
- **External Services**: Ports 4510-4559 are available for additional services

**Note for OrbStack users**: Use the convenient domain name instead of localhost:
- **LocalStack Gateway**: http://localstack-main.orb.local:4566
- **Or using service name**: http://localstack.bedrock-devops-challenge.orb.local:4566

## Configuration

The Docker Compose setup includes:
- **Container Name**: `localstack-main` (configurable via `LOCALSTACK_DOCKER_NAME`)
- **LocalStack Version**: 4.7
- **Debug Mode**: Disabled by default (enable with `DEBUG=1`)
- **Volume Mapping**: Local `./volume` directory for persistence

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `LOCALSTACK_DOCKER_NAME` | `localstack-main` | Container name |
| `DEBUG` | `0` | Enable debug mode (set to `1`) |
| `LOCALSTACK_VOLUME_DIR` | `./volume` | Local volume directory |

## Usage Examples

### AWS CLI Configuration

Configure AWS CLI to use LocalStack:
```bash
aws configure set aws_access_key_id test
aws configure set aws_secret_access_key test
aws configure set region us-east-1
```

Use LocalStack endpoint:
```bash
aws --endpoint-url=http://localhost:4566 s3 ls
```

**For OrbStack users**, use the domain name:
```bash
aws --endpoint-url=http://localstack-main.orb.local:4566 s3 ls
```

## Troubleshooting

### Common Issues

**LocalStack not starting:**
- Ensure Docker is running
- Check port 4566 is not in use: `lsof -i :4566` (Docker Desktop) or `curl http://localstack-main.orb.local:4566` (OrbStack)
- Review logs: `docker compose logs localstack`

**Permission issues:**
- Ensure Docker socket is accessible
- On Linux, add user to docker group: `sudo usermod -aG docker $USER`

**Port conflicts:**
- Modify port mappings in `docker-compose.yml` if needed
- Default ports: 4566 (gateway), 4510-4559 (services)

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

## Resources

- [LocalStack Documentation](https://docs.localstack.cloud/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [AWS CLI Configuration](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html)
