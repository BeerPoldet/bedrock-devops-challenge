FROM python:3.11-slim

# Install required Python packages
RUN pip install --no-cache-dir flask boto3

# Copy the metrics generator script
COPY generate_s3_metrics.py /app/generate_s3_metrics.py

# Set working directory
WORKDIR /app

# Make script executable
RUN chmod +x generate_s3_metrics.py

# Expose the metrics port
EXPOSE 9107

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:9107/health || exit 1

# Run the metrics generator
CMD ["python", "generate_s3_metrics.py"]