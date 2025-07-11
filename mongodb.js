const { MongoClient, ServerApiVersion } = require('mongodb');

// MongoDB configuration
const mongoConfig = {
    uri: "mongodb+srv://turbomail:we1we2we3@turbomail.gjohjma.mongodb.net/turbomail?retryWrites=true&w=majority",
    options: {
        // Simplified configuration without strict serverApi to avoid SSL issues
        connectTimeoutMS: 10000,
        serverSelectionTimeoutMS: 5000,
    }
};

// Create MongoDB client
const client = new MongoClient(mongoConfig.uri, mongoConfig.options);

// Database and collection names
const DB_NAME = 'turbomail';
const COLLECTIONS = {
    EMAILS: 'emails',
    USERS: 'users',
    DOMAINS: 'domains',
    ANALYTICS: 'analytics'
};

// MongoDB connection manager
class MongoDBManager {
    constructor() {
        this.client = client;
        this.db = null;
        this.isConnected = false;
    }

    async connect() {
        try {
            console.log("🔄 Attempting to connect to MongoDB Atlas...");
            await this.client.connect();
            this.db = this.client.db(DB_NAME);
            
            // Test the connection
            await this.client.db("admin").command({ ping: 1 });
            this.isConnected = true;
            
            // Setup TTL indexes for automatic expiration
            await this.setupTTLIndexes();
            
            console.log("✅ Successfully connected to MongoDB Atlas!");
            return true;
        } catch (error) {
            console.error("❌ MongoDB connection failed:");
            console.error("Error type:", error.constructor.name);
            console.error("Error message:", error.message);
            
            // Check for common issues
            if (error.message.includes('SSL') || error.message.includes('TLS')) {
                console.error("💡 SSL/TLS Error - This might be due to:");
                console.error("   1. IP address not whitelisted in MongoDB Atlas");
                console.error("   2. Network connectivity issues");
                console.error("   3. MongoDB Atlas cluster configuration");
            }
            
            this.isConnected = false;
            return false;
        }
    }

    async disconnect() {
        try {
            await this.client.close();
            this.isConnected = false;
            console.log("🔌 Disconnected from MongoDB");
        } catch (error) {
            console.error("Error disconnecting from MongoDB:", error);
        }
    }

    getCollection(collectionName) {
        if (!this.isConnected || !this.db) {
            console.warn(`⚠️  MongoDB not connected - operation on ${collectionName} collection skipped`);
            throw new Error('MongoDB not connected');
        }
        return this.db.collection(collectionName);
    }

    // Check if MongoDB is connected
    isMongoConnected() {
        return this.isConnected;
    }

    // Setup TTL indexes for automatic document expiration
    async setupTTLIndexes() {
        try {
            if (!this.isConnected) return;
            
            // TTL will be handled by application logic, no automatic expiration
            // Only create TTL index on analytics collection (expire after 30 days)
            const analyticsCollection = this.getCollection(COLLECTIONS.ANALYTICS);
            await analyticsCollection.createIndex(
                { "timestamp": 1 },
                { expireAfterSeconds: 30 * 24 * 60 * 60 } // 30 days
            );
            
            console.log("✅ TTL indexes created successfully (analytics only)");
        } catch (error) {
            console.error("⚠️ Error creating TTL indexes:", error.message);
        }
    }

    // Email operations
    async saveEmail(emailData) {
        try {
            const collection = this.getCollection(COLLECTIONS.EMAILS);
            const result = await collection.insertOne({
                ...emailData,
                createdAt: new Date(),
                updatedAt: new Date()
            });
            return result;
        } catch (error) {
            console.error('Error saving email:', error);
            throw error;
        }
    }

    async getEmails(filter = {}, limit = 50, skip = 0) {
        try {
            const collection = this.getCollection(COLLECTIONS.EMAILS);
            const emails = await collection
                .find(filter)
                .sort({ createdAt: -1 })
                .limit(limit)
                .skip(skip)
                .toArray();
            return emails;
        } catch (error) {
            console.error('Error fetching emails:', error);
            throw error;
        }
    }

    async getEmailById(emailId) {
        try {
            const collection = this.getCollection(COLLECTIONS.EMAILS);
            const email = await collection.findOne({ _id: emailId });
            return email;
        } catch (error) {
            console.error('Error fetching email by ID:', error);
            throw error;
        }
    }

    async deleteEmail(emailId) {
        try {
            const collection = this.getCollection(COLLECTIONS.EMAILS);
            const result = await collection.deleteOne({ _id: emailId });
            return result;
        } catch (error) {
            console.error('Error deleting email:', error);
            throw error;
        }
    }

    // Analytics operations
    async saveAnalytics(analyticsData) {
        try {
            const collection = this.getCollection(COLLECTIONS.ANALYTICS);
            const result = await collection.insertOne({
                ...analyticsData,
                timestamp: new Date()
            });
            return result;
        } catch (error) {
            console.error('Error saving analytics:', error);
            throw error;
        }
    }

    async getAnalytics(filter = {}, limit = 100) {
        try {
            const collection = this.getCollection(COLLECTIONS.ANALYTICS);
            const analytics = await collection
                .find(filter)
                .sort({ timestamp: -1 })
                .limit(limit)
                .toArray();
            return analytics;
        } catch (error) {
            console.error('Error fetching analytics:', error);
            throw error;
        }
    }

    // Domain operations
    async saveDomain(domainData) {
        try {
            const collection = this.getCollection(COLLECTIONS.DOMAINS);
            const result = await collection.insertOne({
                ...domainData,
                createdAt: new Date()
            });
            return result;
        } catch (error) {
            console.error('Error saving domain:', error);
            throw error;
        }
    }

    async getDomains() {
        try {
            const collection = this.getCollection(COLLECTIONS.DOMAINS);
            const domains = await collection.find({}).toArray();
            return domains;
        } catch (error) {
            console.error('Error fetching domains:', error);
            throw error;
        }
    }

    // User Generated Email operations
    async saveGeneratedEmail(emailData) {
        try {
            const collection = this.getCollection('generated_emails');
            
            // TTL will be handled by lifetime, no expiration needed
            const ttlSeconds = emailData.ttl || 3600; // 1 hour default
            
            const result = await collection.insertOne({
                ...emailData,
                createdAt: emailData.createdAt || new Date(),
                ttl: ttlSeconds,
                isActive: emailData.isActive !== undefined ? emailData.isActive : true,
                updatedAt: new Date()
            });
            
            console.log(`📧 Email saved with TTL: ${ttlSeconds}s (lifetime based)`);
            return result;
        } catch (error) {
            console.error('Error saving generated email:', error);
            throw error;
        }
    }

    async getUserGeneratedEmails(filter = {}, limit = 50, skip = 0) {
        try {
            const collection = this.getCollection('generated_emails');
            const emails = await collection
                .find(filter)
                .sort({ createdAt: -1 })
                .limit(limit)
                .skip(skip)
                .toArray();
            return emails;
        } catch (error) {
            console.error('Error fetching user generated emails:', error);
            throw error;
        }
    }

    async updateGeneratedEmailStatus(emailId, isActive) {
        try {
            const collection = this.getCollection('generated_emails');
            const result = await collection.updateOne(
                { _id: emailId },
                { 
                    $set: { 
                        isActive: isActive,
                        updatedAt: new Date()
                    }
                }
            );
            return result;
        } catch (error) {
            console.error('Error updating generated email status:', error);
            throw error;
        }
    }

    async deleteGeneratedEmail(emailId) {
        try {
            const collection = this.getCollection('generated_emails');
            const result = await collection.deleteOne({ _id: emailId });
            return result;
        } catch (error) {
            console.error('Error deleting generated email:', error);
            throw error;
        }
    }

    async getActiveEmailForUser(deviceId) {
        try {
            const collection = this.getCollection('generated_emails');
            const email = await collection.findOne(
                { deviceId: deviceId, isActive: true },
                { sort: { createdAt: -1 } }
            );
            return email;
        } catch (error) {
            console.error('Error fetching active email for user:', error);
            throw error;
        }
    }

    // TTL and expiration management methods
    async extendEmailTTL(emailId, additionalSeconds = 3600) {
        try {
            const collection = this.getCollection('generated_emails');
            const email = await collection.findOne({ _id: emailId });
            
            if (!email) {
                throw new Error('Email not found');
            }
            
            const result = await collection.updateOne(
                { _id: emailId },
                { 
                    $set: { 
                        ttl: additionalSeconds,
                        updatedAt: new Date()
                    }
                }
            );
            
            console.log(`⏰ Email TTL extended to: ${additionalSeconds}s (lifetime based)`);
            return result;
        } catch (error) {
            console.error('Error extending email TTL:', error);
            throw error;
        }
    }

    async cleanupExpiredEmails() {
        try {
            const collection = this.getCollection('generated_emails');
            const now = new Date();
            
            // Cleanup based on TTL and creation time (lifetime based)
            const result = await collection.deleteMany({
                $expr: {
                    $lt: [
                        { $add: ["$createdAt", { $multiply: ["$ttl", 1000] }] },
                        now
                    ]
                }
            });
            
            if (result.deletedCount > 0) {
                console.log(`🗑️ Manually cleaned up ${result.deletedCount} expired emails (lifetime based)`);
            }
            
            return result;
        } catch (error) {
            console.error('Error cleaning up expired emails:', error);
            throw error;
        }
    }

    async deactivateExpiredEmails() {
        try {
            const collection = this.getCollection('generated_emails');
            const now = new Date();
            
            // Deactivate expired emails based on TTL and creation time (lifetime based)
            const result = await collection.updateMany(
                { 
                    $expr: {
                        $lt: [
                            { $add: ["$createdAt", { $multiply: ["$ttl", 1000] }] },
                            now
                        ]
                    },
                    isActive: true
                },
                { 
                    $set: { 
                        isActive: false,
                        deactivatedAt: now,
                        updatedAt: now
                    }
                }
            );
            
            if (result.modifiedCount > 0) {
                console.log(`⏸️ Deactivated ${result.modifiedCount} expired emails (lifetime based)`);
            }
            
            return result;
        } catch (error) {
            console.error('Error deactivating expired emails:', error);
            throw error;
        }
    }

    // Scheduled cleanup for expired emails
    startPeriodicCleanup(intervalMinutes = 30) {
        if (!this.isConnected) {
            console.log("⚠️ MongoDB not connected, skipping periodic cleanup setup");
            return;
        }
        
        const intervalMs = intervalMinutes * 60 * 1000;
        
        // Run cleanup immediately
        this.deactivateExpiredEmails();
        
        // Schedule periodic cleanup
        this.cleanupInterval = setInterval(async () => {
            try {
                await this.deactivateExpiredEmails();
                // Optional: Also run manual cleanup every 2 hours
                const now = new Date();
                if (now.getMinutes() === 0 && now.getHours() % 2 === 0) {
                    await this.cleanupExpiredEmails();
                }
            } catch (error) {
                console.error('Error in periodic cleanup:', error);
            }
        }, intervalMs);
        
        console.log(`🔄 Periodic email cleanup started (every ${intervalMinutes} minutes)`);
    }
    
    stopPeriodicCleanup() {
        if (this.cleanupInterval) {
            clearInterval(this.cleanupInterval);
            this.cleanupInterval = null;
            console.log("⏹️ Periodic email cleanup stopped");
        }
    }

    // Health check
    async healthCheck() {
        try {
            await this.client.db("admin").command({ ping: 1 });
            return { status: 'healthy', connected: this.isConnected };
        } catch (error) {
            return { status: 'unhealthy', connected: false, error: error.message };
        }
    }
}

// Create and export singleton instance
const mongoManager = new MongoDBManager();

module.exports = {
    mongoManager,
    COLLECTIONS,
    DB_NAME
};