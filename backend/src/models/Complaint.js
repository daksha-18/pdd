const mongoose = require('mongoose');

const complaintSchema = new mongoose.Schema(
  {
    complaintId: {
      type: String,
      unique: true,
    },
    title: {
      type: String,
      required: [true, 'Title is required'],
      trim: true,
      maxlength: [100, 'Title cannot exceed 100 characters'],
    },
    description: {
      type: String,
      required: [true, 'Description is required'],
      trim: true,
      maxlength: [1000, 'Description cannot exceed 1000 characters'],
    },
    category: {
      type: String,
      required: [true, 'Category is required'],
      enum: ['electrical', 'water', 'internet', 'cleaning', 'furniture', 'security', 'other'],
    },
    priority: {
      type: String,
      enum: ['low', 'medium', 'high', 'urgent'],
      default: 'medium',
    },
    status: {
      type: String,
      enum: ['pending', 'assigned', 'in_progress', 'resolved', 'closed', 'rejected', 'withdrawn'],
      default: 'pending',
    },
    submittedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    assignedTo: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
    },
    location: {
      hostelBlock: { type: String, required: true },
      roomNumber: { type: String, required: true },
      floor: { type: String },
      landmark: { type: String },
    },
    images: [
      {
        url: String,
        publicId: String,
      },
    ],
    completionImages: [
      {
        url: String,
        publicId: String,
      },
    ],
    resolutionNotes: {
      type: String,
      default: '',
    },
    feedback: {
      rating: { type: Number, min: 1, max: 5 },
      comment: { type: String },
      submittedAt: { type: Date },
    },
    statusHistory: [
      {
        status: String,
        changedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
        notes: String,
        timestamp: { type: Date, default: Date.now },
      },
    ],
    resolvedAt: Date,
    assignedAt: Date,
    estimatedResolution: Date,
    isOfflineSubmission: {
      type: Boolean,
      default: false,
    },
    qrScanned: {
      type: Boolean,
      default: false,
    },
    isCommonArea: {
      type: Boolean,
      default: false,
    },
    upvotedBy: [
      {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
      },
    ],
    upvoteCount: {
      type: Number,
      default: 0,
    },
  },
  {
    timestamps: true,
    toJSON: { virtuals: true },
    toObject: { virtuals: true },
  }
);

// Auto-generate complaint ID
complaintSchema.pre('save', async function (next) {
  if (!this.complaintId) {
    const count = await mongoose.model('Complaint').countDocuments();
    this.complaintId = `HC-${String(count + 1).padStart(5, '0')}`;
  }
  next();
});

// Virtual: resolution time in hours
complaintSchema.virtual('resolutionTime').get(function () {
  if (this.resolvedAt && this.createdAt) {
    return Math.round((this.resolvedAt - this.createdAt) / (1000 * 60 * 60));
  }
  return null;
});

// Indexes for performance
complaintSchema.index({ status: 1, category: 1 });
complaintSchema.index({ isCommonArea: 1 });
complaintSchema.index({ submittedBy: 1 });
complaintSchema.index({ assignedTo: 1 });
complaintSchema.index({ createdAt: -1 });

module.exports = mongoose.model('Complaint', complaintSchema);
