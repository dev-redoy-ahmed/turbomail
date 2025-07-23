const mongoose = require('mongoose');

const adsConfigSchema = new mongoose.Schema({
  adType: {
    type: String,
    required: true,
    enum: ['banner', 'interstitial', 'native', 'appopen', 'reward']
  },
  platform: {
    type: String,
    required: true,
    enum: ['android', 'ios']
  },
  adId: {
    type: String,
    required: true,
    trim: true
  },
  isActive: {
    type: Boolean,
    default: true
  },
  description: {
    type: String,
    default: ''
  },
  createdAt: {
    type: Date,
    default: Date.now
  },
  updatedAt: {
    type: Date,
    default: Date.now
  }
});

// Create compound unique index for adType + platform
adsConfigSchema.index({ adType: 1, platform: 1 }, { unique: true });

// Update the updatedAt field before saving
adsConfigSchema.pre('save', function(next) {
  this.updatedAt = Date.now();
  next();
});

// Static method to get all ads config organized by platform
adsConfigSchema.statics.getAllAdsConfig = async function() {
  try {
    const allAds = await this.find({});
    
    // Initialize the structure with empty objects for all ad types
    const adsConfig = {
      android: {
        banner: { id: '', description: '', isActive: false },
        interstitial: { id: '', description: '', isActive: false },
        native: { id: '', description: '', isActive: false },
        appopen: { id: '', description: '', isActive: false },
        reward: { id: '', description: '', isActive: false }
      },
      ios: {
        banner: { id: '', description: '', isActive: false },
        interstitial: { id: '', description: '', isActive: false },
        native: { id: '', description: '', isActive: false },
        appopen: { id: '', description: '', isActive: false },
        reward: { id: '', description: '', isActive: false }
      }
    };
    
    // Populate with actual data
    allAds.forEach(ad => {
      if (adsConfig[ad.platform] && adsConfig[ad.platform][ad.adType]) {
        adsConfig[ad.platform][ad.adType] = {
          id: ad.adId,
          description: ad.description,
          isActive: ad.isActive
        };
      }
    });
    
    return adsConfig;
  } catch (error) {
    console.error('Error getting all ads config:', error);
    // Return default structure on error
    return {
      android: {
        banner: { id: '', description: '', isActive: false },
        interstitial: { id: '', description: '', isActive: false },
        native: { id: '', description: '', isActive: false },
        appopen: { id: '', description: '', isActive: false },
        reward: { id: '', description: '', isActive: false }
      },
      ios: {
        banner: { id: '', description: '', isActive: false },
        interstitial: { id: '', description: '', isActive: false },
        native: { id: '', description: '', isActive: false },
        appopen: { id: '', description: '', isActive: false },
        reward: { id: '', description: '', isActive: false }
      }
    };
  }
};

// Static method to update or create ad config
adsConfigSchema.statics.updateAdConfig = async function(adType, platform, adId, options = {}) {
  try {
    const updateData = {
      adId: adId,
      ...options,
      updatedAt: Date.now()
    };
    
    const result = await this.findOneAndUpdate(
      { adType: adType, platform: platform },
      updateData,
      { upsert: true, new: true }
    );
    
    return result;
  } catch (error) {
    console.error('Error updating ad config:', error);
    throw error;
  }
};

// Static method to get specific ad config
adsConfigSchema.statics.getAdConfig = async function(adType, platform) {
  try {
    const ad = await this.findOne({ adType: adType, platform: platform });
    if (!ad) return null;
    
    return {
      id: ad.adId,
      isActive: ad.isActive,
      description: ad.description
    };
  } catch (error) {
    console.error('Error getting ad config:', error);
    return null;
  }
};

// Static method to get ads config for API (by platform)
adsConfigSchema.statics.getAdsByPlatform = async function(platform) {
  try {
    const ads = await this.find({ platform: platform, isActive: true });
    const adsConfig = {};
    
    ads.forEach(ad => {
      adsConfig[ad.adType] = ad.adId;
    });
    
    return adsConfig;
  } catch (error) {
    console.error('Error getting ads by platform:', error);
    return {};
  }
};

module.exports = mongoose.model('AdsConfig', adsConfigSchema);