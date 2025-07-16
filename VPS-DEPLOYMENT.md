# TurboMail VPS Configuration Guide

## 🚀 VPS Deployment Configuration

This guide helps you deploy TurboMail on your VPS with proper port management and service coordination.

### 📋 Port Configuration
- **Mail API**: Port 3001
- **Admin Panel**: Port 3006
- **Haraka SMTP**: Port 25 (standard SMTP)
- **Redis**: Port 6379 (default)

### 🔧 VPS Setup Instructions

#### 1. Prerequisites on VPS
```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Node.js (v18+)
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Install Redis
sudo apt install redis-server -y
sudo systemctl enable redis-server
sudo systemctl start redis-server

# Install PM2 for process management
sudo npm install -g pm2
```

#### 2. Clone and Setup Project
```bash
# Clone the repository
git clone https://github.com/dev-redoy-ahmed/turbomail.git
cd turbomail

# Install dependencies for all services
cd mail-api && npm install && cd ..
cd admin && npm install && cd ..
cd haraka-server && npm install && cd ..
```

#### 3. Configure Firewall (if needed)
```bash
# Allow necessary ports
sudo ufw allow 22    # SSH
sudo ufw allow 25    # SMTP
sudo ufw allow 3001  # Mail API
sudo ufw allow 3006  # Admin Panel
sudo ufw enable
```

#### 4. Start Services with PM2
```bash
# Start Mail API
pm2 start mail-api/index.js --name "turbomail-api"

# Start Admin Panel
pm2 start admin/server.js --name "turbomail-admin"

# Start Haraka SMTP Server
cd haraka-server
pm2 start "npm start" --name "turbomail-smtp"
cd ..

# Save PM2 configuration
pm2 save
pm2 startup
```

### 🌐 Access Your Services

Replace `YOUR_VPS_IP` with your actual VPS IP address:

- **Mail API**: `http://YOUR_VPS_IP:3001`
- **Admin Panel**: `http://YOUR_VPS_IP:3006`
- **SMTP Server**: `YOUR_VPS_IP:25`

### 📊 Service Management Commands

```bash
# Check service status
pm2 status

# View logs
pm2 logs turbomail-api
pm2 logs turbomail-admin
pm2 logs turbomail-smtp

# Restart services
pm2 restart turbomail-api
pm2 restart turbomail-admin
pm2 restart turbomail-smtp

# Stop services
pm2 stop all

# Monitor services
pm2 monit
```

### 🔒 Security Recommendations

1. **Change default admin credentials** in admin panel
2. **Update API key** in mail-api/index.js
3. **Configure SSL/TLS** for production
4. **Set up reverse proxy** with Nginx (optional)
5. **Regular backups** of Redis data

### 📁 Configuration Files

### Main Configuration (`config.js`)
All TurboMail settings are centralized in the `config.js` file:

```javascript
module.exports = {
  API: {
    PORT: 3001,
    MASTER_KEY: 'tempmail-master-key-2024',
    ALLOWED_DOMAINS: ['oplex.online', 'agrovia.store']
  },
  ADMIN: {
    PORT: 3006,
    USERNAME: 'admin',
    PASSWORD: 'admin123'
  },
  SMTP: {
    PORT: 25,
    HOST: '127.0.0.1'
  },
  REDIS: {
    HOST: '127.0.0.1',
    PORT: 6379
  },
  EMAIL: {
    EXPIRY_TIME: 3600, // 1 hour
    MAX_MESSAGE_SIZE: '20mb'
  }
};
```

**Important**: Update the `config.js` file with your VPS-specific settings before deployment.

All configuration is done through direct file editing (no .env files needed):

- **Mail API Port**: `mail-api/index.js` line 16
- **Admin Panel Port**: `admin/server.js` line 9
- **SMTP Port**: `haraka-server/config/smtp.ini`
- **Allowed Domains**: `mail-api/index.js` line 18
- **API Key**: `mail-api/index.js` line 17

### 🚨 Troubleshooting

#### Port Already in Use
```bash
# Check what's using a port
sudo netstat -tulpn | grep :3001
sudo netstat -tulpn | grep :3006

# Kill process if needed
sudo kill -9 <PID>
```

#### Redis Connection Issues
```bash
# Check Redis status
sudo systemctl status redis-server

# Restart Redis
sudo systemctl restart redis-server
```

#### SMTP Issues
```bash
# Check if port 25 is blocked by ISP
telnet smtp.gmail.com 25

# Use alternative port if needed (edit haraka-server/config/smtp.ini)
listen=0.0.0.0:587
```

### 📈 Monitoring

```bash
# System resources
htop

# Service logs
pm2 logs --lines 100

# Redis monitoring
redis-cli monitor
```

### 🔄 Updates

```bash
# Pull latest changes
git pull origin main

# Restart services
pm2 restart all
```

---

**Note**: This configuration is optimized for VPS deployment with localhost communication between services. All services run on the same server and communicate internally.