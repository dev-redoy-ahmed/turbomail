// Test script for Flutter app integration
// This script tests the new ads and app updates API endpoints

const axios = require('axios');

const BASE_URL = 'http://localhost:3001';
const API_KEY = 'tempmail-master-key-2024';

async function testAdsConfig() {
  console.log('🧪 Testing Ads Configuration API...');
  
  try {
    // Test Android platform
    const androidResponse = await axios.get(`${BASE_URL}/ads-config?platform=android&key=${API_KEY}`);
    console.log('✅ Android Ads Config:', JSON.stringify(androidResponse.data, null, 2));
    
    // Test iOS platform
    const iosResponse = await axios.get(`${BASE_URL}/ads-config?platform=ios&key=${API_KEY}`);
    console.log('✅ iOS Ads Config:', JSON.stringify(iosResponse.data, null, 2));
    
    // Test both platforms
    const bothResponse = await axios.get(`${BASE_URL}/ads-config?platform=both&key=${API_KEY}`);
    console.log('✅ Both Platforms Ads Config:', JSON.stringify(bothResponse.data, null, 2));
    
  } catch (error) {
    console.error('❌ Ads Config Test Failed:', error.response?.data || error.message);
  }
}

async function testAppUpdates() {
  console.log('\n🧪 Testing App Updates API...');
  
  try {
    // Test Android platform
    const androidResponse = await axios.get(`${BASE_URL}/app-updates?platform=android&key=${API_KEY}`);
    console.log('✅ Android App Updates:', JSON.stringify(androidResponse.data, null, 2));
    
    // Test iOS platform
    const iosResponse = await axios.get(`${BASE_URL}/app-updates?platform=ios&key=${API_KEY}`);
    console.log('✅ iOS App Updates:', JSON.stringify(iosResponse.data, null, 2));
    
    // Test both platforms
    const bothResponse = await axios.get(`${BASE_URL}/app-updates?platform=both&key=${API_KEY}`);
    console.log('✅ Both Platforms App Updates:', JSON.stringify(bothResponse.data, null, 2));
    
  } catch (error) {
    console.error('❌ App Updates Test Failed:', error.response?.data || error.message);
  }
}

async function testInvalidApiKey() {
  console.log('\n🧪 Testing Invalid API Key...');
  
  try {
    const response = await axios.get(`${BASE_URL}/ads-config?platform=android&key=invalid-key`);
    console.log('❌ Should have failed with invalid key');
  } catch (error) {
    if (error.response?.status === 403) {
      console.log('✅ Invalid API Key properly rejected');
    } else {
      console.error('❌ Unexpected error:', error.response?.data || error.message);
    }
  }
}

async function runAllTests() {
  console.log('🚀 Starting Flutter App Integration Tests...\n');
  
  await testAdsConfig();
  await testAppUpdates();
  await testInvalidApiKey();
  
  console.log('\n✅ All tests completed!');
  console.log('\n📱 Flutter App Integration Guide:');
  console.log('1. Use these endpoints in your Flutter app');
  console.log('2. Replace localhost with your VPS IP for production');
  console.log('3. Store API key securely in your app');
  console.log('4. Handle platform-specific responses');
}

// Run tests if this file is executed directly
if (require.main === module) {
  runAllTests().catch(console.error);
}

module.exports = {
  testAdsConfig,
  testAppUpdates,
  testInvalidApiKey,
  runAllTests
};