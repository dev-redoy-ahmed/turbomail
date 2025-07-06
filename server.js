const express = require('express');
const redis = require('redis');
const bodyParser = require('body-parser');
const cors = require('cors');
const crypto = require('crypto');
const fs = require('fs');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3001;
const API_KEY = 'supersecretapikey123';

// Middleware to validate API key
function validateApiKey(req, res, next) {
    const providedKey = req.query.key || req.body.key || req.headers['x-api-key'];
    
    if (!providedKey) {
        return res.status(401).json({ 
            error: 'API key is required. Please provide it as a query parameter (?key=your_key), in request body, or in x-api-key header.' 
        });
    }
    
    if (providedKey !== API_KEY) {
        return res.status(401).json({ 
            error: 'Invalid API key. Please check your API key and try again.' 
        });
    }
    
    next();
}
const REDIS_PASSWORD = 'we1we2we3';

// Redis client setup
let client;
let redisConnected = false;

async function connectRedis() {
  try {
    client = redis.createClient({
      password: REDIS_PASSWORD,
      socket: {
        host: 'localhost',
        port: 6379
      }
    });
    
    client.on('error', (err) => {
      console.log('Redis Client Error:', err.message);
      redisConnected = false;
    });
    
    client.on('connect', () => {
      console.log('Connected to Redis successfully');
      redisConnected = true;
    });
    
    await client.connect();
  } catch (err) {
    console.log('Failed to connect to Redis:', err.message);
    console.log('Admin panel will work without Redis functionality');
    redisConnected = false;
  }
}

// Initialize Redis connection
connectRedis();

// Middleware
app.use(cors());
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));
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
app.get('/inbox/:email', validateApiKey, async (req, res) => {
  if (!redisConnected) {
    return res.status(503).json({ error: 'Redis not connected' });
  }
  
  try {
    const email = req.params.email;
    const messages = await client.lRange(`inbox:${email}`, 0, -1);
    const parsedMessages = messages.map(msg => JSON.parse(msg));
    res.json({ email: email, messages: parsedMessages });
  } catch (err) {
    res.status(500).json({ error: 'Failed to retrieve inbox' });
  }
});

// Get specific email by index
app.get('/inbox/:email/:index', validateApiKey, async (req, res) => {
  if (!redisConnected) {
    return res.status(503).json({ error: 'Redis not connected' });
  }
  
  try {
    const email = req.params.email;
    const index = parseInt(req.params.index);
    const message = await client.lIndex(`inbox:${email}`, index);
    
    if (!message) {
      return res.status(404).json({ error: 'Message not found' });
    }
    
    res.json({ email: email, message: JSON.parse(message) });
  } catch (err) {
    res.status(500).json({ error: 'Failed to retrieve message' });
  }
});

// Delete all emails for an inbox
app.delete('/delete/:email', validateApiKey, async (req, res) => {
  if (!redisConnected) {
    return res.status(503).json({ error: 'Redis not connected' });
  }
  
  try {
    const email = req.params.email;
    await client.del(`inbox:${email}`);
    res.json({ success: true, message: `All messages deleted for ${email}` });
  } catch (err) {
    res.status(500).json({ error: 'Failed to delete messages' });
  }
});

// Delete specific email by index
app.delete('/delete/:email/:index', validateApiKey, async (req, res) => {
  if (!redisConnected) {
    return res.status(503).json({ error: 'Redis not connected' });
  }
  
  try {
    const email = req.params.email;
    const index = parseInt(req.params.index);
    
    // Get all messages
    const messages = await client.lRange(`inbox:${email}`, 0, -1);
    
    if (index >= messages.length || index < 0) {
      return res.status(404).json({ error: 'Message not found' });
    }
    
    // Remove the message at the specified index
    const messageToRemove = messages[index];
    await client.lRem(`inbox:${email}`, 1, messageToRemove);
    
    res.json({ success: true, message: `Message at index ${index} deleted` });
  } catch (err) {
    res.status(500).json({ error: 'Failed to delete message' });
  }
});

// Admin API endpoints
app.get('/admin/domains', (req, res) => {
  const domains = loadDomains();
  res.json({ domains: domains });
});

app.post('/admin/domains', (req, res) => {
  const { domain } = req.body;
  if (!domain) {
    return res.status(400).json({ error: 'Domain is required' });
  }
  
  const domains = loadDomains();
  if (!domains.includes(domain)) {
    domains.push(domain);
    saveDomains(domains);
  }
  
  res.json({ success: true, domains: domains });
});

app.delete('/admin/domains/:domain', (req, res) => {
  const domainToDelete = req.params.domain;
  const domains = loadDomains();
  const filteredDomains = domains.filter(domain => domain !== domainToDelete);
  
  if (filteredDomains.length === domains.length) {
    return res.status(404).json({ error: 'Domain not found' });
  }
  
  saveDomains(filteredDomains);
  res.json({ success: true, domains: filteredDomains });
});

// Serve admin panel
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

app.listen(PORT, () => {
  console.log(`TurboMail Admin Panel running on port ${PORT}`);
  console.log(`Admin Panel: http://localhost:${PORT}`);
  console.log(`API Base URL: http://localhost:${PORT}`);
});

module.exports = app;