# CloudWatch Exporter Configuration

This directory contains the configuration for the Prometheus CloudWatch Exporter, which provides real S3 bucket usage monitoring by fetching metrics from AWS CloudWatch.

## Overview

The CloudWatch exporter has been added to replace the fake S3 usage estimation in the Grafana dashboard with actual CloudWatch metrics.

## Configuration

### Docker Compose
- **Service**: `cloudwatch-exporter`
- **Image**: `prom/cloudwatch-exporter:v0.15.5`
- **Port**: `9106`
- **Endpoint**: Configured to work with LocalStack at `http://localstack:4566`

### S3 Metrics Collected

1. **BucketSizeBytes** - Actual storage usage of the S3 bucket
   - Dimensions: BucketName, StorageType
   - Statistics: Average
   - Period: Daily (86400 seconds)

2. **NumberOfObjects** - Total count of objects in the bucket
   - Dimensions: BucketName, StorageType
   - Statistics: Average
   - Period: Daily (86400 seconds)

3. **AllRequests** - Total number of requests to the bucket
   - Dimensions: BucketName, FilterId
   - Statistics: Sum
   - Period: 5 minutes (300 seconds)

4. **BytesDownloaded** - Data downloaded from the bucket
   - Dimensions: BucketName, FilterId
   - Statistics: Sum
   - Period: 5 minutes (300 seconds)

5. **BytesUploaded** - Data uploaded to the bucket
   - Dimensions: BucketName, FilterId
   - Statistics: Sum
   - Period: 5 minutes (300 seconds)

## Grafana Dashboard Integration

### Updated Panels

1. **S3 Bucket Usage (Real CloudWatch)** - Now shows actual bucket size in bytes
   - Query: `aws_s3_bucket_size_bytes_average{bucket_name="app",storage_type="StandardStorage"}`

2. **S3 Object Count** - New gauge showing number of objects
   - Query: `aws_s3_number_of_objects_average{bucket_name="app",storage_type="AllStorageTypes"}`

3. **S3 Data Transfer Rate** - New timeseries showing upload/download rates
   - Upload Query: `rate(aws_s3_bytes_uploaded_sum{bucket_name="app"}[5m])`
   - Download Query: `rate(aws_s3_bytes_downloaded_sum{bucket_name="app"}[5m])`

4. **S3 Request Rate** - New timeseries showing API request rate
   - Query: `rate(aws_s3_all_requests_sum{bucket_name="app"}[5m])`

### Prometheus Configuration

The CloudWatch exporter is scraped by Prometheus with:
- **Job name**: `cloudwatch-exporter`
- **Scrape interval**: 60 seconds
- **Scrape timeout**: 55 seconds

## LocalStack Integration

The exporter is configured to work with LocalStack by:
- Setting `endpoint_url: http://localstack:4566`
- Using LocalStack's default credentials (`test`/`test`)
- Monitoring the `app` bucket created by the sample application

## Health Checks

The service includes health checks that verify:
- The exporter is responding on port 9106
- The `/metrics` endpoint is accessible
- Dependencies (LocalStack) are healthy before starting

## Troubleshooting

1. **No metrics appearing**: Check that LocalStack has S3 CloudWatch metrics enabled
2. **Connection issues**: Verify the CloudWatch exporter can reach LocalStack on port 4566
3. **Missing bucket metrics**: Ensure the `app` S3 bucket exists and has activity
4. **Scrape failures**: Check Prometheus targets page for CloudWatch exporter status

## Real-world Usage

When deploying to real AWS infrastructure:
1. Remove the `endpoint_url` configuration
2. Update AWS credentials to use proper IAM roles or access keys
3. Update bucket names to match your actual S3 buckets
4. Adjust metric collection periods based on your monitoring requirements