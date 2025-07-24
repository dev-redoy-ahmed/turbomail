#!/bin/bash

# TurboMail VPS Update Script
# This script updates the VPS with the latest code from GitHub

echo "🚀 Starting TurboMail VPS Update Process..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if we're in the right directory
if [ ! -f "package.json" ] || [ ! -d "admin" ] || [ ! -d "mail-api" ]; then
    print_error "Not in TurboMail project directory. Please navigate to the project root."
    exit 1
fi

print_status "Found TurboMail project directory"

# Pull latest code from GitHub
echo "📥 Pulling latest code from GitHub..."
git pull origin main
if [ $? -eq 0 ]; then
    print_status "Successfully pulled latest code"
else
    print_error "Failed to pull code from GitHub"
    exit 1
fi

# Update admin panel dependencies
echo "📦 Updating admin panel dependencies..."
cd admin
npm install
if [ $? -eq 0 ]; then
    print_status "Admin dependencies updated"
else
    print_warning "Admin dependencies update had issues"
fi
cd ..

# Update mail-api dependencies
echo "📦 Updating mail-api dependencies..."
cd mail-api
npm install
if [ $? -eq 0 ]; then
    print_status "Mail-API dependencies updated"
else
    print_warning "Mail-API dependencies update had issues"
fi
cd ..

# Update haraka-server dependencies
echo "📦 Updating haraka-server dependencies..."
cd haraka-server
npm install
if [ $? -eq 0 ]; then
    print_status "Haraka-server dependencies updated"
else
    print_warning "Haraka-server dependencies update had issues"
fi
cd ..

# Check if PM2 is available
if command -v pm2 &> /dev/null; then
    echo "🔄 Restarting services with PM2..."
    pm2 restart all
    if [ $? -eq 0 ]; then
        print_status "All services restarted successfully"
    else
        print_warning "Some services may not have restarted properly"
    fi
    
    echo "📊 Current PM2 status:"
    pm2 status
    
    echo "📋 Recent logs:"
    pm2 logs --lines 10
else
    print_warning "PM2 not found. Please restart services manually."
fi

# Test the services
echo "🧪 Testing services..."

# Test admin panel
if curl -s -I http://localhost:3006 | grep -q "200\|302"; then
    print_status "Admin panel is responding"
else
    print_error "Admin panel is not responding"
fi

# Test mail API (try different ports)
for port in 3005 3000 8080; do
    if curl -s -I http://localhost:$port | grep -q "200\|302"; then
        print_status "Mail API is responding on port $port"
        break
    fi
done

echo ""
echo "🎉 Update process completed!"
echo ""
echo "📋 Next steps:"
echo "1. Check admin panel at: http://your-vps-ip:3006"
echo "2. Verify mail API functionality"
echo "3. Test email receiving and management"
echo ""
echo "🔧 If issues persist:"
echo "1. Check PM2 logs: pm2 logs"
echo "2. Check service status: pm2 status"
echo "3. Restart individual services: pm2 restart [service-name]"