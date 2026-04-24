const router = require('express').Router();
const jwt = require('jsonwebtoken');
const User = require('../models/User');
const { registerValidation, loginValidation } = require('../middleware/validate');
const { protect } = require('../middleware/auth');

// Generate JWT Token
const generateToken = (id) => {
  return jwt.sign({ id }, process.env.JWT_SECRET || 'hostelcare_secret_key', {
    expiresIn: process.env.JWT_EXPIRE || '7d',
  });
};

// @route   POST /api/auth/register
// @desc    Register a new user
// @access  Public
router.post('/register', registerValidation, async (req, res, next) => {
  try {
    const { name, email, password, phone, hostelBlock, roomNumber, role } = req.body;

    // Check if user exists
    const existingUser = await User.findOne({ email });
    if (existingUser) {
      return res.status(400).json({ success: false, message: 'Email already registered' });
    }

    // Only allow student registration publicly; admin/staff require admin creation
    const userRole = role === 'admin' || role === 'staff' ? 'student' : role || 'student';

    const user = await User.create({
      name,
      email,
      password,
      phone,
      hostelBlock,
      roomNumber,
      role: userRole,
    });

    const token = generateToken(user._id);

    res.status(201).json({
      success: true,
      message: 'Registration successful',
      data: {
        token,
        user: {
          id: user._id,
          name: user.name,
          email: user.email,
          role: user.role,
          hostelBlock: user.hostelBlock,
          roomNumber: user.roomNumber,
        },
      },
    });
  } catch (error) {
    next(error);
  }
});

// @route   POST /api/auth/login
// @desc    Login user
// @access  Public
router.post('/login', loginValidation, async (req, res, next) => {
  try {
    const { email, password } = req.body;

    const user = await User.findOne({ email }).select('+password');
    if (!user) {
      return res.status(401).json({ success: false, message: 'Invalid email or password' });
    }

    if (!user.isActive) {
      return res.status(401).json({ success: false, message: 'Account has been deactivated' });
    }

    const isMatch = await user.comparePassword(password);
    if (!isMatch) {
      return res.status(401).json({ success: false, message: 'Invalid email or password' });
    }

    // Update last login
    user.lastLogin = new Date();
    await user.save({ validateBeforeSave: false });

    const token = generateToken(user._id);

    res.json({
      success: true,
      message: 'Login successful',
      data: {
        token,
        user: {
          id: user._id,
          name: user.name,
          email: user.email,
          role: user.role,
          hostelBlock: user.hostelBlock,
          roomNumber: user.roomNumber,
          avatar: user.avatar,
        },
      },
    });
  } catch (error) {
    next(error);
  }
});

// @route   GET /api/auth/me
// @desc    Get current user
// @access  Private
router.get('/me', protect, async (req, res) => {
  const user = await User.findById(req.user.id);
  res.json({
    success: true,
    data: user,
  });
});

// @route   PUT /api/auth/update-profile
// @desc    Update user profile
// @access  Private
router.put('/update-profile', protect, async (req, res, next) => {
  try {
    const { name, phone, hostelBlock, roomNumber, language } = req.body;

    const user = await User.findByIdAndUpdate(
      req.user.id,
      { name, phone, hostelBlock, roomNumber, language },
      { new: true, runValidators: true }
    );

    res.json({
      success: true,
      message: 'Profile updated',
      data: user,
    });
  } catch (error) {
    next(error);
  }
});

// @route   PUT /api/auth/change-password
// @desc    Change password
// @access  Private
router.put('/change-password', protect, async (req, res, next) => {
  try {
    const { currentPassword, newPassword } = req.body;

    const user = await User.findById(req.user.id).select('+password');

    const isMatch = await user.comparePassword(currentPassword);
    if (!isMatch) {
      return res.status(400).json({ success: false, message: 'Current password is incorrect' });
    }

    user.password = newPassword;
    await user.save();

    const token = generateToken(user._id);

    res.json({
      success: true,
      message: 'Password changed successfully',
      data: { token },
    });
  } catch (error) {
    next(error);
  }
});

// @route   PUT /api/auth/fcm-token
// @desc    Update FCM token
// @access  Private
router.put('/fcm-token', protect, async (req, res, next) => {
  try {
    await User.findByIdAndUpdate(req.user.id, { fcmToken: req.body.fcmToken });
    res.json({ success: true, message: 'FCM token updated' });
  } catch (error) {
    next(error);
  }
});

module.exports = router;
