# TurboMail - Temporary Email Service

A complete temporary email service built with Node.js, featuring a powerful admin panel, REST API, and Haraka SMTP server integration.

## 🚀 Features

### Core Features
- **Temporary Email Generation**: Generate random or custom temporary email addresses
- **Real-time Email Reception**: Receive emails instantly via Haraka SMTP server
- **REST API**: Complete API for email management with authentication
- **Admin Panel**: Beautiful web-based admin interface with dark theme
- **Redis Integration**: Fast email storage and retrieval
- **Domain Management**: Add/remove custom domains dynamically

### Admin Panel Features
- 🔐 Secure login system
- 📊 System dashboard with overview
- 🌐 Domain management (add/delete domains)
- 🔑 API key management
- 📈 System status monitoring
- 🎨 Modern dark theme UI

### API Features
- Generate random email addresses
- Generate custom email addresses
- View inbox contents
- Delete emails/entire inbox
- API key authentication
- CORS support

## 📁 Project Structure

```
temp-mail/
├── admin/                  # Admin panel (Express.js)
│   ├── server.js          # Main admin server
│   ├── assets/            # Static assets (CSS, JS)
│   └── views/             # EJS templates
├── mail-api/              # REST API server
│   ├── index.js           # Main API server
│   └── client.html        # API documentation
├── haraka-server/         # SMTP server
│   ├── config/            # Haraka configuration
│   └── plugins/           # Custom plugins
└── start-haraka.sh        # Haraka startup script
```

## 🛠️ Installation

### Prerequisites
- Node.js (v14 or higher)
- Redis server
- Git

### Setup Instructions

1. **Clone the repository**
   ```bash
   git clone https://github.com/dev-redoy-ahmed/turbomail.git
   cd turbomail
   ```

2. **Install dependencies for all components**
   ```bash
   # Install Mail API dependencies
   cd mail-api
   npm install
   cd ..

   # Install Admin Panel dependencies
   cd admin
   npm install
   cd ..

   # Install Haraka Server dependencies
   cd haraka-server
   npm install
   cd ..
   ```

3. **Start Redis server**
   ```bash
   redis-server
   ```

4. **Configure the system**
   - Update `haraka-server/config/host_list` with your domains
   - Modify API keys in `mail-api/index.js` if needed
   - Configure SMTP settings in `haraka-server/config/smtp.ini`

## 🚀 Running the Application

### Local Development

Start all services locally:

1. **Start the Mail API** (Port 3001)
   ```bash
   cd mail-api
   npm start
   ```

2. **Start the Admin Panel** (Port 3006)
   ```bash
   cd admin
   npm start
   ```

3. **Start the Haraka SMTP Server** (Port 25)
   ```bash
   cd haraka-server
   npm start
   # or use the shell script
   ./start-haraka.sh
   ```

### 🌐 VPS Deployment

For VPS deployment, use the automated setup:

```bash
# Make startup script executable
chmod +x start-vps.sh

# Run the VPS startup script
./start-vps.sh
```

**VPS Services will be available at:**
- Mail API: `http://YOUR_VPS_IP:3001`
- Admin Panel: `http://YOUR_VPS_IP:3006`
- SMTP Server: `YOUR_VPS_IP:25`

For detailed VPS setup instructions, see [VPS-DEPLOYMENT.md](VPS-DEPLOYMENT.md)

## 📖 API Documentation

### Base URL
```
http://localhost:3001
```

### Authentication
All API endpoints require an API key in the header:
```
X-API-Key: tempmail-master-key-2024
```

### Endpoints

#### Generate Random Email
```http
GET /generate
```

#### Generate Custom Email
```http
GET /generate/manual?username=myemail&domain=example.com
```

#### View Inbox
```http
GET /inbox/:email
```

#### Delete Email/Inbox
```http
DELETE /delete/:email/:index?
```

## 🔧 Admin Panel

Access the admin panel at: `http://localhost:3006`

**Default Credentials:**
- Username: `admin`
- Password: `admin123`

### Admin Features:
- **Dashboard**: System overview and statistics
- **Domain Management**: Add/remove email domains
- **API Management**: View and update API keys
- **System Monitoring**: Check service status

## ⚙️ Configuration

### Environment Variables
Create a `.env` file in each component directory:

**mail-api/.env**
```env
PORT=3001
REDIS_HOST=localhost
REDIS_PORT=6379
API_KEY=tempmail-master-key-2024
```

**admin/.env**
```env
PORT=3006
ADMIN_USERNAME=admin
ADMIN_PASSWORD=admin123
```

### Haraka Configuration
- **SMTP Settings**: `haraka-server/config/smtp.ini`
- **Allowed Domains**: `haraka-server/config/host_list`
- **Plugins**: `haraka-server/config/plugins`

## 🔒 Security Features

- API key authentication
- Admin panel login protection
- Input validation and sanitization
- CORS configuration
- Rate limiting (configurable)

## 🛡️ Production Deployment

### Recommended Setup:
1. Use PM2 for process management
2. Set up Nginx as reverse proxy
3. Configure SSL certificates
4. Use environment variables for sensitive data
5. Set up monitoring and logging

### PM2 Configuration:
```bash
# Install PM2
npm install -g pm2

# Start all services
pm2 start mail-api/index.js --name "mail-api"
pm2 start admin/server.js --name "admin-panel"
pm2 start haraka-server/server.js --name "haraka-smtp"
```

## 📝 API Usage Examples

### JavaScript/Node.js
```javascript
const axios = require('axios');

// Generate random email
const response = await axios.get('http://localhost:3001/generate', {
  headers: { 'X-API-Key': 'tempmail-master-key-2024' }
});

console.log(response.data.email);
```

### cURL
```bash
# Generate random email
curl -H "X-API-Key: tempmail-master-key-2024" \
     http://localhost:3001/generate

# View inbox
curl -H "X-API-Key: tempmail-master-key-2024" \
     http://localhost:3001/inbox/test@example.com
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Built with [Haraka](https://haraka.github.io/) SMTP server
- Uses [Express.js](https://expressjs.com/) for web services
- [Redis](https://redis.io/) for fast data storage
- [EJS](https://ejs.co/) for templating

## 📞 Support

For support and questions:
- Create an issue on GitHub
- Check the documentation
- Review the API examples

---

**TurboMail** - Fast, reliable, and secure temporary email service 🚀