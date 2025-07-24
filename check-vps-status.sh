#!/bin/bash

# TurboMail VPS Status Checker
# This script checks the status of TurboMail services on the VPS

VPS_IP="165.22.109.153"
ADMIN_PORT="3006"
API_PORT="3005"

echo "🔍 Checking TurboMail VPS Status at $VPS_IP"
echo "================================================"

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

# Check admin panel
echo "🔍 Checking Admin Panel (Port $ADMIN_PORT)..."
if curl -s -I http://$VPS_IP:$ADMIN_PORT | grep -q "200\|302"; then
    print_status "Admin Panel is responding"
    
    # Check if login page loads
    if curl -s http://$VPS_IP:$ADMIN_PORT/login | grep -q "TempMail Admin"; then
        print_status "Login page is working"
    else
        print_warning "Login page may have issues"
    fi
else
    print_error "Admin Panel is not responding"
fi

# Check mail API
echo ""
echo "🔍 Checking Mail API (Port $API_PORT)..."
if curl -s -I http://$VPS_IP:$API_PORT | grep -q "200\|302"; then
    print_status "Mail API is responding"
else
    print_error "Mail API is not responding on port $API_PORT"
    
    # Try alternative ports
    echo "🔍 Trying alternative ports..."
    for port in 3000 8080; do
        if curl -s -I http://$VPS_IP:$port | grep -q "200\|302"; then
            print_status "Mail API found on port $port"
            API_PORT=$port
            break
        fi
    done
fi

echo ""
echo "📋 Summary:"
echo "================================================"
echo "VPS IP: $VPS_IP"
echo "Admin Panel: http://$VPS_IP:$ADMIN_PORT"
echo "Mail API: http://$VPS_IP:$API_PORT"
echo ""
echo "🔧 If services are not responding:"
echo "1. SSH into VPS: ssh root@$VPS_IP"
echo "2. Run update script: ./update-vps.sh"
echo "3. Check PM2 status: pm2 status"
echo "4. Check logs: pm2 logs"