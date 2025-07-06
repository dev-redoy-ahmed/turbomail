# TurboMail Admin Panel

A simple admin panel for managing the TurboMail temporary email API.

## Features

- 📩 Display all API endpoints with examples
- 🌐 Add and delete domains
- 🧪 Test API functionality
- 📊 Simple and clean interface

## API Endpoints

| Function | Method | URL |
|----------|--------|-----|
| Auto-generate random email | GET | `http://165.22.97.51:3001/generate?key=supersecretapikey123` |
| Manually generate email | GET | `http://165.22.97.51:3001/generate/manual?username=rahul&domain=oplex.online&key=supersecretapikey123` |
| Get inbox for any email | GET | `http://165.22.97.51:3001/inbox/dd@oplex.online?key=supersecretapikey123` |
| Get specific message from inbox | GET | `http://165.22.97.51:3001/inbox/dd@oplex.online/0?key=supersecretapikey123` |
| Delete all messages from inbox | DELETE | `http://165.22.97.51:3001/delete/dd@oplex.online?key=supersecretapikey123` |
| Delete specific message by index | DELETE | `http://165.22.97.51:3001/delete/dd@oplex.online/0?key=supersecretapikey123` |

## Setup

1. Install dependencies:
```bash
npm install
```

2. Start the server:
```bash
npm start
```

3. Open your browser and go to:
```
http://localhost:3001
```

## Configuration

- **API Key**: `supersecretapikey123`
- **Redis Password**: `we1we2we3`
- **Default Port**: `3001`

## Domain Management

The admin panel allows you to:
- View all available domains
- Add new domains
- Delete existing domains

Domains are stored in `domains.txt` file.

## Requirements

- Node.js
- Redis server running with password `we1we2we3`
- Haraka mail server (for receiving emails)

## Notes

- Make sure Redis is running and accessible
- The API key is required for all API endpoints
- Domains must be properly configured in your mail server