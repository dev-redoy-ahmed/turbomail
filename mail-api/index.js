// index.js (Express + Redis + Secure API Key + Email API + Socket.IO)

const express = require('express');
const { createServer } = require('http');
const { Server } = require('socket.io');
const { simpleParser } = require('mailparser');
const { createClient } = require('redis');
const path = require('path');
const crypto = require('crypto');

const app = express();
const httpServer = createServer(app);
const io = new Server(httpServer, {
  cors: { origin: '*', methods: ['GET', 'POST', 'DELETE'] }
});

const PORT = 3001;
const MASTER_API_KEY = 'tempmail-master-key-2024';
const ALLOWED_DOMAINS = ['oplex.online', 'agrovia.store'];

const redisClient = createClient({
  socket: { host: '127.0.0.1', port: 6379 }
});

redisClient.on('error', err => console.error('❌ Redis error:', err));
redisClient.connect().then(() => console.log('✅ Redis connected'));

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
  res.send('📡 TurboMail API + Socket.IO is live');
});

// ✅ 1. Generate random email
app.get('/generate', (req, res) => {
  const domain = ALLOWED_DOMAINS[0];
  const user = crypto.randomBytes(5).toString('hex');
  res.json({ email: `${user}@${domain}` });
});

// ✅ 2. Generate manual email
app.get('/generate/manual', async (req, res) => {
  const { username, domain } = req.query;
  if (!username || !domain || !ALLOWED_DOMAINS.includes(domain)) {
    return res.status(400).send('❌ Invalid username or domain');
  }
  const key = `inbox:${username.toLowerCase()}@${domain}`;
  const exists = await redisClient.exists(key);
  if (exists) return res.status(409).send('⚠️ Email already exists');
  res.json({ email: `${username.toLowerCase()}@${domain}` });
});

// ✅ 3. View inbox messages
app.get('/inbox/:email', async (req, res) => {
  const email = req.params.email.toLowerCase();
  try {
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

// ✅ Haraka: POST raw mail + broadcast to inbox
app.post('/incoming/raw', express.raw({ type: '*/*', limit: '20mb' }), async (req, res) => {
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

    await redisClient.rPush(`inbox:${to}`, JSON.stringify(email));
    await redisClient.expire(`inbox:${to}`, 3600);
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

httpServer.listen(PORT, () => {
  console.log(`🚀 Mail API with Socket.IO running on port ${PORT}`);
});
