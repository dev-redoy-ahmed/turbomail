const express = require('express');
const bodyParser = require('body-parser');
const session = require('express-session');
const fs = require('fs-extra');
const path = require('path');
const bcrypt = require('bcryptjs');

const app = express();
const PORT = 3006;

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
  if (username === 'admin' && password === 'admin123') {
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
    await updateApiKey(apiKey);
    
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
      success: 'Master API Key updated successfully', 
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
      error: error.message 
    });
  }
});

// Helper functions
async function getApiKey() {
  try {
    const content = await fs.readFile(MAIL_API_PATH, 'utf8');
    const match = content.match(/const MASTER_API_KEY = ['"`](.*?)['"`]/);
    if (match && match[1]) {
      return match[1];
    }
    return 'tempmail-master-key-2024'; // Default fallback
  } catch (error) {
    console.error('Error reading API key:', error);
    return 'tempmail-master-key-2024'; // Default fallback
  }
}

async function updateApiKey(newKey) {
  try {
    let content = await fs.readFile(MAIL_API_PATH, 'utf8');
    
    if (!newKey || !newKey.trim()) {
      throw new Error('API Key cannot be empty');
    }
    
    content = content.replace(/const MASTER_API_KEY = ['"`].*?['"`]/, `const MASTER_API_KEY = '${newKey.trim()}'`);
    
    await fs.writeFile(MAIL_API_PATH, content);
  } catch (error) {
    throw error;
  }
}

async function updateMailApiDomains(domains) {
  try {
    let content = await fs.readFile(MAIL_API_PATH, 'utf8');
    const domainsString = domains.map(d => `'${d}'`).join(', ');
    content = content.replace(/const ALLOWED_DOMAINS = \[.*?\]/s, `const ALLOWED_DOMAINS = [${domainsString}]`);
    await fs.writeFile(MAIL_API_PATH, content);
  } catch (error) {
    console.error('Error updating mail-api domains:', error);
  }
}

app.listen(PORT, () => {
  console.log(`🚀 Admin Panel running on http://localhost:${PORT}`);
});