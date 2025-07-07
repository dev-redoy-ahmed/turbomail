# MongoDB TTL (Time To Live) & Email Expiration System

## Overview
The TurboMail application now includes a comprehensive TTL-based email expiration system that automatically manages email lifecycles without requiring Redis. This system uses MongoDB's native TTL indexes for automatic document expiration.

## Key Features

### 🔄 Automatic Expiration
- **TTL Indexes**: MongoDB automatically deletes documents when they expire
- **Default TTL**: 1 hour (3600 seconds) for new emails
- **Custom TTL**: Set custom expiration times per email
- **Periodic Cleanup**: Runs every 30 minutes to deactivate expired emails

### 📧 Email Document Structure
```json
{
  "_id": "ObjectId",
  "email": "user@example.com",
  "deviceId": "device123",
  "ttl": 3600,
  "expiresAt": "2025-07-07T18:56:26.803Z",
  "isActive": true,
  "createdAt": "2025-07-07T17:56:26.803Z",
  "updatedAt": "2025-07-07T17:56:26.803Z",
  "type": "random"
}
```

## API Endpoints

### 1. Store Email with TTL
```http
POST /api/mongodb/emails/store
Content-Type: application/json
X-API-Key: supersecretapikey123

{
  "email": "test@example.com",
  "deviceId": "device123",
  "ttl": 7200,
  "isActive": true
}
```

**Response:**
```json
{
  "message": "Email stored successfully",
  "email": {
    "email": "test@example.com",
    "ttl": 7200,
    "expiresAt": "2025-07-07T19:56:26.803Z",
    "isActive": true
  },
  "id": "ObjectId"
}
```

### 2. Extend Email TTL
```http
PUT /api/mongodb/emails/{id}/extend-ttl
Content-Type: application/json
X-API-Key: supersecretapikey123

{
  "additionalSeconds": 3600
}
```

**Response:**
```json
{
  "message": "Email TTL extended successfully",
  "modifiedCount": 1,
  "additionalSeconds": 3600,
  "newExpiresAt": "2025-07-07T20:56:26.803Z"
}
```

### 3. Check Email Expiration Status
```http
GET /api/mongodb/emails/{id}/expiration
X-API-Key: supersecretapikey123
```

**Response:**
```json
{
  "emailId": "ObjectId",
  "email": "test@example.com",
  "isActive": true,
  "isExpired": false,
  "expiresAt": "2025-07-07T18:56:26.803Z",
  "ttl": 3600,
  "timeUntilExpiryMs": 3540000,
  "timeUntilExpiryHuman": "59 minutes",
  "createdAt": "2025-07-07T17:56:26.803Z",
  "updatedAt": "2025-07-07T17:56:26.803Z"
}
```

### 4. Manual Cleanup
```http
POST /api/mongodb/emails/cleanup
Content-Type: application/json
X-API-Key: supersecretapikey123

{
  "action": "deactivate"  // or "delete"
}
```

**Response:**
```json
{
  "message": "Expired emails deactivated successfully",
  "modifiedCount": 5,
  "action": "deactivated"
}
```

## TTL Management Methods

### MongoDB Manager Methods

#### `saveGeneratedEmail(emailData)`
- Automatically calculates `expiresAt` based on TTL
- Sets default TTL to 3600 seconds (1 hour)
- Adds `isActive`, `createdAt`, and `updatedAt` fields

#### `extendEmailTTL(emailId, additionalSeconds)`
- Extends the expiration time of an existing email
- Updates both `expiresAt` and `ttl` fields
- Logs the new expiration time

#### `cleanupExpiredEmails()`
- Manually deletes expired emails (backup cleanup)
- Returns count of deleted documents

#### `deactivateExpiredEmails()`
- Sets `isActive: false` for expired emails
- Adds `deactivatedAt` timestamp
- Safer alternative to deletion

#### `startPeriodicCleanup(intervalMinutes)`
- Starts automatic cleanup every X minutes (default: 30)
- Runs deactivation cleanup regularly
- Runs deletion cleanup every 2 hours

## TTL Indexes

### Generated Emails Collection
```javascript
// TTL index for automatic expiration
{
  "expiresAt": 1
}
// expireAfterSeconds: 0 (immediate expiration when expiresAt is reached)
```

### Analytics Collection
```javascript
// TTL index for 30-day retention
{
  "timestamp": 1
}
// expireAfterSeconds: 2592000 (30 days)
```

## Usage Examples

### Example 1: Create Email with 2-hour TTL
```javascript
const emailData = {
  email: 'user@example.com',
  deviceId: 'device123',
  ttl: 7200, // 2 hours
  type: 'custom'
};

const result = await mongoManager.saveGeneratedEmail(emailData);
console.log('Email expires at:', result.expiresAt);
```

### Example 2: Extend Email Lifetime
```javascript
const emailId = new ObjectId('...');
const additionalHours = 2;
const additionalSeconds = additionalHours * 3600;

const result = await mongoManager.extendEmailTTL(emailId, additionalSeconds);
console.log('TTL extended successfully');
```

### Example 3: Check Expiration Status
```javascript
const collection = mongoManager.getCollection('generated_emails');
const email = await collection.findOne({ _id: emailId });

const now = new Date();
const isExpired = new Date(email.expiresAt) < now;
const minutesLeft = Math.floor((new Date(email.expiresAt) - now) / 1000 / 60);

console.log(`Email expires in ${minutesLeft} minutes`);
```

## Automatic Cleanup Process

### 1. MongoDB TTL Index
- **Primary mechanism**: MongoDB automatically deletes expired documents
- **Frequency**: Runs approximately every 60 seconds
- **Precision**: May take up to 60 seconds after expiration

### 2. Periodic Deactivation (Every 30 minutes)
- Finds emails where `expiresAt < now`
- Sets `isActive: false`
- Adds `deactivatedAt` timestamp
- Preserves data for analytics

### 3. Manual Deletion (Every 2 hours)
- Permanently removes expired documents
- Backup cleanup mechanism
- Reduces database size

## Configuration

### Default Settings
```javascript
const DEFAULT_TTL = 3600; // 1 hour
const CLEANUP_INTERVAL = 30; // 30 minutes
const ANALYTICS_RETENTION = 30 * 24 * 60 * 60; // 30 days
```

### Customization
```javascript
// Start cleanup with custom interval
mongoManager.startPeriodicCleanup(15); // Every 15 minutes

// Create email with custom TTL
const emailData = {
  email: 'test@example.com',
  deviceId: 'device123',
  ttl: 1800 // 30 minutes
};
```

## Benefits

### ✅ Advantages
- **No Redis Dependency**: Works without Redis for TTL functionality
- **Automatic Cleanup**: MongoDB handles expiration automatically
- **Flexible TTL**: Different expiration times per email
- **Data Preservation**: Option to deactivate instead of delete
- **Backup Cleanup**: Manual cleanup as fallback
- **Analytics Retention**: Automatic cleanup of old analytics data

### 🔧 Monitoring
- **Logs**: Detailed logging for all TTL operations
- **API Endpoints**: Check expiration status via API
- **Health Checks**: Monitor cleanup process status
- **Error Handling**: Graceful fallback when MongoDB unavailable

## Troubleshooting

### Common Issues

1. **TTL Index Not Working**
   - Check if MongoDB connection is established
   - Verify TTL indexes are created: `db.generated_emails.getIndexes()`
   - Ensure `expiresAt` field is a valid Date object

2. **Emails Not Expiring**
   - Check `expiresAt` field format
   - Verify TTL index exists with `expireAfterSeconds: 0`
   - MongoDB TTL cleanup runs every ~60 seconds

3. **Periodic Cleanup Not Running**
   - Check MongoDB connection status
   - Verify `startPeriodicCleanup()` was called
   - Check server logs for cleanup messages

### Debug Commands
```javascript
// Check TTL indexes
db.generated_emails.getIndexes()

// Find expired emails
db.generated_emails.find({ expiresAt: { $lt: new Date() } })

// Check cleanup interval
console.log(mongoManager.cleanupInterval)
```

This TTL system provides robust email lifecycle management without external dependencies, ensuring emails are automatically cleaned up while maintaining flexibility for different use cases.