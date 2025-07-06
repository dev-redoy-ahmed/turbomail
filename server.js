const express = require('express');
const redis = require('redis');
const bodyParser = require('body-parser');
const cors = require('cors');
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

const app = express();

// Configuration object
const config = {
    port: process.env.PORT || 3001,
    apiKey: 'supersecretapikey123',
    redis: {
        host: '127.0.0.1',
        port: 6379,
        password: 'we1we2we3',
        retryAttempts: 5,
        retryDelay: 2000
    }
};

// Simple logger utility
const logger = {
    info: (message) => console.log(`[INFO] ${new Date().toISOString()} - ${message}`),
    error: (message) => console.error(`[ERROR] ${new Date().toISOString()} - ${message}`),
    warn: (message) => console.warn(`[WARN] ${new Date().toISOString()} - ${message}`)
};

// Middleware to validate API key
function validateApiKey(req, res, next) {
    const providedKey = req.query.key || req.body.key || req.headers['x-api-key'];
    
    if (!providedKey) {
        return res.status(401).json({ 
            error: 'API key is required. Please provide it as a query parameter (?key=your_key), in request body, or in x-api-key header.' 
        });
    }
    
    if (providedKey !== config.apiKey) {
        return res.status(401).json({ 
            error: 'Invalid API key. Please check your API key and try again.' 
        });
    }
    
    next();
}

// Redis client setup with retry logic
let redisClient;
let redisConnected = false;
let connectionAttempts = 0;

// Enhanced Redis connection function with retry logic
async function connectRedis() {
    for (let attempt = 1; attempt <= config.redis.retryAttempts; attempt++) {
        try {
            connectionAttempts++;
            logger.info(`Redis connection attempt ${attempt}/${config.redis.retryAttempts}`);
            
            redisClient = redis.createClient({
                host: config.redis.host,
                port: config.redis.port,
                password: config.redis.password,
                retry_strategy: (options) => {
                    if (options.error && options.error.code === 'ECONNREFUSED') {
                        logger.error('Redis server refused connection');
                    }
                    if (options.total_retry_time > 1000 * 60 * 60) {
                        logger.error('Redis retry time exhausted');
                        return new Error('Retry time exhausted');
                    }
                    if (options.attempt > 10) {
                        return undefined;
                    }
                    return Math.min(options.attempt * 100, 3000);
                }
            });

            // Redis event handlers
            redisClient.on('error', (err) => {
                logger.error(`Redis Client Error: ${err.message}`);
                redisConnected = false;
            });

            redisClient.on('connect', () => {
                logger.info('✅ Redis Client Connected Successfully');
                redisConnected = true;
                connectionAttempts = 0;
            });

            redisClient.on('ready', () => {
                logger.info('✅ Redis Client Ready for Operations');
                redisConnected = true;
            });

            redisClient.on('end', () => {
                logger.warn('⚠️ Redis Client Connection Ended');
                redisConnected = false;
            });

            redisClient.on('reconnecting', () => {
                logger.info('🔄 Redis Client Reconnecting...');
            });

            // Test connection
            await new Promise((resolve, reject) => {
                const timeout = setTimeout(() => {
                    reject(new Error('Connection timeout'));
                }, 5000);
                
                redisClient.on('ready', () => {
                    clearTimeout(timeout);
                    resolve();
                });
                
                redisClient.on('error', (err) => {
                    clearTimeout(timeout);
                    reject(err);
                });
            });

            logger.info('✅ Redis connection established successfully');
            return;
            
        } catch (error) {
            logger.error(`Redis connection attempt ${attempt} failed: ${error.message}`);
            
            if (attempt === config.redis.retryAttempts) {
                logger.warn('🔄 All Redis connection attempts failed. Running in standalone mode.');
                logger.warn('📧 Email persistence will be disabled until Redis is available.');
                redisConnected = false;
                return;
            }
            
            logger.info(`⏳ Waiting ${config.redis.retryDelay}ms before next attempt...`);
            await new Promise(resolve => setTimeout(resolve, config.redis.retryDelay));
        }
    }
}

// Initialize Redis connection
connectRedis().catch(error => {
    logger.error(`Failed to initialize Redis: ${error.message}`);
});

// Input validation middleware
function validateEmail(req, res, next) {
    const email = req.params.email;
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    
    if (!email) {
        return res.status(400).json({ error: 'Email parameter is required' });
    }
    
    if (!emailRegex.test(email)) {
        return res.status(400).json({ error: 'Invalid email format' });
    }
    
    next();
}

// Error handling middleware
function errorHandler(err, req, res, next) {
    logger.error(`Unhandled error: ${err.message}`);
    logger.error(err.stack);
    
    res.status(500).json({
        error: 'Internal server error',
        message: process.env.NODE_ENV === 'development' ? err.message : 'Something went wrong'
    });
}

// Request logging middleware
function requestLogger(req, res, next) {
    const start = Date.now();
    const { method, url, ip } = req;
    
    res.on('finish', () => {
        const duration = Date.now() - start;
        const { statusCode } = res;
        logger.info(`${method} ${url} - ${statusCode} - ${duration}ms - ${ip}`);
    });
    
    next();
}

// Middleware
app.use(cors({
    origin: ['http://localhost:3001', 'http://127.0.0.1:3001'],
    credentials: true
}));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));
app.use(requestLogger);
app.use(express.static('public'));



// Load domains from file
const loadDomains = () => {
  try {
    const data = fs.readFileSync('domains.txt', 'utf8');
    return data.split('\n').filter(domain => domain.trim() !== '');
  } catch (err) {
    return ['oplex.online', 'agrovia.store', 'usashow.live', 'worldwides.help'];
  }
};

// Save domains to file
const saveDomains = (domains) => {
  fs.writeFileSync('domains.txt', domains.join('\n'));
};

// Generate random email
app.get('/generate', validateApiKey, async (req, res) => {
  const domains = loadDomains();
  const randomDomain = domains[Math.floor(Math.random() * domains.length)];
  const randomUsername = crypto.randomBytes(8).toString('hex');
  const email = `${randomUsername}@${randomDomain}`;
  
  res.json({ email: email });
});

// Generate email with specific username and domain
app.get('/generate/manual', validateApiKey, async (req, res) => {
  const { username, domain } = req.query;
  
  if (!username || !domain) {
    return res.status(400).json({ error: 'Username and domain are required' });
  }
  
  const domains = loadDomains();
  if (!domains.includes(domain)) {
    return res.status(400).json({ error: 'Domain not allowed' });
  }
  
  const email = `${username}@${domain}`;
  res.json({ email: email });
});

// Get all emails for an inbox
app.get('/inbox/:email', validateApiKey, validateEmail, async (req, res) => {
  if (!redisConnected) {
    return res.status(503).json({ 
      error: 'Redis service unavailable', 
      message: 'Email storage is temporarily unavailable. Please try again later.' 
    });
  }
  
  try {
    const email = req.params.email;
    logger.info(`Retrieving inbox for: ${email}`);
    
    const messages = await redisClient.lRange(`inbox:${email}`, 0, -1);
    const parsedMessages = messages.map(msg => {
      try {
        return JSON.parse(msg);
      } catch (parseError) {
        logger.error(`Failed to parse message: ${parseError.message}`);
        return { error: 'Corrupted message data' };
      }
    });
    
    logger.info(`Retrieved ${parsedMessages.length} messages for ${email}`);
    res.json({ 
      email, 
      messages: parsedMessages,
      count: parsedMessages.length,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    logger.error(`Failed to retrieve inbox for ${req.params.email}: ${error.message}`);
    res.status(500).json({ 
      error: 'Failed to retrieve inbox',
      message: 'An error occurred while fetching your emails'
    });
  }
});

// Get specific email by index
app.get('/inbox/:email/:index', validateApiKey, validateEmail, async (req, res) => {
  if (!redisConnected) {
    return res.status(503).json({ 
      error: 'Redis service unavailable',
      message: 'Email storage is temporarily unavailable. Please try again later.'
    });
  }
  
  try {
    const email = req.params.email;
    const index = parseInt(req.params.index);
    
    if (isNaN(index) || index < 0) {
      return res.status(400).json({ 
        error: 'Invalid index',
        message: 'Index must be a non-negative number'
      });
    }
    
    logger.info(`Retrieving message ${index} for: ${email}`);
    
    const message = await redisClient.lIndex(`inbox:${email}`, index);
    if (!message) {
      return res.status(404).json({ 
        error: 'Message not found',
        message: `No message found at index ${index} for ${email}`
      });
    }
    
    let parsedMessage;
    try {
      parsedMessage = JSON.parse(message);
    } catch (parseError) {
      logger.error(`Failed to parse message at index ${index}: ${parseError.message}`);
      return res.status(500).json({ 
        error: 'Corrupted message data',
        message: 'The requested message contains invalid data'
      });
    }
    
    logger.info(`Retrieved message ${index} for ${email}`);
    res.json({ 
      email, 
      index, 
      message: parsedMessage,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    logger.error(`Failed to retrieve message ${req.params.index} for ${req.params.email}: ${error.message}`);
    res.status(500).json({ 
      error: 'Failed to retrieve message',
      message: 'An error occurred while fetching the requested message'
    });
  }
});

// Delete all emails for an inbox
app.delete('/delete/:email', validateApiKey, validateEmail, async (req, res) => {
  if (!redisConnected) {
    return res.status(503).json({ 
      error: 'Redis service unavailable',
      message: 'Email storage is temporarily unavailable. Please try again later.'
    });
  }
  
  try {
    const email = req.params.email;
    logger.info(`Deleting all messages for: ${email}`);
    
    // Check if inbox exists
    const messageCount = await redisClient.lLen(`inbox:${email}`);
    
    if (messageCount === 0) {
      return res.status(404).json({ 
        error: 'Inbox not found',
        message: `No messages found for ${email}`
      });
    }
    
    const deletedCount = await redisClient.del(`inbox:${email}`);
    
    logger.info(`Deleted ${messageCount} messages for ${email}`);
    res.json({ 
      message: `All messages deleted for ${email}`,
      deletedCount: messageCount,
      email,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    logger.error(`Failed to delete messages for ${req.params.email}: ${error.message}`);
    res.status(500).json({ 
      error: 'Failed to delete messages',
      message: 'An error occurred while deleting your emails'
    });
  }
});

// Delete specific email by index
app.delete('/delete/:email/:index', validateApiKey, validateEmail, async (req, res) => {
  if (!redisConnected) {
    return res.status(503).json({ 
      error: 'Redis service unavailable',
      message: 'Email storage is temporarily unavailable. Please try again later.'
    });
  }
  
  try {
    const email = req.params.email;
    const index = parseInt(req.params.index);
    
    if (isNaN(index) || index < 0) {
      return res.status(400).json({ 
        error: 'Invalid index',
        message: 'Index must be a non-negative number'
      });
    }
    
    logger.info(`Deleting message ${index} for: ${email}`);
    
    // Get the message first to check if it exists
    const message = await redisClient.lIndex(`inbox:${email}`, index);
    if (!message) {
      return res.status(404).json({ 
        error: 'Message not found',
        message: `No message found at index ${index} for ${email}`
      });
    }
    
    // Get all messages
    const messages = await redisClient.lRange(`inbox:${email}`, 0, -1);
    
    if (index >= messages.length) {
      return res.status(404).json({ 
        error: 'Index out of range',
        message: `Index ${index} is out of range. Inbox has ${messages.length} messages.`
      });
    }
    
    // Remove the message at the specified index
    const deletedMessage = messages.splice(index, 1)[0];
    
    // Clear the original list and repopulate
    await redisClient.del(`inbox:${email}`);
    if (messages.length > 0) {
      await redisClient.rPush(`inbox:${email}`, messages);
    }
    
    let parsedDeletedMessage;
    try {
      parsedDeletedMessage = JSON.parse(deletedMessage);
    } catch (parseError) {
      parsedDeletedMessage = { error: 'Corrupted message data' };
    }
    
    logger.info(`Deleted message ${index} for ${email}`);
    res.json({ 
      message: `Message at index ${index} deleted for ${email}`,
      deletedMessage: parsedDeletedMessage,
      email,
      index,
      remainingCount: messages.length,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    logger.error(`Failed to delete message ${req.params.index} for ${req.params.email}: ${error.message}`);
    res.status(500).json({ 
      error: 'Failed to delete message',
      message: 'An error occurred while deleting the requested message'
    });
  }
});

// Health check endpoint
app.get('/health', (req, res) => {
  const healthStatus = {
    status: 'OK',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    version: '1.0.0',
    services: {
      redis: {
        connected: redisConnected,
        attempts: connectionAttempts,
        status: redisConnected ? 'Connected' : 'Disconnected'
      },
      api: {
        status: 'Running',
        port: config.port
      }
    },
    memory: {
      used: Math.round(process.memoryUsage().heapUsed / 1024 / 1024) + ' MB',
      total: Math.round(process.memoryUsage().heapTotal / 1024 / 1024) + ' MB'
    }
  };
  
  const statusCode = redisConnected ? 200 : 503;
  res.status(statusCode).json(healthStatus);
});

// Admin API endpoints
app.get('/admin/domains', (req, res) => {
  try {
    const domains = loadDomains();
    logger.info(`Retrieved ${domains.length} domains`);
    res.json({ 
      domains,
      count: domains.length,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    logger.error(`Failed to load domains: ${error.message}`);
    res.status(500).json({ 
      error: 'Failed to load domains',
      message: 'An error occurred while retrieving domain list'
    });
  }
});

app.post('/admin/domains', (req, res) => {
  try {
    const { domain } = req.body;
    
    if (!domain) {
      return res.status(400).json({ 
        error: 'Domain is required',
        message: 'Please provide a domain name'
      });
    }
    
    // Basic domain validation
    const domainRegex = /^[a-zA-Z0-9][a-zA-Z0-9-]{0,61}[a-zA-Z0-9]?\.[a-zA-Z]{2,}$/;
    if (!domainRegex.test(domain)) {
      return res.status(400).json({ 
        error: 'Invalid domain format',
        message: 'Please provide a valid domain name'
      });
    }
    
    const domains = loadDomains();
    
    if (domains.includes(domain)) {
      return res.status(409).json({ 
        error: 'Domain already exists',
        message: `Domain ${domain} is already in the list`
      });
    }
    
    domains.push(domain);
    saveDomains(domains);
    
    logger.info(`Added new domain: ${domain}`);
    res.status(201).json({ 
      message: 'Domain added successfully', 
      domain,
      domains,
      count: domains.length,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    logger.error(`Failed to add domain: ${error.message}`);
    res.status(500).json({ 
      error: 'Failed to add domain',
      message: 'An error occurred while adding the domain'
    });
  }
});

app.delete('/admin/domains/:domain', (req, res) => {
  try {
    const domainToDelete = req.params.domain;
    let domains = loadDomains();
    
    const initialLength = domains.length;
    domains = domains.filter(domain => domain !== domainToDelete);
    
    if (domains.length === initialLength) {
      return res.status(404).json({ 
        error: 'Domain not found',
        message: `Domain ${domainToDelete} was not found in the list`
      });
    }
    
    saveDomains(domains);
    
    logger.info(`Deleted domain: ${domainToDelete}`);
    res.json({ 
      message: 'Domain deleted successfully', 
      deletedDomain: domainToDelete,
      domains,
      count: domains.length,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    logger.error(`Failed to delete domain: ${error.message}`);
    res.status(500).json({ 
      error: 'Failed to delete domain',
      message: 'An error occurred while deleting the domain'
    });
  }
});

// Serve admin panel
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// 404 handler for undefined routes
app.use('*', (req, res) => {
  logger.warn(`404 - Route not found: ${req.method} ${req.originalUrl}`);
  res.status(404).json({
    error: 'Route not found',
    message: `The requested endpoint ${req.method} ${req.originalUrl} does not exist`,
    availableEndpoints: {
      api: [
        'GET /generate',
        'GET /generate/manual',
        'GET /inbox/:email',
        'GET /inbox/:email/:index',
        'DELETE /delete/:email',
        'DELETE /delete/:email/:index'
      ],
      admin: [
        'GET /admin/domains',
        'POST /admin/domains',
        'DELETE /admin/domains/:domain'
      ],
      system: [
        'GET /health',
        'GET /'
      ]
    },
    timestamp: new Date().toISOString()
  });
});

// Global error handling middleware (must be last)
app.use(errorHandler);

// Graceful shutdown handling
process.on('SIGTERM', async () => {
  logger.info('🛑 SIGTERM received, shutting down gracefully...');
  
  if (redisClient && redisConnected) {
    try {
      await redisClient.quit();
      logger.info('✅ Redis connection closed');
    } catch (error) {
      logger.error(`Error closing Redis connection: ${error.message}`);
    }
  }
  
  process.exit(0);
});

process.on('SIGINT', async () => {
  logger.info('🛑 SIGINT received, shutting down gracefully...');
  
  if (redisClient && redisConnected) {
    try {
      await redisClient.quit();
      logger.info('✅ Redis connection closed');
    } catch (error) {
      logger.error(`Error closing Redis connection: ${error.message}`);
    }
  }
  
  process.exit(0);
});

// Start the server
app.listen(config.port, () => {
  logger.info(`🚀 TurboMail API Server started successfully`);
  logger.info(`📡 Server running on port ${config.port}`);
  logger.info(`🌐 Admin Panel: http://localhost:${config.port}`);
  logger.info(`🔗 API Base URL: http://localhost:${config.port}`);
  logger.info(`❤️  Health Check: http://localhost:${config.port}/health`);
  logger.info(`🔑 API Key: ${config.apiKey}`);
  logger.info(`📊 Memory Usage: ${Math.round(process.memoryUsage().heapUsed / 1024 / 1024)} MB`);
  
  if (!redisConnected) {
    logger.warn(`⚠️  Redis not connected - running in standalone mode`);
    logger.warn(`📧 Email persistence disabled until Redis is available`);
  }
  
  logger.info(`✨ TurboMail is ready to handle requests!`);
});

module.exports = app;