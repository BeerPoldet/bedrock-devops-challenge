const express = require('express');
const multer = require('multer');
const { S3Client, PutObjectCommand } = require('@aws-sdk/client-s3');
const promClient = require('prom-client');
const winston = require('winston');
const { S3StreamTransport } = require('winston-s3-transport');
const helmet = require('helmet');
const cors = require('cors');
const { z } = require('zod');
require('dotenv').config();

// Environment validation schema
const envSchema = z.object({
  PORT: z.coerce.number().int().positive().default(3000),
  NODE_ENV: z.enum(['development', 'staging', 'production']).default('development'),
  AWS_ENDPOINT: z.url().default('http://localhost:4566'),
  AWS_REGION: z.string().min(1).default('us-east-1'),
  AWS_ACCESS_KEY_ID: z.string().min(1).default('test'),
  AWS_SECRET_ACCESS_KEY: z.string().min(1).default('test'),
  S3_BUCKET_NAME: z.string().min(1).default('app')
});

// Validate environment variables
const env = envSchema.parse(process.env);

const app = express();
const port = env.PORT;

// Security middleware
app.use(helmet());
app.use(cors());
app.use(express.json({ limit: '50mb' }));

// Prometheus metrics setup
const collectDefaultMetrics = promClient.collectDefaultMetrics;
const Registry = promClient.Registry;
const register = new Registry();
collectDefaultMetrics({ register });

// Custom metrics
const httpRequestDuration = new promClient.Histogram({
  name: 'http_request_duration_seconds',
  help: 'Duration of HTTP requests in seconds',
  labelNames: ['method', 'route', 'status_code'],
  buckets: [0.1, 0.3, 0.5, 0.7, 1, 3, 5, 7, 10]
});

const httpRequestsTotal = new promClient.Counter({
  name: 'http_requests_total',
  help: 'Total number of HTTP requests',
  labelNames: ['method', 'route', 'status_code']
});

const fileUploadsTotal = new promClient.Counter({
  name: 'file_uploads_total',
  help: 'Total number of file uploads',
  labelNames: ['status']
});

const fileUploadSize = new promClient.Histogram({
  name: 'file_upload_size_bytes',
  help: 'Size of uploaded files in bytes',
  buckets: [1024, 10240, 102400, 1048576, 10485760, 52428800]
});

register.registerMetric(httpRequestDuration);
register.registerMetric(httpRequestsTotal);
register.registerMetric(fileUploadsTotal);
register.registerMetric(fileUploadSize);

// Logger setup
const logTransports = [
  new winston.transports.Console({
    format: winston.format.combine(
      winston.format.colorize(),
      winston.format.simple()
    )
  }),
  new S3StreamTransport({
    s3ClientConfig: {
      endpoint: env.AWS_ENDPOINT,
      region: env.AWS_REGION,
      credentials: {
        accessKeyId: env.AWS_ACCESS_KEY_ID,
        secretAccessKey: env.AWS_SECRET_ACCESS_KEY
      },
      forcePathStyle: true
    },
    s3TransportConfig: {
      bucket: env.S3_BUCKET_NAME,
      generateGroup: () => 'application-logs',
      generateBucketPath: (group) => {
        const date = new Date();
        const timestamp = date.toISOString().slice(0, 16).replace(/[-:]/g, '').replace('T', '-'); // YYYYMMDD-HHMM
        return `logs/${group}/${timestamp}.log`;
      }
    }
  })
]

const logger = winston.createLogger({
  level: 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.errors({ stack: true }),
    winston.format.json()
  ),
  defaultMeta: { service: 'app' },
  transports: logTransports
});

// AWS S3 setup for LocalStack
const s3Client = new S3Client({
  endpoint: env.AWS_ENDPOINT,
  region: env.AWS_REGION,
  credentials: {
    accessKeyId: env.AWS_ACCESS_KEY_ID,
    secretAccessKey: env.AWS_SECRET_ACCESS_KEY
  },
  forcePathStyle: true
});

// Multer setup for file uploads
const storage = multer.memoryStorage();
const upload = multer({
  storage: storage,
  limits: {
    fileSize: 50 * 1024 * 1024 // 50MB limit
  }
});

// Middleware to track request metrics
app.use((req, res, next) => {
  const start = Date.now();

  res.on('finish', () => {
    const duration = (Date.now() - start) / 1000;
    const route = req.route ? req.route.path : req.path;

    httpRequestDuration
      .labels(req.method, route, res.statusCode.toString())
      .observe(duration);

    httpRequestsTotal
      .labels(req.method, route, res.statusCode.toString())
      .inc();

    logger.info('HTTP Request', {
      method: req.method,
      url: req.url,
      statusCode: res.statusCode,
      duration: duration,
      userAgent: req.get('User-Agent'),
      ip: req.ip
    });
  });

  next();
});

// Health check endpoint
app.get('/health', (req, res) => {
  const healthCheck = {
    uptime: process.uptime(),
    message: 'OK',
    timestamp: new Date().toISOString(),
    environment: env.NODE_ENV
  };

  logger.info('Health check requested', healthCheck);
  res.status(200).json(healthCheck);
});

// Metrics endpoint for Prometheus
app.get('/metrics', async (req, res) => {
  try {
    res.set('Content-Type', register.contentType);
    res.end(await register.metrics());
  } catch (error) {
    logger.error('Error generating metrics', { error: error.message });
    res.status(500).end(error.message);
  }
});

// File upload endpoint
app.post('/upload', upload.single('file'), async (req, res) => {
  try {
    if (!req.file) {
      fileUploadsTotal.labels('error').inc();
      logger.warn('Upload attempt without file');
      return res.status(400).json({ error: 'No file provided' });
    }

    const bucketName = env.S3_BUCKET_NAME;
    const fileName = `uploads/${Date.now()}-${req.file.originalname}`;

    const uploadParams = {
      Bucket: bucketName,
      Key: fileName,
      Body: req.file.buffer,
      ContentType: req.file.mimetype,
      Metadata: {
        'original-name': req.file.originalname,
        'upload-timestamp': new Date().toISOString()
      }
    };

    logger.info('Uploading file to S3', {
      fileName: fileName,
      size: req.file.size,
      mimetype: req.file.mimetype,
      bucket: bucketName
    });

    const command = new PutObjectCommand(uploadParams);
    const result = await s3Client.send(command);

    fileUploadsTotal.labels('success').inc();
    fileUploadSize.observe(req.file.size);

    const location = `${env.AWS_ENDPOINT}/${bucketName}/${fileName}`;

    logger.info('File uploaded successfully', {
      fileName: fileName,
      location: location,
      size: req.file.size,
      etag: result.ETag
    });

    res.status(200).json({
      message: 'File uploaded successfully',
      fileName: fileName,
      size: req.file.size,
      location: location,
      etag: result.ETag,
      uploadedAt: new Date().toISOString()
    });

  } catch (error) {
    fileUploadsTotal.labels('error').inc();
    logger.error('File upload failed', {
      error: error.message,
      stack: error.stack,
      fileName: req.file?.originalname
    });

    res.status(500).json({
      error: 'Upload failed',
      message: error.message
    });
  }
});

// Root endpoint
app.get('/', (req, res) => {
  res.json({
    message: 'Bedrock DevOps Challenge Application',
    version: '1.0.0',
    endpoints: {
      health: '/health',
      metrics: '/metrics',
      upload: 'POST /upload'
    }
  });
});

// Error handling middleware
app.use((error, req, res) => {
  logger.error('Unhandled error', {
    error: error.message,
    stack: error.stack,
    url: req.url,
    method: req.method
  });

  res.status(500).json({
    error: 'Internal server error',
    message: error.message
  });
});

// 404 handler
app.use((req, res) => {
  logger.warn('404 Not Found', {
    url: req.url,
    method: req.method,
    ip: req.ip
  });

  res.status(404).json({
    error: 'Not found',
    message: 'The requested resource was not found'
  });
});

// Graceful shutdown
process.on('SIGTERM', () => {
  logger.info('SIGTERM received, shutting down gracefully');
  server.close(() => {
    logger.info('Process terminated');
  });
});

process.on('SIGINT', () => {
  logger.info('SIGINT received, shutting down gracefully');
  server.close(() => {
    logger.info('Process terminated');
  });
});

const server = app.listen(port, '0.0.0.0', () => {
  logger.info(`Application started`, {
    port: port,
    environment: env.NODE_ENV,
    nodeVersion: process.version
  });
});

module.exports = app;
