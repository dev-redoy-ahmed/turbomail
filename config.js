// TurboMail Configuration
// This file contains all the configuration settings for TurboMail

module.exports = {
  // API Configuration
  API: {
    PORT: 3001,
    MASTER_KEY: 'tempmail-master-key-2024',
    ALLOWED_DOMAINS: ['oplex.online', 'agrovia.store']
  },

  // Admin Panel Configuration
  ADMIN: {
    PORT: 3006,
    USERNAME: 'admin',
    PASSWORD: 'admin123'
  },

  // SMTP Server Configuration
  SMTP: {
    PORT: 25,
    HOST: '127.0.0.1'
  },

  // Redis Configuration
  REDIS: {
    HOST: '127.0.0.1',
    PORT: 6379
  },

  // Email Settings
  EMAIL: {
    EXPIRY_TIME: 3600, // 1 hour in seconds
    MAX_MESSAGE_SIZE: '20mb'
  }
};