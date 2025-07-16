#!/bin/bash

# TurboMail VPS Startup Script
echo "🚀 Starting TurboMail Services on VPS..."

# Create logs directory
mkdir -p logs

# Check if Redis is running
if ! pgrep -x "redis-server" > /dev/null; then
    echo "⚠️  Redis not running. Starting Redis..."
    sudo systemctl start redis-server
    sleep 2
fi

# Check Redis connection
if redis-cli ping | grep -q "PONG"; then
    echo "✅ Redis is running"
else
    echo "❌ Redis connection failed"
    exit 1
fi

# Stop any existing PM2 processes
echo "🔄 Stopping existing services..."
pm2 delete all 2>/dev/null || true

# Start services using PM2 ecosystem
echo "🚀 Starting TurboMail services..."
pm2 start ecosystem.config.json

# Save PM2 configuration
pm2 save

# Show status
echo "📊 Service Status:"
pm2 status

echo ""
echo "🎉 TurboMail is now running on your VPS!"
echo ""
echo "📡 Services:"
echo "   Mail API: http://YOUR_VPS_IP:3001"
echo "   Admin Panel: http://YOUR_VPS_IP:3006"
echo "   SMTP Server: YOUR_VPS_IP:25"
echo ""
echo "🔧 Management Commands:"
echo "   pm2 status          - Check service status"
echo "   pm2 logs            - View all logs"
echo "   pm2 restart all     - Restart all services"
echo "   pm2 stop all        - Stop all services"
echo ""
echo "⚠️  Remember to:"
echo "   1. Replace YOUR_VPS_IP with your actual VPS IP"
echo "   2. Configure your firewall to allow ports 25, 3001, 3006"
echo "   3. Update DNS records to point to your VPS"
echo "   4. Change default admin credentials (admin/admin123)"
echo ""