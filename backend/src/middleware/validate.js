const { body, validationResult } = require('express-validator');

// Handle validation errors
const handleValidation = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({
      success: false,
      message: 'Validation failed',
      errors: errors.array().map((e) => ({ field: e.path, message: e.msg })),
    });
  }
  next();
};

// Register validation
const registerValidation = [
  body('name').trim().notEmpty().withMessage('Name is required'),
  body('email').isEmail().withMessage('Please provide a valid email'),
  body('password').isLength({ min: 6 }).withMessage('Password must be at least 6 characters'),
  handleValidation,
];

// Login validation
const loginValidation = [
  body('email').isEmail().withMessage('Please provide a valid email'),
  body('password').notEmpty().withMessage('Password is required'),
  handleValidation,
];

// Complaint validation
const complaintValidation = [
  body('title').trim().notEmpty().withMessage('Title is required').isLength({ max: 100 }),
  body('description').trim().notEmpty().withMessage('Description is required').isLength({ max: 1000 }),
  body('category')
    .isIn(['electrical', 'water', 'internet', 'cleaning', 'furniture', 'security', 'other'])
    .withMessage('Invalid category'),
  body('location.hostelBlock').trim().notEmpty().withMessage('Hostel block is required'),
  body('location.roomNumber').trim().notEmpty().withMessage('Room number is required'),
  handleValidation,
];

module.exports = {
  handleValidation,
  registerValidation,
  loginValidation,
  complaintValidation,
};
