const http = require('http');
const { PassThrough } = require('stream');
const config = require('../../../config.js');




exports.hook_queue = function (next, connection) {
  const txn = connection.transaction;
  if (!txn || !txn.message_stream) {
    connection.logerror(this, '❌ No message stream.');
    return next();
  }

  const recipient = txn.rcpt_to?.[0]?.address()?.toLowerCase() || 'unknown@domain.com';

  const pass = new PassThrough();
  const chunks = [];

  pass.on('data', chunk => {
    if (chunk) chunks.push(chunk);
  });

  pass.on('end', () => {
    const raw = Buffer.concat(chunks);

    connection.loginfo(this, `📨 Safely received mail for: ${recipient}`);

    // Prepare HTTP request options for forwarding the email to your API
    const options = {
      hostname: config.SMTP.HOST, // usually '127.0.0.1' if API is local
      port: config.API.PORT,      // port where your API listens
      path: `/incoming/raw?to=${encodeURIComponent(recipient)}&key=${config.API.MASTER_KEY}`,
      method: 'POST',
      headers: {
        'Content-Type': 'application/octet-stream',
        'Content-Length': raw.length
      }
    };

    // Send the raw email data to the API endpoint
    const req = http.request(options, res => {
      connection.loginfo(this, `✅ Mail forwarded: ${res.statusCode}`);

      let responseBody = '';
      res.on('data', chunk => { responseBody += chunk; });
      res.on('end', () => {
        if (res.statusCode !== 200) {
          connection.logerror(this, `❌ API response error: ${responseBody}`);
        } else {
          connection.loginfo(this, `📧 Email successfully processed for ${recipient}`);
        }
      });
    });

    req.on('error', err => {
      connection.logerror(this, `❌ API error: ${err.message}`);
    });

    req.write(raw);
    req.end();

    // Continue processing in Haraka
    next();
  });

  txn.message_stream.pipe(pass);
};
