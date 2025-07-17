#!/usr/bin/env node

/**
 * Test Script: API Key Update Verification
 * This script tests if the API key is properly updated across all components
 */

const fs = require('fs').promises;
const path = require('path');

async function testApiKeyUpdate() {
  console.log('🧪 Testing API Key Update System...\n');
  
  const testApiKey = 'test-key-' + Date.now();
  console.log(`🔑 Test API Key: ${testApiKey}\n`);
  
  try {
    // 1. Check config.js
    const configPath = path.join(__dirname, 'config.js');
    const configContent = await fs.readFile(configPath, 'utf8');
    const configMatch = configContent.match(/MASTER_KEY:\s*['"`]([^'"`]+)['"`]/);
    const configApiKey = configMatch ? configMatch[1] : 'NOT_FOUND';
    console.log(`📄 config.js API Key: ${configApiKey}`);
    
    // 2. Check mail-api/index.js
    const mailApiPath = path.join(__dirname, 'mail-api/index.js');
    const mailApiContent = await fs.readFile(mailApiPath, 'utf8');
    const usesConfig = mailApiContent.includes('config.API.MASTER_KEY');
    console.log(`📧 mail-api uses config: ${usesConfig ? '✅' : '❌'}`);
    
    // 3. Check Haraka plugin
    const harakaPath = path.join(__dirname, 'haraka-server/plugins/forward_to_api.js');
    const harakaContent = await fs.readFile(harakaPath, 'utf8');
    const harakaUsesConfig = harakaContent.includes('config.API.MASTER_KEY');
    console.log(`📨 Haraka plugin uses config: ${harakaUsesConfig ? '✅' : '❌'}`);
    
    // 4. Check ecosystem.config.json
    const ecosystemPath = path.join(__dirname, 'ecosystem.config.json');
    try {
      const ecosystemContent = await fs.readFile(ecosystemPath, 'utf8');
      const ecosystem = JSON.parse(ecosystemContent);
      const hasEnvVar = ecosystem.apps.some(app => app.env && app.env.API_MASTER_KEY);
      console.log(`🚀 ecosystem.config.json has env var: ${hasEnvVar ? '✅' : '❌'}`);
    } catch (error) {
      console.log(`🚀 ecosystem.config.json: ❌ (${error.message})`);
    }
    
    console.log('\n📊 Test Results:');
    console.log('================');
    console.log(`✅ Configuration centralized: ${usesConfig && harakaUsesConfig ? 'PASS' : 'FAIL'}`);
    console.log(`✅ API Key readable: ${configApiKey !== 'NOT_FOUND' ? 'PASS' : 'FAIL'}`);
    console.log(`✅ Current API Key: ${configApiKey}`);
    
    console.log('\n💡 To test API key update:');
    console.log('1. Go to Admin Panel: http://localhost:3006');
    console.log('2. Navigate to API Management');
    console.log('3. Update the API key');
    console.log('4. Check console logs for update confirmation');
    console.log('5. Run this script again to verify changes');
    
  } catch (error) {
    console.error('❌ Test failed:', error.message);
  }
}

// Run the test
testApiKeyUpdate();