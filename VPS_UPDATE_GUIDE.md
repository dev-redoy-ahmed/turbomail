# VPS Update Guide - TurboMail

## 🚀 VPS Information
- **IP Address:** 165.22.109.153
- **Admin Panel:** http://165.22.109.153:3006
- **Mail API:** http://165.22.109.153:3005

## 📋 Current Status Check Results

### ✅ Working Services:
- **Admin Panel (Port 3006):** ✅ Running and accessible
- **Login System:** ✅ Working

### ❌ Issues Found:
- **Mail API (Port 3005):** ❌ Not responding

## 🔄 Steps to Update VPS with Latest Code

### 1. SSH into VPS
```bash
ssh root@165.22.109.153
# or
ssh your-username@165.22.109.153
```

### 2. Navigate to Project Directory
```bash
cd /path/to/turbomail
# Usually: cd /opt/turbomail or cd /home/user/turbomail
```

### 3. Pull Latest Code from GitHub
```bash
git pull origin main
```

### 4. Install/Update Dependencies
```bash
# Update admin panel dependencies
cd admin
npm install

# Update mail-api dependencies
cd ../mail-api
npm install

# Update haraka-server dependencies
cd ../haraka-server
npm install
```

### 5. Restart Services
```bash
# Using PM2 (recommended)
pm2 restart all

# Or restart individual services
pm2 restart admin
pm2 restart mail-api
pm2 restart haraka-server

# Or if using systemd
sudo systemctl restart turbomail-admin
sudo systemctl restart turbomail-api
sudo systemctl restart turbomail-haraka
```

### 6. Check Service Status
```bash
pm2 status
# or
pm2 logs
```

## 🧪 Testing Services

### 1. Test Admin Panel
```bash
# Check if admin panel is accessible
curl -I http://165.22.109.153:3006
```

### 2. Test API Endpoints
```bash
# Test mail-api endpoints
curl http://165.22.109.153:3005/api/emails/test@example.com
```

## 🔧 Troubleshooting

### If Mail API is not responding:
1. Check if the service is running: `pm2 status`
2. Check logs: `pm2 logs mail-api`
3. Restart service: `pm2 restart mail-api`
4. Check port configuration in config.js

### If Admin Panel has issues:
1. Ensure latest code is pulled: `git pull origin main`
2. Restart admin service: `pm2 restart admin`
3. Check if view files exist in `admin/views/`

### If Database connection issues:
1. Check MongoDB connection string in environment variables
2. Ensure MongoDB is running
3. Check network connectivity to MongoDB

## 📞 Quick Commands for VPS Admin

```bash
# Check all services
pm2 status

# View logs
pm2 logs

# Restart all services
pm2 restart all

# Check git status
git status

# Pull latest code
git pull origin main

# Check open ports
netstat -tulpn | grep :300
```

## 🎯 Expected Results After Update

1. **Admin Panel:** Should be accessible and functional
2. **API Endpoints:** Should respond with JSON data
3. **Mail API:** Should be accessible on configured port
4. **Email System:** Should receive and manage emails properly

## 📋 Verification Checklist

- [ ] Admin panel accessible at http://165.22.109.153:3006
- [ ] Mail API accessible at http://165.22.109.153:3005 (or configured port)
- [ ] Email receiving functionality working
- [ ] Admin dashboard functional
- [ ] All PM2 services running
- [ ] No errors in PM2 logs