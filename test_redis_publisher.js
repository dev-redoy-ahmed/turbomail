#!/usr/bin/env node

/**
 * Test Redis Publisher for TurboMail
 * This script simulates external email notifications (like from Haraka plugin)
 * Usage: node test_redis_publisher.js
 */

const redis = require('redis');
const crypto = require('crypto');

// Configuration
const config = {
    redis: {
        url: process.env.REDIS_URL || 'redis://:we1we2we3@165.22.97.51:6379'
    }
};

// Create Redis client for publishing
const publisher = redis.createClient({
    url: config.redis.url
});

publisher.on('error', (err) => {
    console.error('❌ Redis Publisher Error:', err.message);
});

publisher.on('connect', () => {
    console.log('✅ Redis Publisher Connected');
});

// Sample email data generator
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
        from: sender,
        subject: subject,
        text: `This is a test email sent to ${recipientEmail} from ${sender}.\n\nContent: ${subject}\n\nBest regards,\nTest System`,
        html: `<h2>${subject}</h2><p>This is a test email sent to <strong>${recipientEmail}</strong> from <em>${sender}</em>.</p><p>Content: ${subject}</p><p>Best regards,<br>Test System</p>`,
        timestamp: new Date().toISOString(),
        id: crypto.randomBytes(16).toString('hex')
    };
}

// Publish email notification to general channel
async function publishGeneralEmail(recipientEmail) {
    const emailMessage = generateSampleEmail(recipientEmail);
    
    const notification = {
        to: recipientEmail,
        message: emailMessage
    };
    
    await publisher.publish('new_email', JSON.stringify(notification));
    console.log(`📨 Published general email notification for: ${recipientEmail}`);
    console.log(`   Subject: ${emailMessage.subject}`);
    console.log(`   From: ${emailMessage.from}`);
}

// Publish email notification to specific channel
async function publishTargetedEmail(recipientEmail) {
    const emailMessage = generateSampleEmail(recipientEmail);
    
    await publisher.publish(`channel:email:${recipientEmail}`, JSON.stringify(emailMessage));
    console.log(`🎯 Published targeted email notification for: ${recipientEmail}`);
    console.log(`   Subject: ${emailMessage.subject}`);
    console.log(`   From: ${emailMessage.from}`);
}

// Main test function
async function runTests() {
    try {
        await publisher.connect();
        console.log('🚀 Starting Redis Publisher Tests...');
        console.log('=' .repeat(50));
        
        // Test emails
        const testEmails = [
            'test@turbomail.dev',
            'demo@example.com',
            'user@test.com'
        ];
        
        // Publish general notifications
        console.log('\n📢 Testing General Email Notifications:');
        for (const email of testEmails) {
            await publishGeneralEmail(email);
            await new Promise(resolve => setTimeout(resolve, 1000)); // 1 second delay
        }
        
        // Publish targeted notifications
        console.log('\n🎯 Testing Targeted Email Notifications:');
        for (const email of testEmails) {
            await publishTargetedEmail(email);
            await new Promise(resolve => setTimeout(resolve, 1000)); // 1 second delay
        }
        
        console.log('\n✅ All test notifications published successfully!');
        console.log('📝 Check your TurboMail server logs to see if notifications were received.');
        console.log('🌐 Open your TurboMail app to see real-time notifications.');
        
    } catch (error) {
        console.error('❌ Test failed:', error.message);
    } finally {
        await publisher.quit();
        console.log('\n🔌 Redis Publisher disconnected.');
        process.exit(0);
    }
}

// Handle command line arguments
if (process.argv.length > 2) {
    const customEmail = process.argv[2];
    console.log(`🎯 Testing with custom email: ${customEmail}`);
    
    publisher.connect().then(async () => {
        await publishGeneralEmail(customEmail);
        await new Promise(resolve => setTimeout(resolve, 500));
        await publishTargetedEmail(customEmail);
        await publisher.quit();
        console.log('✅ Custom email test completed!');
        process.exit(0);
    }).catch(error => {
        console.error('❌ Error:', error.message);
        process.exit(1);
    });
} else {
    // Run full test suite
    runTests();
}

// Handle process termination
process.on('SIGINT', async () => {
    console.log('\n🛑 Test interrupted, cleaning up...');
    try {
        await publisher.quit();
    } catch (error) {
        // Ignore cleanup errors
    }
    process.exit(0);
});