const mongoose = require('mongoose');

const appUpdateSchema = new mongoose.Schema({
  versionName: {
    type: String,
    required: true,
    trim: true
  },
  versionCode: {
    type: Number,
    required: true,
    unique: true
  },
  isForceUpdate: {
    type: Boolean,
    default: false
  },
  isNormalUpdate: {
    type: Boolean,
    default: false
  },
  isActive: {
    type: Boolean,
    default: false
  },
  updateMessage: {
    type: String,
    default: ''
  },
  updateLink: {
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

// Update the updatedAt field before saving
appUpdateSchema.pre('save', function(next) {
  this.updatedAt = Date.now();
  next();
});

// Static method to get the latest active update
appUpdateSchema.statics.getLatestUpdate = async function() {
  try {
    const update = await this.findOne({ isActive: true })
      .sort({ versionCode: -1 });
    return update;
  } catch (error) {
    console.error('Error getting latest update:', error);
    return null;
  }
};

// Static method to get all updates
appUpdateSchema.statics.getAllUpdates = async function() {
  try {
    const updates = await this.find({}).sort({ versionCode: -1 });
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
    if (updateData.isActive) {
      await this.updateMany({}, { isActive: false });
    }
    
    const result = await this.findOneAndUpdate(
      { versionCode: updateData.versionCode },
      { ...updateData, updatedAt: Date.now() },
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
    await this.updateMany({}, { isActive: false });
    
    // Activate the specified version
    const result = await this.findOneAndUpdate(
      { versionCode: versionCode },
      { isActive: true, updatedAt: Date.now() },
      { new: true }
    );
    
    return result;
  } catch (error) {
    console.error('Error activating version:', error);
    throw error;
  }
};

// Static method to delete a version
appUpdateSchema.statics.deleteVersion = async function(versionCode) {
  try {
    const result = await this.findOneAndDelete({ versionCode: versionCode });
    return result;
  } catch (error) {
    console.error('Error deleting version:', error);
    throw error;
  }
};

module.exports = mongoose.model('AppUpdate', appUpdateSchema);