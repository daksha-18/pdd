const router = require('express').Router();
const Complaint = require('../models/Complaint');
const User = require('../models/User');
const Notification = require('../models/Notification');
const { protect, authorize } = require('../middleware/auth');
const { upload } = require('../config/cloudinary');
const { sendPushNotification } = require('../config/firebase');

router.use(protect, authorize('staff'));

// GET /api/staff/assignments
router.get('/assignments', async (req, res, next) => {
  try {
    const { status, page = 1, limit = 20 } = req.query;
    
    // Exclude complaints submitted by deactivated users
    const activeUsers = await User.find({ isActive: { $ne: false } }).select('_id');
    const activeUserIds = activeUsers.map((u) => u._id);
    const filter = { assignedTo: req.user.id, submittedBy: { $in: activeUserIds } };
    if (status === 'resolved') {
      filter.status = { $in: ['resolved', 'closed'] };
    } else if (status) {
      filter.status = status;
    }

    const total = await Complaint.countDocuments(filter);
    const complaints = await Complaint.find(filter)
      .populate('submittedBy', 'name email hostelBlock roomNumber')
      .sort('-createdAt')
      .skip((page - 1) * limit)
      .limit(parseInt(limit));

    res.json({ success: true, data: complaints, pagination: { total, page: parseInt(page), pages: Math.ceil(total / limit) } });
  } catch (error) { next(error); }
});

// PUT /api/staff/assignments/:id/status
router.put('/assignments/:id/status', async (req, res, next) => {
  try {
    const { status, notes } = req.body;
    const complaint = await Complaint.findOne({ _id: req.params.id, assignedTo: req.user.id });
    if (!complaint) return res.status(404).json({ success: false, message: 'Assignment not found' });

    complaint.status = status;
    complaint.statusHistory.push({ status, changedBy: req.user.id, notes: notes || `Status: ${status}` });
    if (status === 'resolved') complaint.resolvedAt = new Date();
    if (notes) complaint.resolutionNotes = notes;
    await complaint.save();
    await complaint.populate('submittedBy', 'name email fcmToken');

    await Notification.create({
      recipient: complaint.submittedBy._id,
      title: 'Status Update',
      body: `"${complaint.title}" is now ${status.replace('_', ' ')}`,
      type: 'complaint_update',
      relatedComplaint: complaint._id,
    });

    if (complaint.submittedBy.fcmToken) {
      await sendPushNotification(complaint.submittedBy.fcmToken, 'Update', `Complaint is now ${status.replace('_', ' ')}`);
    }

    const io = req.app.get('io');
    if (io) {
      io.to(complaint.submittedBy._id.toString()).emit('complaint_update', complaint);
    }

    res.json({ success: true, data: complaint });
  } catch (error) { next(error); }
});

// POST /api/staff/assignments/:id/completion-images
router.post('/assignments/:id/completion-images', upload.array('images', 3), async (req, res, next) => {
  try {
    const complaint = await Complaint.findOne({ _id: req.params.id, assignedTo: req.user.id });
    if (!complaint) return res.status(404).json({ success: false, message: 'Not found' });

    const images = req.files.map((f) => ({ url: f.path, publicId: f.filename }));
    complaint.completionImages.push(...images);
    await complaint.save();

    res.json({ success: true, data: complaint });
  } catch (error) { next(error); }
});

// GET /api/staff/stats
router.get('/stats', async (req, res, next) => {
  try {
    const activeUsers = await User.find({ isActive: { $ne: false } }).select('_id');
    const activeUserIds = activeUsers.map((u) => u._id);
    const baseFilter = { assignedTo: req.user.id, submittedBy: { $in: activeUserIds } };

    const userDoc = await User.findById(req.user.id).select('averageRating totalRatingsCount');

    const [assigned, inProgress, resolved] = await Promise.all([
      Complaint.countDocuments({ ...baseFilter, status: 'assigned' }),
      Complaint.countDocuments({ ...baseFilter, status: 'in_progress' }),
      Complaint.countDocuments({ ...baseFilter, status: { $in: ['resolved', 'closed'] } }),
    ]);
    res.json({
      success: true,
      data: {
        assigned,
        inProgress,
        resolved,
        total: assigned + inProgress + resolved,
        averageRating: userDoc?.averageRating || 0,
        totalRatingsCount: userDoc?.totalRatingsCount || 0,
      },
    });
  } catch (error) { next(error); }
});

module.exports = router;
