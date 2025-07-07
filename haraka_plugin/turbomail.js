const Redis = require('redis');
const { PassThrough } = require('stream');
const http = require('http');
const { Server } = require('socket.io');

let redisClient;
let redisSubscriber;
let io;
let httpServer;

// Performance optimization configs
const CONFIG = {
    redis: {
        url: 'redis://:we1we2we3@127.0.0.1:6379',
        socket: {
            reconnectStrategy: (retries) => Math.min(retries * 50, 500),
            keepAlive: 30000,
            noDelay: true,
            connectTimeout: 5000,
            commandTimeout: 5000
        },
        // Connection pooling for high load
        pool: {
            min: 5,
            max: 20
        }
    },
    websocket: {
        port: 3005,
        cors: {
            origin: ['http://localhost:3001', 'http://localhost:3002', 'http://127.0.0.1:3001', 'http://127.0.0.1:3002'],
            methods: ['GET', 'POST']
        },
        // Performance settings for million users
        transports: ['websocket'],
        pingTimeout: 60000,
        pingInterval: 25000,
        maxHttpBufferSize: 1e6,
        allowEIO3: true
    },
    performance: {
        batchSize: 100,
        flushInterval: 50, // ms
        maxConcurrentOperations: 1000
    }
};

// Batch processing queue for high performance
class BatchProcessor {
    constructor() {
        this.queue = [];
        this.processing = false;
        this.timer = null;
    }

    add(operation) {
        this.queue.push(operation);
        
        if (this.queue.length >= CONFIG.performance.batchSize) {
            this.flush();
        } else if (!this.timer) {
            this.timer = setTimeout(() => this.flush(), CONFIG.performance.flushInterval);
        }
    }

    async flush() {
        if (this.processing || this.queue.length === 0) return;
        
        this.processing = true;
        if (this.timer) {
            clearTimeout(this.timer);
            this.timer = null;
        }

        const batch = this.queue.splice(0, CONFIG.performance.batchSize);
        
        try {
            // Process batch operations in parallel with concurrency limit
            const chunks = [];
            for (let i = 0; i < batch.length; i += CONFIG.performance.maxConcurrentOperations) {
                chunks.push(batch.slice(i, i + CONFIG.performance.maxConcurrentOperations));
            }

            for (const chunk of chunks) {
                await Promise.allSettled(chunk.map(op => op()));
            }
        } catch (err) {
            console.error('Batch processing error:', err);
        } finally {
            this.processing = false;
            
            // Continue processing if more items in queue
            if (this.queue.length > 0) {
                setImmediate(() => this.flush());
            }
        }
    }
}

const batchProcessor = new BatchProcessor();

// Connection pool manager
class RedisConnectionPool {
    constructor() {
        this.connections = [];
        this.available = [];
        this.inUse = new Set();
    }

    async initialize() {
        for (let i = 0; i < CONFIG.redis.pool.min; i++) {
            const client = await this.createConnection();
            this.connections.push(client);
            this.available.push(client);
        }
    }

    async createConnection() {
        const client = Redis.createClient(CONFIG.redis);
        await client.connect();
        return client;
    }

    async getConnection() {
        if (this.available.length > 0) {
            const client = this.available.pop();
            this.inUse.add(client);
            return client;
        }

        if (this.connections.length < CONFIG.redis.pool.max) {
            const client = await this.createConnection();
            this.connections.push(client);
            this.inUse.add(client);
            return client;
        }

        // Wait for available connection
        return new Promise((resolve) => {
            const checkAvailable = () => {
                if (this.available.length > 0) {
                    const client = this.available.pop();
                    this.inUse.add(client);
                    resolve(client);
                } else {
                    setTimeout(checkAvailable, 10);
                }
            };
            checkAvailable();
        });
    }

    releaseConnection(client) {
        this.inUse.delete(client);
        this.available.push(client);
    }
}

const connectionPool = new RedisConnectionPool();

// WebSocket server for real-time notifications
function initializeWebSocketServer(plugin) {
    httpServer = http.createServer();
    io = new Server(httpServer, CONFIG.websocket);

    io.on('connection', (socket) => {
        plugin.loginfo(`WebSocket client connected: ${socket.id}`);

        socket.on('subscribe-email', (email) => {
            if (email && typeof email === 'string') {
                socket.join(`email:${email}`);
                plugin.loginfo(`Client ${socket.id} subscribed to: ${email}`);
                socket.emit('subscribed', { email, message: 'Successfully subscribed' });
            }
        });

        socket.on('unsubscribe-email', (email) => {
            if (email && typeof email === 'string') {
                socket.leave(`email:${email}`);
                plugin.loginfo(`Client ${socket.id} unsubscribed from: ${email}`);
                socket.emit('unsubscribed', { email, message: 'Successfully unsubscribed' });
            }
        });

        socket.on('disconnect', () => {
            plugin.loginfo(`WebSocket client disconnected: ${socket.id}`);
        });
    });

    httpServer.listen(CONFIG.websocket.port, () => {
        plugin.loginfo(`WebSocket server listening on port ${CONFIG.websocket.port}`);
    });
}

// Optimized real-time notification broadcaster
function broadcastNewEmail(email, emailData) {
    if (!io) return;
    
    // Use setImmediate for non-blocking broadcast
    setImmediate(() => {
        try {
            const room = `email:${email}`;
            const clientsInRoom = io.sockets.adapter.rooms.get(room);
            
            if (clientsInRoom && clientsInRoom.size > 0) {
                io.to(room).emit('new-email', {
                    email,
                    message: emailData,
                    timestamp: Date.now(),
                    count: clientsInRoom.size
                });
                
                console.log(`📡 Broadcasted to ${clientsInRoom.size} clients for: ${email}`);
            }
        } catch (err) {
            console.error('Broadcast error:', err);
        }
    });
}

// High-performance email storage with batching
async function storeEmailOptimized(email, message) {
    return new Promise((resolve, reject) => {
        batchProcessor.add(async () => {
            let client;
            try {
                client = await connectionPool.getConnection();
                const redisKey = `inbox:${email}`;
                
                // Use pipeline for better performance
                const pipeline = client.multi();
                pipeline.lPush(redisKey, JSON.stringify(message));
                pipeline.expire(redisKey, 2592000); // 30 days TTL
                
                await pipeline.exec();
                
                // Broadcast real-time notification
                broadcastNewEmail(email, message);
                
                resolve();
            } catch (err) {
                reject(err);
            } finally {
                if (client) {
                    connectionPool.releaseConnection(client);
                }
            }
        });
    });
}

exports.register = function () {
    this.loginfo("🚀 Loading optimized TurboMail plugin");

    // Initialize Redis connection pool
    connectionPool.initialize()
        .then(() => {
            this.loginfo("✅ Redis connection pool initialized");
            
            // Initialize WebSocket server
            initializeWebSocketServer(this);
            
        })
        .catch(err => {
            this.logerror("❌ Redis pool initialization failed: " + err);
        });

    // Graceful shutdown
    process.on('SIGTERM', () => {
        this.loginfo("🔄 Graceful shutdown initiated");
        if (httpServer) {
            httpServer.close();
        }
        if (io) {
            io.close();
        }
    });
};

exports.hook_data_post = async function (next, connection) {
    const transaction = connection.transaction;
    const to = transaction.rcpt_to.map(r => r.address());
    const from = transaction.mail_from.address();
    
    // Handle multiple recipients efficiently
    const recipients = to.filter(email => email && email.includes('@'));
    
    if (recipients.length === 0) {
        connection.logwarn(this, '⚠️ No valid recipients found');
        return next();
    }

    const bufferStream = new PassThrough();
    transaction.message_stream.pipe(bufferStream);

    const chunks = [];
    let totalSize = 0;
    const maxSize = 10 * 1024 * 1024; // 10MB limit

    bufferStream.on('data', (chunk) => {
        totalSize += chunk.length;
        if (totalSize > maxSize) {
            connection.logerror(this, '❌ Email too large, rejecting');
            return next(DENY, 'Email size exceeds limit');
        }
        chunks.push(chunk);
    });

    bufferStream.on('end', async () => {
        try {
            const rawMessage = Buffer.concat(chunks).toString('utf8');
            const timestamp = Date.now();
            
            // Create optimized message object
            const baseMessage = {
                from,
                timestamp,
                content: rawMessage,
                size: totalSize,
                id: `${timestamp}-${Math.random().toString(36).substr(2, 9)}`
            };

            // Store for each recipient in parallel with error handling
            const storePromises = recipients.map(async (email) => {
                try {
                    const message = { ...baseMessage, to: [email] };
                    await storeEmailOptimized(email, message);
                    connection.loginfo(this, `📥 Stored for: ${email} (${totalSize} bytes)`);
                } catch (err) {
                    connection.logerror(this, `❌ Store failed for ${email}: ${err.message}`);
                }
            });

            // Wait for all storage operations with timeout
            await Promise.allSettled(storePromises);
            
            connection.loginfo(this, `✅ Processed email for ${recipients.length} recipients`);
            
        } catch (err) {
            connection.logerror(this, '❌ Email processing error: ' + err.message);
        }
        
        return next();
    });

    bufferStream.on('error', (err) => {
        connection.logerror(this, '❌ Stream error: ' + err.message);
        return next();
    });

    // Set timeout for email processing
    setTimeout(() => {
        if (!bufferStream.destroyed) {
            connection.logerror(this, '⏰ Email processing timeout');
            bufferStream.destroy();
            return next();
        }
    }, 30000); // 30 second timeout
};

// Health check endpoint
exports.hook_init_master = function () {
    this.loginfo("🏥 TurboMail health monitoring active");
    
    setInterval(() => {
        const memUsage = process.memoryUsage();
        const memMB = Math.round(memUsage.heapUsed / 1024 / 1024);
        
        if (memMB > 500) { // Alert if memory usage > 500MB
            this.logwarn(`⚠️ High memory usage: ${memMB}MB`);
        }
        
        // Log performance stats every 5 minutes
        this.loginfo(`📊 Memory: ${memMB}MB, Queue: ${batchProcessor.queue.length}, Connections: ${connectionPool.connections.length}`);
    }, 300000); // 5 minutes
};