const express = require('express');
const bodyParser = require('body-parser');
const session = require('express-session');
const fs = require('fs-extra');
const path = require('path');
const bcrypt = require('bcryptjs');
const mongoose = require('mongoose');
require('dotenv').config();
const config = require('../config');

// Import models
const AdsConfig = require('./models/AdsConfig');
const AppUpdate = require('./models/AppUpdate');

const app = express();
const PORT = config.ADMIN.PORT;

// Paths
const HARAKA_HOST_LIST = path.join(__dirname, '../haraka-server/config/host_list');
const MAIL_API_PATH = path.join(__dirname, '../mail-api/index.js');

// Middleware
app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, 'views'));
app.use(express.static(path.join(__dirname, 'assets')));
app.use(bodyParser.urlencoded({ extended: true }));
app.use(bodyParser.json());
app.use(session({
  secret: 'temp-mail-admin-secret-key',
  resave: false,
  saveUninitialized: false,
  cookie: { secure: false }
}));

// MongoDB Connection
const MONGO_URI = process.env.MONGO_URI || 'mongodb+srv://turbomail:we1we2we3@turbomail.gjohjma.mongodb.net/?retryWrites=true&w=majority&appName=turbomail';
mongoose.connect(MONGO_URI, {
  useNewUrlParser: true,
  useUnifiedTopology: true,
})
.then(() => {
  console.log('✅ Connected to MongoDB');
})
.catch((error) => {
  console.error('❌ MongoDB connection error:', error);
});

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

// Ads Management Routes
app.get('/ads-management', requireAuth, async (req, res) => {
  try {
    const adsConfig = await AdsConfig.getAllAdsConfig();
    const mongoUri = process.env.MONGO_URI || '';
    const adsEnabled = true; // You can make this configurable
    
    res.render('ads-management', { 
      adsConfig, 
      mongoUri,
      adsEnabled,
      success: null, 
      error: null 
    });
  } catch (error) {
    console.error('Error loading ads management:', error);
    res.render('ads-management', { 
      adsConfig: { 
        android: {
          banner: { id: '', description: '', isActive: false },
          interstitial: { id: '', description: '', isActive: false },
          native: { id: '', description: '', isActive: false },
          appopen: { id: '', description: '', isActive: false },
          reward: { id: '', description: '', isActive: false }
        },
        ios: {
          banner: { id: '', description: '', isActive: false },
          interstitial: { id: '', description: '', isActive: false },
          native: { id: '', description: '', isActive: false },
          appopen: { id: '', description: '', isActive: false },
          reward: { id: '', description: '', isActive: false }
        }
      }, 
      mongoUri: '',
      adsEnabled: false,
      success: null, 
      error: `Failed to load ads configuration: ${error.message}` 
    });
  }
});

app.post('/ads-management/update', requireAuth, async (req, res) => {
  try {
    const { platform, banner, interstitial, native, appopen, reward } = req.body;
    
    if (!platform) {
      throw new Error('Platform is required');
    }
    
    // Validate platform
    if (!['android', 'ios'].includes(platform)) {
      throw new Error('Platform must be either android or ios');
    }
    
    const adTypes = { banner, interstitial, native, appopen, reward };
    const updatedAds = [];
    
    // Update each ad type for the platform
    for (const [adType, adId] of Object.entries(adTypes)) {
      if (adId && adId.trim()) {
        // Validate ad ID format (basic AdMob format check)
        const adIdPattern = /^ca-app-pub-\d{16}\/\d{10}$/;
        if (!adIdPattern.test(adId.trim())) {
          throw new Error(`Invalid ${adType} Ad ID format. Please use format: ca-app-pub-xxxxxxxxxxxxxxxx/xxxxxxxxxx`);
        }
        
        await AdsConfig.updateAdConfig(adType, platform, adId.trim(), {
          description: '',
          isActive: true
        });
        updatedAds.push(adType);
      }
    }
    
    // Get updated data
    const adsConfig = await AdsConfig.getAllAdsConfig();
    
    res.render('ads-management', { 
      adsConfig, 
      mongoUri: process.env.MONGO_URI || '',
      adsEnabled: true,
      success: `✅ ${platform.toUpperCase()} ads updated successfully! Updated: ${updatedAds.join(', ')}`, 
      error: null 
    });
  } catch (error) {
    console.error('Error updating ad config:', error);
    
    // Get current data for error response
    try {
      const adsConfig = await AdsConfig.getAllAdsConfig();
      res.render('ads-management', { 
        adsConfig, 
        mongoUri: process.env.MONGO_URI || '',
        adsEnabled: true,
        success: null, 
        error: `❌ Failed to update ads: ${error.message}` 
      });
    } catch (getError) {
      res.render('ads-management', { 
        adsConfig: { 
          android: {
            banner: { id: '', description: '', isActive: false },
            interstitial: { id: '', description: '', isActive: false },
            native: { id: '', description: '', isActive: false },
            appopen: { id: '', description: '', isActive: false },
            reward: { id: '', description: '', isActive: false }
          },
          ios: {
            banner: { id: '', description: '', isActive: false },
            interstitial: { id: '', description: '', isActive: false },
            native: { id: '', description: '', isActive: false },
            appopen: { id: '', description: '', isActive: false },
            reward: { id: '', description: '', isActive: false }
          }
        }, 
        mongoUri: process.env.MONGO_URI || '',
        adsEnabled: true,
        success: null, 
        error: `❌ Failed to update ads: ${error.message}` 
      });
    }
  }
});

app.post('/ads-management/settings', requireAuth, async (req, res) => {
  try {
    const { mongoUri, adsEnabled } = req.body;
    
    // Update environment variables or config file
    if (mongoUri && mongoUri.trim()) {
      // You can save this to a config file or environment
      process.env.MONGO_URI = mongoUri.trim();
    }
    
    // Get updated data
    const adsConfig = await AdsConfig.getAllAdsConfig();
    
    res.render('ads-management', { 
      adsConfig, 
      mongoUri: mongoUri || process.env.MONGO_URI || '',
      adsEnabled: adsEnabled === 'true',
      success: '✅ Settings updated successfully!', 
      error: null 
    });
  } catch (error) {
    console.error('Error updating settings:', error);
    
    res.render('ads-management', { 
      adsConfig: { 
        android: {
          banner: { id: '', description: '', isActive: false },
          interstitial: { id: '', description: '', isActive: false },
          native: { id: '', description: '', isActive: false },
          appopen: { id: '', description: '', isActive: false },
          reward: { id: '', description: '', isActive: false }
        },
        ios: {
          banner: { id: '', description: '', isActive: false },
          interstitial: { id: '', description: '', isActive: false },
          native: { id: '', description: '', isActive: false },
          appopen: { id: '', description: '', isActive: false },
          reward: { id: '', description: '', isActive: false }
        }
      }, 
      mongoUri: process.env.MONGO_URI || '',
      adsEnabled: false,
      success: null, 
      error: `❌ Failed to update settings: ${error.message}` 
    });
  }
});

// App Updates Management Routes
app.get('/app-updates', requireAuth, async (req, res) => {
  try {
    const updates = await AppUpdate.getAllUpdates();
    res.render('app-updates', { 
      updates, 
      success: null, 
      error: null 
    });
  } catch (error) {
    console.error('Error loading app updates:', error);
    res.render('app-updates', { 
      updates: [], 
      success: null, 
      error: error.message 
    });
  }
});

app.post('/app-updates/create', requireAuth, async (req, res) => {
  try {
    const { version_name, version_code, update_message, update_link, is_force_update, is_normal_update, is_active } = req.body;
    
    if (!version_name || !version_code) {
      throw new Error('Version name and version code are required');
    }
    
    const updateData = {
      version_name: version_name.trim(),
      version_code: parseInt(version_code),
      update_message: update_message || 'A new version is available. Please update for the best experience.',
      update_link: update_link || 'https://example.com/app-download',
      is_force_update: is_force_update === 'true',
      is_normal_update: is_normal_update === 'true',
      is_active: is_active === 'true'
    };
    
    await AppUpdate.createOrUpdateVersion(updateData);
    
    const updates = await AppUpdate.getAllUpdates();
    res.render('app-updates', { 
      updates, 
      success: `✅ App version ${version_name} created successfully!`, 
      error: null 
    });
  } catch (error) {
    console.error('Error creating app update:', error);
    const updates = await AppUpdate.getAllUpdates();
    res.render('app-updates', { 
      updates, 
      success: null, 
      error: `❌ Failed to create app update: ${error.message}` 
    });
  }
});

app.post('/app-updates/activate', requireAuth, async (req, res) => {
  try {
    const { version_code } = req.body;
    
    if (!version_code) {
      throw new Error('Version code is required');
    }
    
    const activatedVersion = await AppUpdate.activateVersion(parseInt(version_code));
    
    if (!activatedVersion) {
      throw new Error('Version not found');
    }
    
    const updates = await AppUpdate.getAllUpdates();
    res.render('app-updates', { 
      updates, 
      success: `✅ Version ${activatedVersion.version_name} activated successfully!`, 
      error: null 
    });
  } catch (error) {
    console.error('Error activating app update:', error);
    const updates = await AppUpdate.getAllUpdates();
    res.render('app-updates', { 
      updates, 
      success: null, 
      error: `❌ Failed to activate version: ${error.message}` 
    });
  }
});

app.post('/app-updates/deactivate', requireAuth, async (req, res) => {
  try {
    const { version_code } = req.body;
    
    if (!version_code) {
      throw new Error('Version code is required');
    }
    
    const deactivatedVersion = await AppUpdate.deactivateVersion(parseInt(version_code));
    
    if (!deactivatedVersion) {
      throw new Error('Version not found');
    }
    
    const updates = await AppUpdate.getAllUpdates();
    res.render('app-updates', { 
      updates, 
      success: `✅ Version ${deactivatedVersion.version_name} deactivated successfully!`, 
      error: null 
    });
  } catch (error) {
    console.error('Error deactivating app update:', error);
    const updates = await AppUpdate.getAllUpdates();
    res.render('app-updates', { 
      updates, 
      success: null, 
      error: `❌ Failed to deactivate version: ${error.message}` 
    });
  }
});

app.post('/app-updates/delete', requireAuth, async (req, res) => {
  try {
    const { version_code } = req.body;
    
    if (!version_code) {
      throw new Error('Version code is required');
    }
    
    const deletedVersion = await AppUpdate.deleteVersion(parseInt(version_code));
    
    if (!deletedVersion) {
      throw new Error('Version not found');
    }
    
    const updates = await AppUpdate.getAllUpdates();
    res.render('app-updates', { 
      updates, 
      success: `✅ Version ${deletedVersion.version_name} deleted successfully!`, 
      error: null 
    });
  } catch (error) {
    console.error('Error deleting app update:', error);
    const updates = await AppUpdate.getAllUpdates();
    res.render('app-updates', { 
      updates, 
      success: null, 
      error: `❌ Failed to delete version: ${error.message}` 
    });
  }
});

// API endpoint to get ads config for Flutter app
app.get('/api/ads-config', async (req, res) => {
  try {
    const { platform } = req.query;
    
    if (platform && ['android', 'ios'].includes(platform)) {
      // Get ads for specific platform
      const adsConfig = await AdsConfig.getAdsByPlatform(platform);
      res.json({
        success: true,
        data: adsConfig
      });
    } else {
      // Get all ads config (both platforms)
      const adsConfig = await AdsConfig.getAllAdsConfig();
      res.json({
        success: true,
        data: adsConfig
      });
    }
  } catch (error) {
    console.error('Error getting ads config:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// API endpoint to update ads config
app.post('/api/ads-config', async (req, res) => {
  try {
    const { adType, platform, adId, description, isActive } = req.body;
    
    if (!adType || !platform || !adId || !adId.trim()) {
      return res.status(400).json({
        success: false,
        error: 'Ad type, platform, and Ad ID are required'
      });
    }
    
    // Validate platform
    if (!['android', 'ios'].includes(platform)) {
      return res.status(400).json({
        success: false,
        error: 'Platform must be either android or ios'
      });
    }
    
    // Validate ad ID format (basic AdMob format check)
    const adIdPattern = /^ca-app-pub-\d{16}\/\d{10}$/;
    if (!adIdPattern.test(adId.trim())) {
      return res.status(400).json({
        success: false,
        error: 'Invalid Ad ID format. Please use format: ca-app-pub-xxxxxxxxxxxxxxxx/xxxxxxxxxx'
      });
    }
    
    const updateOptions = {
      description: description || '',
      isActive: isActive === true || isActive === 'true'
    };
    
    await AdsConfig.updateAdConfig(adType, platform, adId.trim(), updateOptions);
    
    const adsConfig = await AdsConfig.getAllAdsConfig();
    res.json({
      success: true,
      data: adsConfig,
      message: `${platform.toUpperCase()} ${adType.charAt(0).toUpperCase() + adType.slice(1)} ad updated successfully!`
    });
  } catch (error) {
    console.error('Error updating ads config:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// API endpoint to get latest app update for Flutter app
app.get('/api/app-update/latest', async (req, res) => {
  try {
    const latestUpdate = await AppUpdate.getLatestUpdate();
    
    if (!latestUpdate) {
      return res.json({
        success: true,
        data: null,
        message: 'No active app update found'
      });
    }
    
    res.json({
      success: true,
      data: {
        version_name: latestUpdate.version_name,
        version_code: latestUpdate.version_code,
        is_force_update: latestUpdate.is_force_update,
        is_normal_update: latestUpdate.is_normal_update,
        update_message: latestUpdate.update_message,
        update_link: latestUpdate.update_link,
        is_active: latestUpdate.is_active
      }
    });
  } catch (error) {
    console.error('Error getting latest app update:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// API endpoint to get all app updates (for admin purposes)
app.get('/api/app-updates', async (req, res) => {
  try {
    const updates = await AppUpdate.getAllUpdates();
    res.json({
      success: true,
      data: updates
    });
  } catch (error) {
    console.error('Error getting all app updates:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// API endpoint to create or update app version
app.post('/api/app-updates', async (req, res) => {
  try {
    const { version_name, version_code, update_message, update_link, is_force_update, is_normal_update, is_active } = req.body;
    
    if (!version_name || !version_code) {
      return res.status(400).json({
        success: false,
        error: 'Version name and version code are required'
      });
    }
    
    const updateData = {
      version_name: version_name.trim(),
      version_code: parseInt(version_code),
      update_message: update_message || 'A new version is available. Please update for the best experience.',
      update_link: update_link || 'https://example.com/app-download',
      is_force_update: is_force_update === true || is_force_update === 'true',
      is_normal_update: is_normal_update === true || is_normal_update === 'true',
      is_active: is_active === true || is_active === 'true'
    };
    
    const result = await AppUpdate.createOrUpdateVersion(updateData);
    
    res.json({
      success: true,
      data: result,
      message: `App version ${version_name} created/updated successfully!`
    });
  } catch (error) {
    console.error('Error creating/updating app version:', error);
    res.status(500).json({
      success: false,
      error: error.message
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

app.listen(PORT, () => {
  console.log(`🚀 Admin Panel running on http://localhost:${PORT}`);
});