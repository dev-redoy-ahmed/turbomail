const mongoose = require('mongoose');

const appUpdateSchema = new mongoose.Schema({
  version_name: {
    type: String,
    required: true,
    trim: true
  },
  version_code: {
    type: Number,
    required: true,
    unique: true
  },
  is_force_update: {
    type: Boolean,
    default: false
  },
  is_normal_update: {
    type: Boolean,
    default: false
  },
  is_active: {
    type: Boolean,
    default: false
  },
  update_message: {
    type: String,
    default: 'A new version is available. Please update for the best experience.'
  },
  update_link: {
    type: String,
    default: 'https://example.com/app-download'
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

// Update the updated_at field before saving
appUpdateSchema.pre('save', function(next) {
  this.updated_at = Date.now();
  next();
});

// Static method to get the latest active update
appUpdateSchema.statics.getLatestUpdate = async function() {
  try {
    const update = await this.findOne({ is_active: true })
      .sort({ version_code: -1 });
    return update;
  } catch (error) {
    console.error('Error getting latest update:', error);
    return null;
  }
};

// Static method to get all updates
appUpdateSchema.statics.getAllUpdates = async function() {
  try {
    const updates = await this.find({}).sort({ version_code: -1 });
    return updates;
  } catch (error) {
    console.error('Error getting all updates:', error);
    return [];
  }
};

// Static method to create or update app version
appUpdateSchema.statics.createOrUpdateVersion = async function(updateData) {
  try {
    // If setting as active, deactivate all other versions
    if (updateData.is_active) {
      await this.updateMany({}, { is_active: false });
    }
    
    const result = await this.findOneAndUpdate(
      { version_code: updateData.version_code },
      { ...updateData, updated_at: Date.now() },
      { upsert: true, new: true }
    );
    
    return result;
  } catch (error) {
    console.error('Error creating/updating app version:', error);
    throw error;
  }
};

// Static method to activate a specific version
appUpdateSchema.statics.activateVersion = async function(versionCode) {
  try {
    // Deactivate all versions first
    await this.updateMany({}, { is_active: false });
    
    // Activate the specified version
    const result = await this.findOneAndUpdate(
      { version_code: versionCode },
      { is_active: true, updated_at: Date.now() },
      { new: true }
    );
    
    return result;
  } catch (error) {
    console.error('Error activating version:', error);
    throw error;
  }
};

// Static method to deactivate a specific version
appUpdateSchema.statics.deactivateVersion = async function(versionCode) {
  try {
    const result = await this.findOneAndUpdate(
      { version_code: versionCode },
      { is_active: false, updated_at: Date.now() },
      { new: true }
    );
    
    return result;
  } catch (error) {
    console.error('Error deactivating version:', error);
    throw error;
  }
};

// Static method to delete a version
appUpdateSchema.statics.deleteVersion = async function(versionCode) {
  try {
    const result = await this.findOneAndDelete({ version_code: versionCode });
    return result;
  } catch (error) {
    console.error('Error deleting version:', error);
    throw error;
  }
};

module.exports = mongoose.model('AppUpdate', appUpdateSchema);