const express = require('express');
const { MongoClient, ObjectId } = require('mongodb');
const MongoStore = require('connect-mongo');
const path = require('path');
const cors = require('cors');
const session = require('express-session');
const fs = require('fs').promises;

const config = require('../config');

const app = express();
const PORT = process.env.PORT || config.ADMIN.PORT;

// MongoDB Atlas connection - Hardcoded for VPS deployment
const MONGODB_URI = 'mongodb+srv://turbomail:we1we2we3@turbomail.gjohjma.mongodb.net/?retryWrites=true&w=majority&appName=turbomail';
const DB_NAME = 'turbomail';
let db;

console.log('🔗 Using MongoDB URI:', MONGODB_URI);

// File paths
const HARAKA_HOST_LIST = path.join(__dirname, '../haraka-server/config/host_list');
const MAIL_API_PATH = path.join(__dirname, '../mail-api/index.js');

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(express.static(path.join(__dirname, 'assets')));
app.use(session({
  secret: 'admin-secret-key',
  resave: false,
  saveUninitialized: false,
  store: MongoStore.create({
    mongoUrl: MONGODB_URI,
    dbName: DB_NAME,
    collectionName: 'admin_sessions'
  }),
  cookie: {
    maxAge: 24 * 60 * 60 * 1000 // 24 hours
  }
}));

// Set view engine
app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, 'views'));

// Connect to MongoDB Atlas
async function connectToMongoDB() {
  try {
    console.log('🔄 Attempting to connect to MongoDB Atlas...');
    console.log('🔗 Connection URI:', MONGODB_URI);
    
    const client = new MongoClient(MONGODB_URI);
    await client.connect();
    db = client.db(DB_NAME);
    console.log('✅ Connected to MongoDB Atlas');
    
    // Test the connection
    await db.admin().ping();
    console.log('✅ MongoDB Atlas connection verified');
    
    // Create indexes for better performance
    await db.collection('ads_ios').createIndex({ _id: 1 });
    await db.collection('ads_android').createIndex({ _id: 1 });
    await db.collection('app_updates').createIndex({ version_code: -1 });
    await db.collection('app_updates').createIndex({ is_active: 1 });
    
    // Initialize collections if they don't exist
    await initializeCollections();
  } catch (error) {
    console.error('❌ MongoDB connection error:', error);
    console.error('❌ Error details:', error.message);
    console.error('❌ Please check your MongoDB Atlas connection string and network access');
    // Retry connection after 5 seconds
    console.log('🔄 Retrying connection in 5 seconds...');
    setTimeout(connectToMongoDB, 5000);
  }
}

// Initialize collections with default data
async function initializeCollections() {
  try {
    // Initialize iOS ads collection
    const iosAdsCount = await db.collection('ads_ios').countDocuments();
    if (iosAdsCount === 0) {
      await db.collection('ads_ios').insertOne({
        banner_ad_id: 'ca-app-pub-ios/banner',
        interstitial_ad_id: 'ca-app-pub-ios/interstitial',
        rewarded_ad_id: 'ca-app-pub-ios/rewarded',
        native_ad_id: 'ca-app-pub-ios/native',
        app_open_ad_id: 'ca-app-pub-ios/app-open',
        created_at: new Date(),
        updated_at: new Date()
      });
    }

    // Initialize Android ads collection
    const androidAdsCount = await db.collection('ads_android').countDocuments();
    if (androidAdsCount === 0) {
      await db.collection('ads_android').insertOne({
        banner_ad_id: 'ca-app-pub-android/banner',
        interstitial_ad_id: 'ca-app-pub-android/interstitial',
        rewarded_ad_id: 'ca-app-pub-android/rewarded',
        native_ad_id: 'ca-app-pub-android/native',
        app_open_ad_id: 'ca-app-pub-android/app-open',
        created_at: new Date(),
        updated_at: new Date()
      });
    }

    console.log('✅ Collections initialized');
  } catch (error) {
    console.error('❌ Error initializing collections:', error);
  }
}

// Simple auth middleware
const requireAuth = (req, res, next) => {
  if (req.session.authenticated) {
    next();
  } else {
    res.redirect('/login');
  }
};

// Routes
app.get('/login', (req, res) => {
  res.render('login', { error: null });
});

app.post('/login', async (req, res) => {
  const { username, password } = req.body;
  // Simple hardcoded admin credentials (change in production)
  if (username === config.ADMIN.USERNAME && password === config.ADMIN.PASSWORD) {
    req.session.authenticated = true;
    res.redirect('/dashboard');
  } else {
    res.render('login', { error: 'Invalid credentials' });
  }
});

app.get('/logout', (req, res) => {
  req.session.destroy();
  res.redirect('/login');
});

app.get('/', requireAuth, (req, res) => {
  res.redirect('/dashboard');
});

app.get('/dashboard', requireAuth, (req, res) => {
  res.render('dashboard');
});

// Database Management Routes
app.get('/database', requireAuth, async (req, res) => {
  try {
    // Check if database connection exists
    if (!db) {
      throw new Error('Database connection not established. Please check MongoDB Atlas connection.');
    }

    // Get iOS ads
    const iosAds = await db.collection('ads_ios').findOne({});
    
    // Get Android ads
    const androidAds = await db.collection('ads_android').findOne({});
    
    // Get app updates
    const appUpdates = await db.collection('app_updates').find({}).sort({ created_at: -1 }).toArray();
    
    console.log('✅ Database data retrieved successfully');
    console.log('iOS Ads:', iosAds ? 'Found' : 'Not found');
    console.log('Android Ads:', androidAds ? 'Found' : 'Not found');
    console.log('App Updates:', appUpdates.length, 'found');
    
    res.render('database', { 
      iosAds: iosAds || {
        banner_ad_id: '',
        interstitial_ad_id: '',
        rewarded_ad_id: '',
        native_ad_id: '',
        app_open_ad_id: ''
      },
      androidAds: androidAds || {
        banner_ad_id: '',
        interstitial_ad_id: '',
        rewarded_ad_id: '',
        native_ad_id: '',
        app_open_ad_id: ''
      },
      appUpdates,
      success: req.query.success || null,
      error: req.query.error || null
    });
  } catch (error) {
    console.error('❌ Database route error:', error);
    res.render('database', { 
      iosAds: {
        banner_ad_id: '',
        interstitial_ad_id: '',
        rewarded_ad_id: '',
        native_ad_id: '',
        app_open_ad_id: ''
      },
      androidAds: {
        banner_ad_id: '',
        interstitial_ad_id: '',
        rewarded_ad_id: '',
        native_ad_id: '',
        app_open_ad_id: ''
      },
      appUpdates: [],
      success: null,
      error: error.message
    });
  }
});

// Update iOS Ads
app.post('/database/ios-ads/update', requireAuth, async (req, res) => {
  try {
    // Check if database connection exists
    if (!db) {
      throw new Error('Database connection not established');
    }

    const { banner_ad_id, interstitial_ad_id, rewarded_ad_id, native_ad_id, app_open_ad_id } = req.body;
    
    // Validate required fields
    if (!banner_ad_id || !interstitial_ad_id || !rewarded_ad_id || !native_ad_id || !app_open_ad_id) {
      throw new Error('All ad ID fields are required');
    }
    
    const result = await db.collection('ads_ios').updateOne(
      {},
      {
        $set: {
          banner_ad_id,
          interstitial_ad_id,
          rewarded_ad_id,
          native_ad_id,
          app_open_ad_id,
          updated_at: new Date()
        }
      },
      { upsert: true }
    );
    
    console.log('✅ iOS ads updated successfully:', result);
    res.redirect('/database?success=' + encodeURIComponent('iOS ads updated successfully'));
  } catch (error) {
    console.error('❌ iOS ads update error:', error);
    res.redirect('/database?error=' + encodeURIComponent(error.message));
  }
});

// Update Android Ads
app.post('/database/android-ads/update', requireAuth, async (req, res) => {
  try {
    // Check if database connection exists
    if (!db) {
      throw new Error('Database connection not established');
    }

    const { banner_ad_id, interstitial_ad_id, rewarded_ad_id, native_ad_id, app_open_ad_id } = req.body;
    
    // Validate required fields
    if (!banner_ad_id || !interstitial_ad_id || !rewarded_ad_id || !native_ad_id || !app_open_ad_id) {
      throw new Error('All ad ID fields are required');
    }
    
    const result = await db.collection('ads_android').updateOne(
      {},
      {
        $set: {
          banner_ad_id,
          interstitial_ad_id,
          rewarded_ad_id,
          native_ad_id,
          app_open_ad_id,
          updated_at: new Date()
        }
      },
      { upsert: true }
    );
    
    console.log('✅ Android ads updated successfully:', result);
    res.redirect('/database?success=' + encodeURIComponent('Android ads updated successfully'));
  } catch (error) {
    console.error('❌ Android ads update error:', error);
    res.redirect('/database?error=' + encodeURIComponent(error.message));
  }
});

// Create App Update
app.post('/database/app-updates/create', requireAuth, async (req, res) => {
  try {
    const { version_name, version_code, update_message, is_force_update, is_active } = req.body;
    
    // Check if version code already exists
    const existingUpdate = await db.collection('app_updates').findOne({ 
      version_code: parseInt(version_code) 
    });
    
    if (existingUpdate) {
      return res.redirect('/database?error=' + encodeURIComponent('Version code already exists'));
    }

    // If this is set to active, deactivate all other updates
    if (is_active === 'on') {
      await db.collection('app_updates').updateMany(
        { is_active: true },
        { $set: { is_active: false } }
      );
    }

    const newUpdate = {
      version_name,
      version_code: parseInt(version_code),
      update_message,
      is_force_update: is_force_update === 'on',
      is_active: is_active === 'on',
      created_at: new Date()
    };

    await db.collection('app_updates').insertOne(newUpdate);
    
    res.redirect('/database?success=App update created successfully');
  } catch (error) {
    res.redirect('/database?error=' + encodeURIComponent(error.message));
  }
});

// Delete App Update
app.post('/database/app-updates/delete/:id', requireAuth, async (req, res) => {
  try {
    const { id } = req.params;
    
    await db.collection('app_updates').deleteOne({ _id: new ObjectId(id) });
    
    res.redirect('/database?success=App update deleted successfully');
  } catch (error) {
    res.redirect('/database?error=' + encodeURIComponent(error.message));
  }
});

// Toggle App Update Active Status
app.post('/database/app-updates/toggle/:id', requireAuth, async (req, res) => {
  try {
    const { id } = req.params;
    
    const update = await db.collection('app_updates').findOne({ _id: new ObjectId(id) });
    
    if (!update) {
      return res.redirect('/database?error=' + encodeURIComponent('App update not found'));
    }

    // If setting to active, deactivate all others
    if (!update.is_active) {
      await db.collection('app_updates').updateMany(
        { is_active: true },
        { $set: { is_active: false } }
      );
    }

    await db.collection('app_updates').updateOne(
      { _id: new ObjectId(id) },
      { $set: { is_active: !update.is_active } }
    );
    
    res.redirect('/database?success=App update status updated successfully');
  } catch (error) {
    res.redirect('/database?error=' + encodeURIComponent(error.message));
  }
});

// Domain Management
app.get('/domains', requireAuth, async (req, res) => {
  try {
    const domains = await fs.readFile(HARAKA_HOST_LIST, 'utf8');
    const domainList = domains.trim().split('\n').filter(d => d.trim());
    res.render('domains', { domains: domainList, success: null, error: null });
  } catch (error) {
    res.render('domains', { domains: [], success: null, error: 'Failed to load domains' });
  }
});

app.post('/domains/add', requireAuth, async (req, res) => {
  try {
    const { domain } = req.body;
    if (!domain || !domain.trim()) {
      throw new Error('Domain cannot be empty');
    }
    
    const domains = await fs.readFile(HARAKA_HOST_LIST, 'utf8');
    const domainList = domains.trim().split('\n').filter(d => d.trim());
    
    if (domainList.includes(domain.trim())) {
      throw new Error('Domain already exists');
    }
    
    domainList.push(domain.trim());
    await fs.writeFile(HARAKA_HOST_LIST, domainList.join('\n') + '\n');
    
    // Update mail-api allowed domains
    await updateMailApiDomains(domainList);
    
    res.render('domains', { 
      domains: domainList, 
      success: 'Domain added successfully', 
      error: null 
    });
  } catch (error) {
    const domains = await fs.readFile(HARAKA_HOST_LIST, 'utf8');
    const domainList = domains.trim().split('\n').filter(d => d.trim());
    res.render('domains', { 
      domains: domainList, 
      success: null, 
      error: error.message 
    });
  }
});

app.post('/domains/delete', requireAuth, async (req, res) => {
  try {
    const { domain } = req.body;
    const domains = await fs.readFile(HARAKA_HOST_LIST, 'utf8');
    const domainList = domains.trim().split('\n').filter(d => d.trim() && d.trim() !== domain);
    
    await fs.writeFile(HARAKA_HOST_LIST, domainList.join('\n') + '\n');
    
    // Update mail-api allowed domains
    await updateMailApiDomains(domainList);
    
    res.render('domains', { 
      domains: domainList, 
      success: 'Domain deleted successfully', 
      error: null 
    });
  } catch (error) {
    const domains = await fs.readFile(HARAKA_HOST_LIST, 'utf8');
    const domainList = domains.trim().split('\n').filter(d => d.trim());
    res.render('domains', { 
      domains: domainList, 
      success: null, 
      error: error.message 
    });
  }
});

// API Management
app.get('/api-management', requireAuth, async (req, res) => {
  try {
    const masterApiKey = await getApiKey();
    const apiEndpoints = [
      { name: 'Generate Random Email', endpoint: '/generate', method: 'GET' },
      { name: 'Generate Manual Email', endpoint: '/generate/manual', method: 'GET' },
      { name: 'View Inbox', endpoint: '/inbox/:email', method: 'GET' },
      { name: 'Delete Message/Inbox', endpoint: '/delete/:email/:index?', method: 'DELETE' }
    ];
    res.render('api-management', { 
      masterApiKey: masterApiKey || 'tempmail-master-key-2024', 
      apiEndpoints, 
      success: null, 
      error: null 
    });
  } catch (error) {
    const apiEndpoints = [
      { name: 'Generate Random Email', endpoint: '/generate', method: 'GET' },
      { name: 'Generate Manual Email', endpoint: '/generate/manual', method: 'GET' },
      { name: 'View Inbox', endpoint: '/inbox/:email', method: 'GET' },
      { name: 'Delete Message/Inbox', endpoint: '/delete/:email/:index?', method: 'DELETE' }
    ];
    res.render('api-management', { 
      masterApiKey: 'tempmail-master-key-2024', 
      apiEndpoints, 
      success: null, 
      error: error.message 
    });
  }
});

app.post('/api-key/update', requireAuth, async (req, res) => {
  try {
    const { apiKey } = req.body;
    
    if (!apiKey || !apiKey.trim()) {
      throw new Error('API Key cannot be empty');
    }
    
    // Update API key across all components
    await updateApiKey(apiKey);
    
    const masterApiKey = await getApiKey();
    const apiEndpoints = [
      { name: 'Generate Random Email', endpoint: '/generate', method: 'GET' },
      { name: 'Generate Manual Email', endpoint: '/generate/manual', method: 'GET' },
      { name: 'View Inbox', endpoint: '/inbox/:email', method: 'GET' },
      { name: 'Delete Message/Inbox', endpoint: '/delete/:email/:index?', method: 'DELETE' }
    ];
    
    const successMessage = `
      🎉 Master API Key updated successfully!<br>
      <strong>Updated Components:</strong><br>
      ✅ config.js (Main Configuration)<br>
      ✅ mail-api/index.js (Mail API)<br>
      ✅ haraka-server/plugins/forward_to_api.js (Haraka Plugin)<br>
      ✅ ecosystem.config.json (PM2 Configuration)<br>
      <br>
      <strong>New API Key:</strong> <code>${apiKey}</code><br>
      <em>Note: Restart services to apply changes in production.</em>
    `;
    
    res.render('api-management', { 
      masterApiKey: masterApiKey || apiKey, 
      apiEndpoints, 
      success: successMessage, 
      error: null 
    });
  } catch (error) {
    const masterApiKey = await getApiKey();
    const apiEndpoints = [
      { name: 'Generate Random Email', endpoint: '/generate', method: 'GET' },
      { name: 'Generate Manual Email', endpoint: '/generate/manual', method: 'GET' },
      { name: 'View Inbox', endpoint: '/inbox/:email', method: 'GET' },
      { name: 'Delete Message/Inbox', endpoint: '/delete/:email/:index?', method: 'DELETE' }
    ];
    res.render('api-management', { 
      masterApiKey: masterApiKey || 'tempmail-master-key-2024', 
      apiEndpoints, 
      success: null, 
      error: `❌ Failed to update API key: ${error.message}` 
    });
  }
});







// Helper functions
async function getApiKey() {
  try {
    // Read from config file first
    const configPath = path.join(__dirname, '../config.js');
    delete require.cache[require.resolve('../config')]; // Clear cache to get fresh config
    const freshConfig = require('../config');
    return freshConfig.API.MASTER_KEY;
  } catch (error) {
    console.error('Error reading API key from config:', error);
    return config.API.MASTER_KEY; // Fallback to initial config
  }
}

async function updateApiKey(newKey) {
  try {
    if (!newKey || !newKey.trim()) {
      throw new Error('API Key cannot be empty');
    }
    
    console.log(`🔑 Updating API key to: ${newKey.trim()}`);
    
    // 1. Update config.js file (main configuration)
    const configPath = path.join(__dirname, '../config.js');
    let content = await fs.readFile(configPath, 'utf8');
    
    // Replace the MASTER_KEY value in the config file
    content = content.replace(
      /MASTER_KEY:\s*['"`].*?['"`]/,
      `MASTER_KEY: '${newKey.trim()}'`
    );
    
    await fs.writeFile(configPath, content);
    console.log('✅ Updated config.js');
    
    // 2. Update mail-api file for backward compatibility
    let apiContent = await fs.readFile(MAIL_API_PATH, 'utf8');
    apiContent = apiContent.replace(
      /const MASTER_API_KEY = ['"`].*?['"`]/,
      `const MASTER_API_KEY = config.API.MASTER_KEY`
    );
    await fs.writeFile(MAIL_API_PATH, apiContent);
    console.log('✅ Updated mail-api/index.js');
    
    // 3. Update Haraka plugin to ensure it uses the config
    const harakaPluginPath = path.join(__dirname, '../haraka-server/plugins/forward_to_api.js');
    let harakaContent = await fs.readFile(harakaPluginPath, 'utf8');
    
    // Ensure the plugin is using config.API.MASTER_KEY
    if (!harakaContent.includes('config.API.MASTER_KEY')) {
      harakaContent = harakaContent.replace(
        /key=[^&}]+/g,
        'key=${config.API.MASTER_KEY}'
      );
      await fs.writeFile(harakaPluginPath, harakaContent);
      console.log('✅ Updated Haraka plugin');
    }
    
    // 4. Update ecosystem.config.json environment variables
    const ecosystemPath = path.join(__dirname, '../ecosystem.config.json');
    try {
      let ecosystemContent = await fs.readFile(ecosystemPath, 'utf8');
      const ecosystem = JSON.parse(ecosystemContent);
      
      // Update environment variables for all apps
      ecosystem.apps.forEach(app => {
        if (!app.env) app.env = {};
        app.env.API_MASTER_KEY = newKey.trim();
      });
      
      await fs.writeFile(ecosystemPath, JSON.stringify(ecosystem, null, 2));
      console.log('✅ Updated ecosystem.config.json');
    } catch (error) {
      console.log('⚠️ Could not update ecosystem.config.json:', error.message);
    }
    
    // 5. Clear require cache to ensure fresh config is loaded
    delete require.cache[require.resolve('../config')];
    
    console.log('🎉 API key updated successfully across all components!');
    
  } catch (error) {
    console.error('❌ Error updating API key:', error);
    throw error;
  }
}

async function updateMailApiDomains(domains) {
  try {
    // Update config.js file
    const configPath = path.join(__dirname, '../config.js');
    let content = await fs.readFile(configPath, 'utf8');
    
    const domainsString = domains.map(d => `'${d}'`).join(', ');
    content = content.replace(
      /ALLOWED_DOMAINS:\s*\[.*?\]/s,
      `ALLOWED_DOMAINS: [${domainsString}]`
    );
    
    await fs.writeFile(configPath, content);
    
    // Also update the mail-api file for backward compatibility
    let apiContent = await fs.readFile(MAIL_API_PATH, 'utf8');
    apiContent = apiContent.replace(
      /const ALLOWED_DOMAINS = \[.*?\]/s,
      `const ALLOWED_DOMAINS = config.API.ALLOWED_DOMAINS`
    );
    await fs.writeFile(MAIL_API_PATH, apiContent);
    
  } catch (error) {
    console.error('Error updating domains in config:', error);
  }
}

app.listen(PORT, '0.0.0.0', async () => {
  console.log(`🚀 Admin Panel running on http://0.0.0.0:${PORT}`);
  await connectToMongoDB();
});