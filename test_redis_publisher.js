#!/usr/bin/env node

/**
 * Test Redis Publisher for TurboMail
 * This script simulates external email notifications (like from Haraka plugin)
 * Usage: node test_redis_publisher.js [email]
 */

const redis = require('redis');
const crypto = require('crypto');

// Configuration
const config = {
    redis: {
        url: process.env.REDIS_URL || 'redis://:we1we2we3@127.0.0.1:6379'
    }
};

// Create Redis client for publishing
const publisher = redis.createClient({
    url: config.redis.url
});

publisher.on('error', (err) => {
    console.error('Redis Publisher Error:', err.message);
});

publisher.on('connect', () => {
    console.log('✅ Redis Publisher Connected');
});

// Generate sample email data
function generateSampleEmail(recipientEmail) {
    const senders = [
        'john.doe@example.com',
        'newsletter@company.com',
        'support@service.com',
        'notifications@app.com'
    ];
    
    const subjects = [
        'Welcome to our service!',
        'Your order has been confirmed',
        'Weekly Newsletter',
        'Password Reset Request',
        'New message from support'
    ];
    
    const sender = senders[Math.floor(Math.random() * senders.length)];
    const subject = subjects[Math.floor(Math.random() * subjects.length)];
    
    return {
        id: crypto.randomUUID(),
        from: sender,
        to: recipientEmail,
        subject: subject,
        body: `This is a test email sent to ${recipientEmail} from ${sender}.\n\nSubject: ${subject}\n\nThis email was generated for testing the real-time notification system.`,
        timestamp: new Date().toISOString(),
        attachments: []
    };
}

// Publish general email notification
async function publishGeneralEmail(recipientEmail) {
    const emailMessage = generateSampleEmail(recipientEmail);
    
    const notificationData = {
        to: recipientEmail,
        message: emailMessage
    };
    
    try {
        await publisher.publish('new_email', JSON.stringify(notificationData));
        console.log(`📧 Published general email notification for: ${recipientEmail}`);
        console.log(`   Subject: ${emailMessage.subject}`);
        console.log(`   From: ${emailMessage.from}`);
    } catch (error) {
        console.error('Failed to publish general email:', error.message);
    }
}

// Publish targeted email notification
async function publishTargetedEmail(recipientEmail) {
    const emailMessage = generateSampleEmail(recipientEmail);
    
    try {
        await publisher.publish(`channel:email:${recipientEmail}`, JSON.stringify(emailMessage));
        console.log(`🎯 Published targeted email notification for: ${recipientEmail}`);
        console.log(`   Subject: ${emailMessage.subject}`);
        console.log(`   From: ${emailMessage.from}`);
    } catch (error) {
        console.error('Failed to publish targeted email:', error.message);
    }
}

// Main function
async function main() {
    try {
        await publisher.connect();
        
        // Get email from command line argument or use default
        const targetEmail = process.argv[2] || 'test@turbomail.dev';
        
        console.log(`🚀 Starting Redis Publisher Test for: ${targetEmail}`);
        console.log(`📡 Redis URL: ${config.redis.url}`);
        console.log('=' .repeat(60));
        
        // Publish both types of notifications
        await publishGeneralEmail(targetEmail);
        await new Promise(resolve => setTimeout(resolve, 1000)); // Wait 1 second
        
        await publishTargetedEmail(targetEmail);
        
        console.log('=' .repeat(60));
        console.log('✅ Test completed successfully!');
        console.log('📱 Check your TurboMail Flutter app for real-time notifications');
        
    } catch (error) {
        console.error('❌ Test failed:', error.message);
        process.exit(1);
    } finally {
        await publisher.quit();
        console.log('🔌 Redis Publisher disconnected');
    }
}

// Handle process termination
process.on('SIGINT', async () => {
    console.log('\n🛑 Received SIGINT, shutting down gracefully...');
    await publisher.quit();
    process.exit(0);
});

process.on('SIGTERM', async () => {
    console.log('\n🛑 Received SIGTERM, shutting down gracefully...');
    await publisher.quit();
    process.exit(0);
});

// Run the test
if (require.main === module) {
    main().catch(console.error);
}

module.exports = {
    publishGeneralEmail,
    publishTargetedEmail,
    generateSampleEmail
};