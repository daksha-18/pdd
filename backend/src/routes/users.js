const router = require('express').Router();
const User = require('../models/User');
const Notification = require('../models/Notification');
const { protect } = require('../middleware/auth');

// @route   GET /api/users/notifications
// @desc    Get user notifications
// @access  Private
router.get('/notifications', protect, async (req, res, next) => {
  try {
    const { page = 1, limit = 20 } = req.query;

    const notifications = await Notification.find({ recipient: req.user.id })
      .populate('relatedComplaint', 'complaintId title status')
      .sort('-createdAt')
      .skip((page - 1) * limit)
      .limit(parseInt(limit));

    const unreadCount = await Notification.countDocuments({
      recipient: req.user.id,
      isRead: false,
    });

    res.json({
      success: true,
      data: notifications,
      unreadCount,
    });
  } catch (error) {
    next(error);
  }
});

// @route   PUT /api/users/notifications/read-all
// @desc    Mark all notifications as read
// @access  Private
router.put('/notifications/read-all', protect, async (req, res, next) => {
  try {
    await Notification.updateMany(
      { recipient: req.user.id, isRead: false },
      { isRead: true }
    );
    res.json({ success: true, message: 'All notifications marked as read' });
  } catch (error) {
    next(error);
  }
});

// @route   PUT /api/users/notifications/:id/read
// @desc    Mark single notification as read
// @access  Private
router.put('/notifications/:id/read', protect, async (req, res, next) => {
  try {
    await Notification.findByIdAndUpdate(req.params.id, { isRead: true });
    res.json({ success: true, message: 'Notification marked as read' });
  } catch (error) {
    next(error);
  }
});

module.exports = router;
