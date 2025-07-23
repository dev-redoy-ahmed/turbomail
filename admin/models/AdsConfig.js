const mongoose = require('mongoose');

const adsConfigSchema = new mongoose.Schema({
  platform: {
    type: String,
    required: true,
    enum: ['android', 'ios'],
    default: 'android'
  },
  adType: {
    type: String,
    required: true,
    enum: ['banner', 'interstitial', 'native', 'appopen', 'reward'],
  },
  ads_id: {
    type: String,
    required: true,
    trim: true
  },
  created_at: {
    type: Date,
    default: Date.now
  },
  updated_at: {
    type: Date,
    default: Date.now
  }
});

// Create compound unique index for platform + adType
adsConfigSchema.index({ platform: 1, adType: 1 }, { unique: true });

// Update the updated_at field before saving
adsConfigSchema.pre('save', function(next) {
  this.updated_at = Date.now();
  next();
});

// Static method to get all ads config
adsConfigSchema.statics.getAllAdsConfig = async function() {
  try {
    const allAds = await this.find({});
    const adsConfig = {
      android: {},
      ios: {}
    };
    
    allAds.forEach(ad => {
      adsConfig[ad.platform][ad.adType] = ad.ads_id;
    });
    
    return adsConfig;
  } catch (error) {
    console.error('Error getting all ads config:', error);
    return { android: {}, ios: {} };
  }
};

// Static method to get platform-specific ads config
adsConfigSchema.statics.getPlatformAdsConfig = async function(platform) {
  try {
    const platformAds = await this.find({ platform: platform });
    const adsConfig = {};
    
    platformAds.forEach(ad => {
      adsConfig[ad.adType] = ad.ads_id;
    });
    
    return adsConfig;
  } catch (error) {
    console.error('Error getting platform ads config:', error);
    return {};
  }
};

// Static method to update or create ad config
adsConfigSchema.statics.updateAdConfig = async function(platform, adType, ads_id) {
  try {
    const result = await this.findOneAndUpdate(
      { platform: platform, adType: adType },
      { ads_id: ads_id, updated_at: Date.now() },
      { upsert: true, new: true }
    );
    
    return result;
  } catch (error) {
    console.error('Error updating ad config:', error);
    throw error;
  }
};

// Static method to get specific ad config
adsConfigSchema.statics.getAdConfig = async function(platform, adType) {
  try {
    const ad = await this.findOne({ platform: platform, adType: adType });
    return ad ? ad.ads_id : '';
  } catch (error) {
    console.error('Error getting ad config:', error);
    return '';
  }
};

module.exports = mongoose.model('AdsConfig', adsConfigSchema);