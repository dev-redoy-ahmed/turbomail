// Simple test without external dependencies
const http = require('http');

function testAPI(path, description) {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: 'localhost',
      port: 3001,
      path: path,
      method: 'GET'
    };

    const req = http.request(options, (res) => {
      let data = '';
      
      res.on('data', (chunk) => {
        data += chunk;
      });
      
      res.on('end', () => {
        console.log(`✅ ${description}:`);
        console.log(`Status: ${res.statusCode}`);
        try {
          const jsonData = JSON.parse(data);
          console.log('Response:', JSON.stringify(jsonData, null, 2));
        } catch (e) {
          console.log('Response:', data);
        }
        console.log('---');
        resolve(data);
      });
    });

    req.on('error', (err) => {
      console.error(`❌ ${description} failed:`, err.message);
      reject(err);
    });

    req.end();
  });
}

async function runTests() {
  console.log('🚀 Testing TurboMail API Endpoints...\n');
  
  try {
    // Test ads config
    await testAPI('/ads-config?platform=android&key=tempmail-master-key-2024', 'Ads Config (Android)');
    await testAPI('/ads-config?platform=ios&key=tempmail-master-key-2024', 'Ads Config (iOS)');
    
    // Test app updates
    await testAPI('/app-updates?platform=android&key=tempmail-master-key-2024', 'App Updates (Android)');
    await testAPI('/app-updates?platform=ios&key=tempmail-master-key-2024', 'App Updates (iOS)');
    
    // Test invalid API key
    await testAPI('/ads-config?platform=android&key=invalid-key', 'Invalid API Key Test');
    
    console.log('✅ All tests completed!');
    
  } catch (error) {
    console.error('❌ Test failed:', error.message);
  }
}

runTests();