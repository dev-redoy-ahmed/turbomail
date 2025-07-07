const { MongoClient, ServerApiVersion } = require('mongodb');

// MongoDB configuration
const mongoConfig = {
    uri: "mongodb+srv://turbomail:we1we2we3@turbomail.gjohjma.mongodb.net/turbomail?retryWrites=true&w=majority",
    options: {
        // Simplified options without strict serverApi
    }
};

async function testMongoConnection() {
    console.log('🔄 Testing MongoDB connection...');
    
    const client = new MongoClient(mongoConfig.uri, mongoConfig.options);
    
    try {
        console.log('🔗 Attempting to connect to MongoDB...');
        await client.connect();
        
        console.log('📡 Testing ping command...');
        await client.db("admin").command({ ping: 1 });
        
        console.log('✅ MongoDB connection test successful!');
        
        // Test database access
        const db = client.db('turbomail');
        const collections = await db.listCollections().toArray();
        console.log('📂 Available collections:', collections.map(c => c.name));
        
    } catch (error) {
        console.error('❌ MongoDB connection test failed:');
        console.error('Error message:', error.message);
        console.error('Error code:', error.code);
        console.error('Full error:', error);
    } finally {
        await client.close();
        console.log('🔌 Connection closed');
    }
}

testMongoConnection();