#!/usr/bin/env python3
"""
S3 Metrics Generator for LocalStack
Generates Prometheus-format S3 metrics based on actual bucket contents
"""

import os
import time
import boto3
from datetime import datetime
from flask import Flask, Response

app = Flask(__name__)

def get_s3_client():
    """Get S3 client configured for LocalStack"""
    return boto3.client(
        's3',
        endpoint_url=os.getenv('AWS_ENDPOINT', 'http://localstack:4566'),
        region_name=os.getenv('AWS_REGION', 'us-east-1'),
        aws_access_key_id=os.getenv('AWS_ACCESS_KEY_ID', 'test'),
        aws_secret_access_key=os.getenv('AWS_SECRET_ACCESS_KEY', 'test')
    )

def get_bucket_metrics(s3_client, bucket_name):
    """Calculate bucket metrics based on actual contents"""
    try:
        # List all objects in bucket
        response = s3_client.list_objects_v2(Bucket=bucket_name)
        
        if 'Contents' not in response:
            return {
                'bucket_size_bytes': 0,
                'number_of_objects': 0
            }
        
        # Calculate total size and count
        total_size = sum(obj['Size'] for obj in response['Contents'])
        object_count = len(response['Contents'])
        
        return {
            'bucket_size_bytes': total_size,
            'number_of_objects': object_count
        }
        
    except Exception as e:
        print(f"Error getting bucket metrics: {e}")
        return {
            'bucket_size_bytes': 0,
            'number_of_objects': 0
        }

@app.route('/metrics')
def metrics():
    """Generate Prometheus metrics"""
    s3_client = get_s3_client()
    bucket_name = os.getenv('S3_BUCKET_NAME', 'app')
    
    # Get current bucket metrics
    metrics = get_bucket_metrics(s3_client, bucket_name)
    
    # Generate Prometheus format metrics
    output = []
    
    # Bucket size metric
    output.append('# HELP aws_s3_bucket_size_bytes_average S3 bucket size in bytes')
    output.append('# TYPE aws_s3_bucket_size_bytes_average gauge')
    output.append(f'aws_s3_bucket_size_bytes_average{{bucket_name="{bucket_name}",storage_type="StandardStorage"}} {metrics["bucket_size_bytes"]}')
    
    # Object count metric
    output.append('# HELP aws_s3_number_of_objects_average Number of objects in S3 bucket')
    output.append('# TYPE aws_s3_number_of_objects_average gauge')
    output.append(f'aws_s3_number_of_objects_average{{bucket_name="{bucket_name}",storage_type="AllStorageTypes"}} {metrics["number_of_objects"]}')
    
    # Mock data transfer metrics (based on recent activity)
    current_time = int(time.time())
    upload_rate = max(0, 1024 * (current_time % 60))  # Simulate varying upload rate
    download_rate = max(0, 512 * ((current_time + 30) % 60))  # Simulate varying download rate
    
    output.append('# HELP aws_s3_bytes_uploaded_sum Total bytes uploaded to S3 bucket')
    output.append('# TYPE aws_s3_bytes_uploaded_sum counter')
    output.append(f'aws_s3_bytes_uploaded_sum{{bucket_name="{bucket_name}"}} {upload_rate}')
    
    output.append('# HELP aws_s3_bytes_downloaded_sum Total bytes downloaded from S3 bucket')
    output.append('# TYPE aws_s3_bytes_downloaded_sum counter')
    output.append(f'aws_s3_bytes_downloaded_sum{{bucket_name="{bucket_name}"}} {download_rate}')
    
    # Request metrics - counter should be monotonically increasing  
    # Simulate cumulative requests starting from a more recent baseline
    start_time = 1757007000  # Recent baseline timestamp
    if current_time < start_time:
        start_time = current_time  # If somehow we're before baseline, use current time
    
    elapsed_seconds = current_time - start_time
    base_requests = elapsed_seconds * 0.5  # 0.5 requests per second baseline
    variation = abs((current_time % 60) - 30) * 0.1  # Add some variation
    total_requests = max(0, int(base_requests + variation))  # Ensure non-negative
    
    output.append('# HELP aws_s3_all_requests_sum Total requests to S3 bucket')
    output.append('# TYPE aws_s3_all_requests_sum counter')
    output.append(f'aws_s3_all_requests_sum{{bucket_name="{bucket_name}"}} {total_requests}')
    
    # Add timestamp
    output.append(f'# Generated at {datetime.now().isoformat()}')
    output.append('')  # Empty line at end
    
    return Response('\n'.join(output), mimetype='text/plain')

@app.route('/health')
def health():
    """Health check endpoint"""
    return {'status': 'healthy', 'service': 's3-metrics-generator'}

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=9107, debug=False)