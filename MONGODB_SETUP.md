# MongoDB Atlas Connection Setup Guide

## Current Issue
The TurboMail application is experiencing SSL/TLS connection errors when trying to connect to MongoDB Atlas:

```
Error: SSL routines:ssl3_read_bytes:tlsv1 alert internal error (SSL alert number 80)
```

## Database Credentials
- **Database Name:** turbomail
- **Password:** we1we2we3
- **Connection String:** mongodb+srv://turbomail:we1we2we3@turbomail.gjohjma.mongodb.net/turbomail

## Common Causes & Solutions

### 1. IP Address Not Whitelisted (Most Common)
**Problem:** Your current IP address is not added to the MongoDB Atlas IP Access List.

**Solution:**
1. Go to [MongoDB Atlas](https://cloud.mongodb.com/)
2. Navigate to your project
3. Go to **Security** → **Network Access**
4. Click **Add IP Address**
5. Either:
   - Add your current IP address
   - Add `0.0.0.0/0` for testing (allows all IPs - not recommended for production)

### 2. Network Connectivity Issues
**Problem:** Firewall or network restrictions blocking MongoDB Atlas access.

**Solution:**
- Ensure ports 27017-27019 are open
- Check if corporate firewall is blocking MongoDB Atlas
- Try connecting from a different network

### 3. MongoDB Atlas Cluster Issues
**Problem:** The cluster might be paused or having issues.

**Solution:**
1. Check cluster status in MongoDB Atlas dashboard
2. Ensure the cluster is running (not paused)
3. Verify the connection string is correct

## Testing Connection

Run the test script to verify connection:
```bash
node test_mongodb.js
```

## Application Behavior

### When MongoDB is Connected:
- ✅ Email history is stored and retrievable
- ✅ Device tracking works
- ✅ Analytics are collected
- ✅ Full functionality available

### When MongoDB is NOT Connected:
- ⚠️ Email generation still works
- ❌ Email history is not stored
- ❌ Device tracking is disabled
- ❌ Analytics are not collected
- 🔄 Application runs in "standalone mode"

## Error Messages

The application now provides clear error messages:
- **503 Service Unavailable:** When MongoDB is not connected
- **Fallback responses:** Empty arrays for list endpoints
- **Clear instructions:** What to check and fix

## Next Steps

1. **Immediate:** Whitelist your IP address in MongoDB Atlas
2. **Verify:** Run the test script to confirm connection
3. **Restart:** Restart the TurboMail server
4. **Test:** Check if email history and device tracking work

## Support

If issues persist:
1. Check MongoDB Atlas status page
2. Verify your internet connection
3. Try connecting from a different location/network
4. Contact MongoDB Atlas support if needed