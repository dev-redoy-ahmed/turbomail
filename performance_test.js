#!/usr/bin/env node

/**
 * Performance Test for Redis Notification Delays
 * This script measures the time between Redis publish and WebSocket broadcast
 */

const redis = require('redis');
const { io } = require('socket.io-client');
const crypto = require('crypto');

// Configuration
const config = {
    redis: {
        url: process.env.REDIS_URL || 'redis://:we1we2we3@165.22.97.51:6379'
    },
    websocket: {
        url: 'http://localhost:3001'
    }
};

// Performance metrics
const metrics = {
    publishTimes: [],
    receiveTimes: [],
    delays: []
};

class PerformanceTest {
    constructor() {
        this.publisher = null;
        this.socket = null;
        this.testEmail = 'performance-test@example.com';
        this.testCount = 10;
        this.currentTest = 0;
    }

    async initialize() {
        try {
            // Setup Redis publisher
            this.publisher = redis.createClient({ url: config.redis.url });
            await this.publisher.connect();
            console.log('✅ Redis Publisher Connected');

            // Setup WebSocket client
            this.socket = io(config.websocket.url);
            
            this.socket.on('connect', () => {
                console.log('✅ WebSocket Connected');
                // Subscribe to test email notifications
                this.socket.emit('subscribe-email', this.testEmail);
            });

            this.socket.on('subscribed', (data) => {
                console.log(`✅ Subscribed to: ${data.email}`);
                this.startPerformanceTest();
            });

            this.socket.on('new-email', (data) => {
                this.handleEmailReceived(data);
            });

            this.socket.on('disconnect', () => {
                console.log('❌ WebSocket Disconnected');
            });

        } catch (error) {
            console.error('❌ Initialization failed:', error.message);
            process.exit(1);
        }
    }

    async startPerformanceTest() {
        console.log('\n🚀 Starting Performance Test...');
        console.log(`📊 Running ${this.testCount} tests with ${this.testEmail}`);
        console.log('=' .repeat(60));

        for (let i = 0; i < this.testCount; i++) {
            this.currentTest = i + 1;
            await this.runSingleTest();
            // Wait between tests to avoid overwhelming
            await this.sleep(500);
        }
    }

    async runSingleTest() {
        const testId = crypto.randomUUID();
        const publishTime = Date.now();
        
        // Store publish time for this test
        metrics.publishTimes[this.currentTest - 1] = { testId, time: publishTime };

        const emailData = {
            id: testId,
            from: 'performance-test@system.com',
            subject: `Performance Test #${this.currentTest} - ${testId}`,
            body: `This is a performance test email sent at ${new Date(publishTime).toISOString()}`,
            timestamp: new Date(publishTime).toISOString(),
            to: this.testEmail
        };

        console.log(`📤 Test ${this.currentTest}: Publishing at ${publishTime}`);
        
        // Publish to Redis
        await this.publisher.publish(`channel:email:${this.testEmail}`, JSON.stringify(emailData));
    }

    handleEmailReceived(data) {
        const receiveTime = Date.now();
        const testId = data.message.id;
        
        // Find corresponding publish time
        const publishData = metrics.publishTimes.find(p => p.testId === testId);
        
        if (publishData) {
            const delay = receiveTime - publishData.time;
            metrics.receiveTimes.push({ testId, time: receiveTime });
            metrics.delays.push(delay);
            
            console.log(`📥 Test ${this.currentTest}: Received after ${delay}ms delay`);
            
            // Check if all tests completed
            if (metrics.delays.length === this.testCount) {
                this.showResults();
            }
        }
    }

    showResults() {
        console.log('\n' + '=' .repeat(60));
        console.log('📊 PERFORMANCE TEST RESULTS');
        console.log('=' .repeat(60));
        
        const delays = metrics.delays;
        const avgDelay = delays.reduce((a, b) => a + b, 0) / delays.length;
        const minDelay = Math.min(...delays);
        const maxDelay = Math.max(...delays);
        
        console.log(`📈 Average Delay: ${avgDelay.toFixed(2)}ms`);
        console.log(`⚡ Minimum Delay: ${minDelay}ms`);
        console.log(`🐌 Maximum Delay: ${maxDelay}ms`);
        console.log(`📊 Total Tests: ${delays.length}`);
        
        // Show individual results
        console.log('\n📋 Individual Test Results:');
        delays.forEach((delay, index) => {
            const status = delay > 100 ? '🔴' : delay > 50 ? '🟡' : '🟢';
            console.log(`   Test ${index + 1}: ${delay}ms ${status}`);
        });
        
        // Performance analysis
        console.log('\n🔍 Performance Analysis:');
        if (avgDelay > 100) {
            console.log('❌ HIGH DELAY DETECTED - Average > 100ms');
            console.log('   Possible causes:');
            console.log('   - Redis network latency');
            console.log('   - WebSocket processing delays');
            console.log('   - Server overload');
        } else if (avgDelay > 50) {
            console.log('⚠️  MODERATE DELAY - Average > 50ms');
            console.log('   Consider optimizing notification pipeline');
        } else {
            console.log('✅ GOOD PERFORMANCE - Average < 50ms');
        }
        
        this.cleanup();
    }

    async cleanup() {
        console.log('\n🧹 Cleaning up...');
        if (this.socket) {
            this.socket.disconnect();
        }
        if (this.publisher) {
            await this.publisher.quit();
        }
        console.log('✅ Cleanup complete');
        process.exit(0);
    }

    sleep(ms) {
        return new Promise(resolve => setTimeout(resolve, ms));
    }
}

// Run the performance test
const test = new PerformanceTest();
test.initialize().catch(error => {
    console.error('❌ Test failed:', error.message);
    process.exit(1);
});

// Handle graceful shutdown
process.on('SIGINT', () => {
    console.log('\n🛑 Test interrupted by user');
    test.cleanup();
});