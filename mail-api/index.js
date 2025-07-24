// index.js (Express + Redis + MongoDB + Secure API Key + Email API + Socket.IO)

const express = require('express');
const cors = require('cors');
const mongoose = require('mongoose');
const { createServer } = require('http');
const { Server } = require('socket.io');
const { simpleParser } = require('mailparser');
const { createClient } = require('redis');
const { MongoClient, ObjectId } = require('mongodb');
const { v4: uuidv4 } = require('uuid');
const path = require('path');
const crypto = require('crypto');
const config = require('../config');

const app = express();
const httpServer = createServer(app);
const io = new Server(httpServer, {
  cors: { origin: '*', methods: ['GET', 'POST', 'DELETE', 'PUT'] }
});

const PORT = config.API.PORT;
const MASTER_API_KEY = config.API.MASTER_KEY;
const ALLOWED_DOMAINS = config.API.ALLOWED_DOMAINS;

// MongoDB Atlas connection
const MONGODB_URI = 'mongodb+srv://turbomail:we1we2we3@turbomail.gjohjma.mongodb.net/?retryWrites=true&w=majority&appName=turbomail';
const DB_NAME = 'turbomail';

let mongoClient;
let db;

// Redis client
const redisClient = createClient({
  socket: { host: config.REDIS.HOST, port: config.REDIS.PORT }
});

redisClient.on('error', err => console.error('❌ Redis error:', err));
redisClient.connect().then(() => console.log('✅ Redis connected'));

// MongoDB connection
async function connectMongoDB() {
  try {
    mongoClient = new MongoClient(MONGODB_URI);
    await mongoClient.connect();
    db = mongoClient.db(DB_NAME);
    console.log('✅ MongoDB Atlas connected');
    
    // Create indexes for better performance
    await db.collection('generated_emails').createIndex({ email: 1 }, { unique: true });
    await db.collection('generated_emails').createIndex({ deviceId: 1 });
    await db.collection('generated_emails').createIndex({ createdAt: -1 });
    
    // Create indexes for ads and app updates
    await db.collection('ads_ios').createIndex({ _id: 1 });
    await db.collection('ads_android').createIndex({ _id: 1 });
    await db.collection('app_updates').createIndex({ version_code: -1 });
    await db.collection('app_updates').createIndex({ is_active: 1 });
    
    // Initialize default data if collections are empty
    await initializeDefaultData();
  } catch (error) {
    console.error('❌ MongoDB connection error:', error);
  }
}

// Initialize default data for ads and app updates
async function initializeDefaultData() {
  try {
    // Check and insert default iOS ads if collection is empty
    const iosAdsCount = await db.collection('ads_ios').countDocuments();
    if (iosAdsCount === 0) {
      await db.collection('ads_ios').insertOne({
        banner_ad_id: "ca-app-pub-ios/aaa",
        interstitial_ad_id: "ca-app-pub-ios/bbb",
        rewarded_ad_id: "ca-app-pub-ios/ccc",
        native_ad_id: "ca-app-pub-ios/ddd",
        app_open_ad_id: "ca-app-pub-ios/eee",
        created_at: new Date(),
        updated_at: new Date()
      });
      console.log('✅ Default iOS ads data inserted');
    }

    // Check and insert default Android ads if collection is empty
    const androidAdsCount = await db.collection('ads_android').countDocuments();
    if (androidAdsCount === 0) {
      await db.collection('ads_android').insertOne({
        banner_ad_id: "ca-app-pub-android/111",
        interstitial_ad_id: "ca-app-pub-android/222",
        rewarded_ad_id: "ca-app-pub-android/333",
        native_ad_id: "ca-app-pub-android/444",
        app_open_ad_id: "ca-app-pub-android/555",
        created_at: new Date(),
        updated_at: new Date()
      });
      console.log('✅ Default Android ads data inserted');
    }

    // Check and insert default app update if collection is empty
    const appUpdatesCount = await db.collection('app_updates').countDocuments();
    if (appUpdatesCount === 0) {
      await db.collection('app_updates').insertOne({
        version_name: "1.2.3",
        version_code: 123,
        is_force_update: true,
        is_normal_update: false,
        is_active: true,
        update_message: "Bug fixes and performance improvements.",
        update_link: "",
        created_at: new Date(),
        updated_at: new Date()
      });
      console.log('✅ Default app update data inserted');
    }
  } catch (error) {
    console.error('❌ Error initializing default data:', error);
  }
}

connectMongoDB();

app.use(express.json());
app.use(express.static(path.join(__dirname)));

// 🔐 API key middleware
app.use((req, res, next) => {
  const key = req.query.key;
  if (key !== MASTER_API_KEY) {
    return res.status(403).send('🔐 Invalid API key');
  }
  next();
});

// ✅ API root
app.get('/', (req, res) => {
  res.send('📡 TurboMail API + Socket.IO + MongoDB is live');
});

// ✅ 1. Generate random email with uniqueness check
app.get('/generate', async (req, res) => {
  const { deviceId } = req.query;
  if (!deviceId) {
    return res.status(400).send('❌ Device ID is required');
  }

  try {
    let email;
    let attempts = 0;
    const maxAttempts = 10;

    // Keep generating until we find a unique email
    do {
      const domain = ALLOWED_DOMAINS[Math.floor(Math.random() * ALLOWED_DOMAINS.length)];
      const user = crypto.randomBytes(5).toString('hex');
      email = `${user}@${domain}`;
      attempts++;
      
      if (attempts > maxAttempts) {
        return res.status(500).send('❌ Unable to generate unique email');
      }
    } while (await db.collection('generated_emails').findOne({ email }));

    // Store in MongoDB
    const emailDoc = {
      email,
      deviceId,
      type: 'random',
      isStarred: false,
      createdAt: new Date(),
      lastUsed: new Date()
    };

    await db.collection('generated_emails').insertOne(emailDoc);
    
    res.json({ email, deviceId });
  } catch (error) {
    console.error('❌ Generate random email error:', error);
    res.status(500).send('❌ Error generating email');
  }
});

// ✅ 2. Generate manual email with uniqueness check
app.get('/generate/manual', async (req, res) => {
  const { username, domain, deviceId } = req.query;
  
  if (!username || !domain || !deviceId || !ALLOWED_DOMAINS.includes(domain)) {
    return res.status(400).send('❌ Invalid username, domain, or device ID');
  }

  const email = `${username.toLowerCase()}@${domain}`;

  try {
    // Check if email already exists
    const existingEmail = await db.collection('generated_emails').findOne({ email });
    if (existingEmail) {
      return res.status(409).json({ 
        error: 'Email already exists', 
        message: 'This email is already taken. Please use a different name.' 
      });
    }

    // Check Redis for active sessions
    const key = `inbox:${email}`;
    const exists = await redisClient.exists(key);
    if (exists) {
      return res.status(409).json({ 
        error: 'Email already exists', 
        message: 'This email is currently active. Please use a different name.' 
      });
    }

    // Store in MongoDB
    const emailDoc = {
      email,
      deviceId,
      type: 'custom',
      username: username.toLowerCase(),
      domain,
      isStarred: false,
      createdAt: new Date(),
      lastUsed: new Date()
    };

    await db.collection('generated_emails').insertOne(emailDoc);
    
    res.json({ email, deviceId });
  } catch (error) {
    console.error('❌ Generate manual email error:', error);
    res.status(500).send('❌ Error generating email');
  }
});

// ✅ 3. View inbox messages
app.get('/inbox/:email', async (req, res) => {
  const email = req.params.email.toLowerCase();
  try {
    // Update last used time
    await db.collection('generated_emails').updateOne(
      { email },
      { $set: { lastUsed: new Date() } }
    );

    const messages = await redisClient.lRange(`inbox:${email}`, 0, -1);
    res.json(messages.map(msg => JSON.parse(msg)));
  } catch (err) {
    console.error('❌ Inbox fetch error:', err.message);
    res.status(500).send('Inbox error');
  }
});

// ✅ 4. Delete message or entire inbox
app.delete('/delete/:email/:index', async (req, res) => {
  const email = req.params.email.toLowerCase();
  const index = req.params.index;
  const key = `inbox:${email}`;
  try {
    if (index && index !== 'all') {
      const msgs = await redisClient.lRange(key, 0, -1);
      if (!msgs[index]) return res.status(404).send('❌ Message not found');
      await redisClient.lRem(key, 1, msgs[index]);
    } else {
      await redisClient.del(key);
    }
    res.send('🗑️ Deleted');
  } catch (err) {
    console.error('❌ Delete error:', err.message);
    res.status(500).send('Delete error');
  }
});

// ✅ 4b. Delete entire inbox
app.delete('/delete/:email', async (req, res) => {
  const email = req.params.email.toLowerCase();
  const key = `inbox:${email}`;
  try {
    await redisClient.del(key);
    res.send('🗑️ Inbox deleted');
  } catch (err) {
    console.error('❌ Delete error:', err.message);
    res.status(500).send('Delete error');
  }
});

// ✅ 5. Get email history for device
app.get('/history/:deviceId', async (req, res) => {
  const { deviceId } = req.params;
  const { page = 1, limit = 20 } = req.query;
  
  try {
    const skip = (page - 1) * limit;
    
    // Get emails sorted by starred first, then by creation date (newest first)
    const emails = await db.collection('generated_emails')
      .find({ deviceId })
      .sort({ isStarred: -1, createdAt: -1 })
      .skip(skip)
      .limit(parseInt(limit))
      .toArray();

    const total = await db.collection('generated_emails').countDocuments({ deviceId });
    
    res.json({
      emails,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / limit)
      }
    });
  } catch (error) {
    console.error('❌ History fetch error:', error);
    res.status(500).send('❌ Error fetching history');
  }
});

// ✅ 6. Toggle star status for email
app.put('/star/:email', async (req, res) => {
  const email = req.params.email.toLowerCase();
  const { isStarred } = req.body;
  
  try {
    const result = await db.collection('generated_emails').updateOne(
      { email },
      { $set: { isStarred: Boolean(isStarred) } }
    );
    
    if (result.matchedCount === 0) {
      return res.status(404).send('❌ Email not found');
    }
    
    res.json({ success: true, isStarred: Boolean(isStarred) });
  } catch (error) {
    console.error('❌ Star toggle error:', error);
    res.status(500).send('❌ Error updating star status');
  }
});

// ✅ 7. Get starred emails for device
app.get('/starred/:deviceId', async (req, res) => {
  const { deviceId } = req.params;
  
  try {
    const starredEmails = await db.collection('generated_emails')
      .find({ deviceId, isStarred: true })
      .sort({ createdAt: -1 })
      .toArray();
    
    res.json({ emails: starredEmails });
  } catch (error) {
    console.error('❌ Starred emails fetch error:', error);
    res.status(500).send('❌ Error fetching starred emails');
  }
});

// ✅ 8. Delete email from history
app.delete('/history/:email', async (req, res) => {
  const email = req.params.email.toLowerCase();
  const { deviceId } = req.query;
  
  try {
    // Delete from MongoDB
    const result = await db.collection('generated_emails').deleteOne({ email, deviceId });
    
    if (result.deletedCount === 0) {
      return res.status(404).send('❌ Email not found');
    }
    
    // Also delete from Redis if exists
    await redisClient.del(`inbox:${email}`);
    
    res.json({ success: true, message: 'Email deleted from history' });
  } catch (error) {
    console.error('❌ Delete from history error:', error);
    res.status(500).send('❌ Error deleting email from history');
  }
});

// ✅ 9. Check email availability
app.get('/check/:email', async (req, res) => {
  const email = req.params.email.toLowerCase();
  
  try {
    const existsInMongo = await db.collection('generated_emails').findOne({ email });
    const existsInRedis = await redisClient.exists(`inbox:${email}`);
    
    res.json({ 
      available: !existsInMongo && !existsInRedis,
      exists: Boolean(existsInMongo || existsInRedis)
    });
  } catch (error) {
    console.error('❌ Email check error:', error);
    res.status(500).send('❌ Error checking email availability');
  }
});

// Simple API Routes - Only 3 APIs to fetch all data
// ✅ Combined Ads API - Get all ads data (iOS and Android)
app.get('/api/ads', async (req, res) => {
  try {
    const iosAdsCollection = db.collection('ads_ios');
    const androidAdsCollection = db.collection('ads_android');
    
    const iosAds = await iosAdsCollection.findOne({});
    const androidAds = await androidAdsCollection.findOne({});
    
    res.json({
      success: true,
      data: {
        ios: iosAds || {
          banner_ad_id: '',
          interstitial_ad_id: '',
          rewarded_ad_id: '',
          native_ad_id: '',
          app_open_ad_id: ''
        },
        android: androidAds || {
          banner_ad_id: '',
          interstitial_ad_id: '',
          rewarded_ad_id: '',
          native_ad_id: '',
          app_open_ad_id: ''
        }
      }
    });
  } catch (error) {
    console.error('Error fetching ads:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// 1. iOS Ads API - Get all iOS ad IDs
app.get('/api/ios-ads', async (req, res) => {
  try {
    const adsCollection = db.collection('ads_ios');
    const ads = await adsCollection.findOne({});
    
    res.json({
      success: true,
      data: ads || {
        banner_ad_id: '',
        interstitial_ad_id: '',
        rewarded_ad_id: '',
        native_ad_id: '',
        app_open_ad_id: ''
      }
    });
  } catch (error) {
    console.error('Error fetching iOS ads:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// 2. Android Ads API - Get all Android ad IDs
app.get('/api/android-ads', async (req, res) => {
  try {
    const adsCollection = db.collection('ads_android');
    const ads = await adsCollection.findOne({});
    
    res.json({
      success: true,
      data: ads || {
        banner_ad_id: '',
        interstitial_ad_id: '',
        rewarded_ad_id: '',
        native_ad_id: '',
        app_open_ad_id: ''
      }
    });
  } catch (error) {
    console.error('Error fetching Android ads:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// 3. App Updates API - Get all app update data
app.get('/api/app-updates', async (req, res) => {
  try {
    const updatesCollection = db.collection('app_updates');
    const updates = await updatesCollection.find({}).sort({ created_at: -1 }).toArray();
    
    res.json({
      success: true,
      data: updates
    });
  } catch (error) {
    console.error('Error fetching app updates:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// ✅ Update iOS ads via GET method (for admin panel)
app.get('/ads/ios/update', async (req, res) => {
  try {
    const { banner_ad_id, interstitial_ad_id, rewarded_ad_id, native_ad_id, app_open_ad_id } = req.query;
    
    if (!banner_ad_id || !interstitial_ad_id || !rewarded_ad_id || !native_ad_id || !app_open_ad_id) {
      return res.status(400).json({ error: 'All ad IDs are required as query parameters' });
    }

    const updateData = {
      banner_ad_id,
      interstitial_ad_id,
      rewarded_ad_id,
      native_ad_id,
      app_open_ad_id,
      updated_at: new Date()
    };

    const result = await db.collection('ads_ios').updateOne(
      {},
      { $set: updateData },
      { upsert: true }
    );

    res.json({ success: true, message: 'iOS ads updated successfully', data: updateData });
  } catch (error) {
    console.error('❌ iOS ads update error:', error);
    res.status(500).send('❌ Error updating iOS ads');
  }
});

// ✅ Update Android ads via GET method (for admin panel)
app.get('/ads/android/update', async (req, res) => {
  try {
    const { banner_ad_id, interstitial_ad_id, rewarded_ad_id, native_ad_id, app_open_ad_id } = req.query;
    
    if (!banner_ad_id || !interstitial_ad_id || !rewarded_ad_id || !native_ad_id || !app_open_ad_id) {
      return res.status(400).json({ error: 'All ad IDs are required as query parameters' });
    }

    const updateData = {
      banner_ad_id,
      interstitial_ad_id,
      rewarded_ad_id,
      native_ad_id,
      app_open_ad_id,
      updated_at: new Date()
    };

    const result = await db.collection('ads_android').updateOne(
      {},
      { $set: updateData },
      { upsert: true }
    );

    res.json({ success: true, message: 'Android ads updated successfully', data: updateData });
  } catch (error) {
    console.error('❌ Android ads update error:', error);
    res.status(500).send('❌ Error updating Android ads');
  }
});

// ✅ Create new app update via GET method (for admin panel)
app.get('/app/updates/create', async (req, res) => {
  try {
    const { 
      version_name, 
      version_code, 
      is_force_update = 'false', 
      is_normal_update = 'true', 
      is_active = 'true', 
      update_message, 
      update_link = '' 
    } = req.query;
    
    if (!version_name || !version_code || !update_message) {
      return res.status(400).json({ error: 'version_name, version_code, and update_message are required' });
    }

    // If this update is being set as active, deactivate all others
    if (is_active === 'true') {
      await db.collection('app_updates').updateMany(
        {},
        { $set: { is_active: false, updated_at: new Date() } }
      );
    }

    const updateData = {
      version_name,
      version_code: parseInt(version_code),
      is_force_update: is_force_update === 'true',
      is_normal_update: is_normal_update === 'true',
      is_active: is_active === 'true',
      update_message,
      update_link: update_link || "",
      created_at: new Date(),
      updated_at: new Date()
    };

    const result = await db.collection('app_updates').insertOne(updateData);
    
    res.json({ 
      success: true, 
      message: 'App update created successfully', 
      id: result.insertedId,
      update: updateData
    });
  } catch (error) {
    console.error('❌ App update creation error:', error);
    res.status(500).send('❌ Error creating app update');
  }
});



// ✅ Haraka: POST raw mail + broadcast to inbox + store in MongoDB
app.post('/incoming/raw', express.raw({ type: '*/*', limit: config.EMAIL.MAX_MESSAGE_SIZE }), async (req, res) => {
  const to = req.query.to?.toLowerCase();
  const raw = req.body;
  if (!to || !raw) return res.status(400).send('❌ Missing recipient or body');

  try {
    const parsed = await simpleParser(raw);
    const email = {
      from: parsed.from?.text || null,
      subject: parsed.subject || '(no subject)',
      text: parsed.text || '',
      html: parsed.html || '',
      attachments: parsed.attachments?.map(a => ({
        filename: a.filename,
        contentType: a.contentType,
        size: a.size
      })) || [],
      date: parsed.date || new Date().toISOString(),
      to
    };

    // Store in Redis only (not in MongoDB)
    await redisClient.rPush(`inbox:${to}`, JSON.stringify(email));
    await redisClient.expire(`inbox:${to}`, config.EMAIL.EXPIRY_TIME);
    
    // Update last used time for the email
    await db.collection('generated_emails').updateOne(
      { email: to },
      { $set: { lastUsed: new Date() } }
    );
    
    io.to(to).emit('new_mail', email);
    console.log(`📥 Stored & emitted mail for ${to}`);
    res.sendStatus(200);
  } catch (err) {
    console.error('❌ Parsing failed:', err.message);
    res.status(500).send('Parse error');
  }
});

// ✅ WebSocket connection
io.on('connection', socket => {
  console.log('🔌 Socket connected');
  socket.on('subscribe', email => {
    socket.join(email.toLowerCase());
    console.log(`📡 Subscribed to inbox: ${email}`);
  });
});

// Graceful shutdown
process.on('SIGINT', async () => {
  console.log('🔄 Shutting down gracefully...');
  await redisClient.quit();
  await mongoClient?.close();
  process.exit(0);
});

httpServer.listen(PORT, () => {
  console.log(`🚀 Mail API with Socket.IO + MongoDB running on port ${PORT}`);
});
