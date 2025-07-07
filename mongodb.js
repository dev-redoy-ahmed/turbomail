const { MongoClient, ServerApiVersion } = require('mongodb');

// MongoDB configuration
const mongoConfig = {
    uri: "mongodb+srv://turbomail:we1we2we3@turbomail.gjohjma.mongodb.net/?retryWrites=true&w=majority&appName=turbomail",
    options: {
        serverApi: {
            version: ServerApiVersion.v1,
            strict: true,
            deprecationErrors: true,
        }
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
            await this.client.connect();
            this.db = this.client.db(DB_NAME);
            
            // Test the connection
            await this.client.db("admin").command({ ping: 1 });
            this.isConnected = true;
            
            console.log("✅ Successfully connected to MongoDB!");
            return true;
        } catch (error) {
            console.error("❌ MongoDB connection failed:", error);
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
            throw new Error('MongoDB not connected');
        }
        return this.db.collection(collectionName);
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
            const result = await collection.insertOne({
                ...emailData,
                createdAt: emailData.createdAt || new Date()
            });
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