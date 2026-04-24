const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: [true, 'Name is required'],
      trim: true,
      maxlength: [50, 'Name cannot exceed 50 characters'],
    },
    email: {
      type: String,
      required: [true, 'Email is required'],
      unique: true,
      lowercase: true,
      trim: true,
      match: [/^\S+@\S+\.\S+$/, 'Please provide a valid email'],
    },
    password: {
      type: String,
      required: [true, 'Password is required'],
      minlength: [6, 'Password must be at least 6 characters'],
      select: false,
    },
    role: {
      type: String,
      enum: ['student', 'admin', 'staff'],
      default: 'student',
    },
    phone: {
      type: String,
      trim: true,
    },
    hostelBlock: {
      type: String,
      trim: true,
    },
    roomNumber: {
      type: String,
      trim: true,
    },
    avatar: {
      type: String,
      default: '',
    },
    fcmToken: {
      type: String,
      default: '',
    },
    specialization: {
      type: String,
      enum: ['electrical', 'plumbing', 'internet', 'cleaning', 'general'],
      default: 'general',
    },
    isActive: {
      type: Boolean,
      default: true,
    },
    lastLogin: {
      type: Date,
    },
    language: {
      type: String,
      enum: ['en', 'hi', 'ta', 'te', 'kn', 'ml'],
      default: 'en',
    },
  },
  {
    timestamps: true,
    toJSON: { virtuals: true },
    toObject: { virtuals: true },
  }
);

// Hash password before save
userSchema.pre('save', async function (next) {
  if (!this.isModified('password')) return next();
  const salt = await bcrypt.genSalt(12);
  this.password = await bcrypt.hash(this.password, salt);
  next();
});

// Compare password method
userSchema.methods.comparePassword = async function (candidatePassword) {
  return await bcrypt.compare(candidatePassword, this.password);
};

// Virtual: complaints count
userSchema.virtual('complaintsCount', {
  ref: 'Complaint',
  localField: '_id',
  foreignField: 'submittedBy',
  count: true,
});

module.exports = mongoose.model('User', userSchema);
