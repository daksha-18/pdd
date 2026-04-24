const router = require('express').Router();
const Complaint = require('../models/Complaint');
const Notification = require('../models/Notification');
const { protect, authorize } = require('../middleware/auth');
const { complaintValidation } = require('../middleware/validate');
const { upload } = require('../config/cloudinary');
const { sendPushNotification } = require('../config/firebase');

// @route   POST /api/complaints
// @desc    Submit a new complaint
// @access  Private (Student)
router.post('/', protect, upload.array('images', 3), async (req, res, next) => {
  try {
    const { title, description, category, location, priority, qrScanned, isOfflineSubmission } = req.body;

    const parsedLocation = typeof location === 'string' ? JSON.parse(location) : location;

    const images = req.files
      ? req.files.map((file) => ({
          url: file.path,
          publicId: file.filename,
        }))
      : [];

    const complaint = await Complaint.create({
      title,
      description,
      category,
      priority: priority || 'medium',
      submittedBy: req.user.id,
      location: parsedLocation,
      images,
      qrScanned: qrScanned === 'true' || qrScanned === true,
      isOfflineSubmission: isOfflineSubmission === 'true' || isOfflineSubmission === true,
      statusHistory: [
        {
          status: 'pending',
          changedBy: req.user.id,
          notes: 'Complaint submitted',
        },
      ],
    });

    await complaint.populate('submittedBy', 'name email');

    // Emit real-time event
    const io = req.app.get('io');
    io.emit('new_complaint', complaint);

    res.status(201).json({
      success: true,
      message: 'Complaint submitted successfully',
      data: complaint,
    });
  } catch (error) {
    next(error);
  }
});

// @route   GET /api/complaints
// @desc    Get complaints (filtered by role)
// @access  Private
router.get('/', protect, async (req, res, next) => {
  try {
    const { status, category, priority, page = 1, limit = 10, sort = '-createdAt' } = req.query;

    const filter = {};

    // Students see only their complaints
    if (req.user.role === 'student') {
      filter.submittedBy = req.user.id;
    }

    // Staff see only assigned complaints
    if (req.user.role === 'staff') {
      filter.assignedTo = req.user.id;
    }

    if (status) filter.status = status;
    if (category) filter.category = category;
    if (priority) filter.priority = priority;

    const total = await Complaint.countDocuments(filter);
    const complaints = await Complaint.find(filter)
      .populate('submittedBy', 'name email hostelBlock roomNumber')
      .populate('assignedTo', 'name email specialization')
      .sort(sort)
      .skip((page - 1) * limit)
      .limit(parseInt(limit));

    res.json({
      success: true,
      data: complaints,
      pagination: {
        total,
        page: parseInt(page),
        pages: Math.ceil(total / limit),
        limit: parseInt(limit),
      },
    });
  } catch (error) {
    next(error);
  }
});

// @route   GET /api/complaints/:id
// @desc    Get single complaint
// @access  Private
router.get('/:id', protect, async (req, res, next) => {
  try {
    const complaint = await Complaint.findById(req.params.id)
      .populate('submittedBy', 'name email hostelBlock roomNumber avatar')
      .populate('assignedTo', 'name email specialization avatar')
      .populate('statusHistory.changedBy', 'name role');

    if (!complaint) {
      return res.status(404).json({ success: false, message: 'Complaint not found' });
    }

    // Check ownership for students
    if (
      req.user.role === 'student' &&
      complaint.submittedBy._id.toString() !== req.user.id
    ) {
      return res.status(403).json({ success: false, message: 'Not authorized' });
    }

    res.json({ success: true, data: complaint });
  } catch (error) {
    next(error);
  }
});

// @route   PUT /api/complaints/:id/status
// @desc    Update complaint status
// @access  Private (Admin/Staff)
router.put('/:id/status', protect, authorize('admin', 'staff'), async (req, res, next) => {
  try {
    const { status, notes } = req.body;

    const complaint = await Complaint.findById(req.params.id);
    if (!complaint) {
      return res.status(404).json({ success: false, message: 'Complaint not found' });
    }

    complaint.status = status;
    complaint.statusHistory.push({
      status,
      changedBy: req.user.id,
      notes: notes || `Status changed to ${status}`,
    });

    if (status === 'resolved') {
      complaint.resolvedAt = new Date();
    }

    await complaint.save();
    await complaint.populate('submittedBy', 'name email fcmToken');
    await complaint.populate('assignedTo', 'name email');

    // Create notification
    await Notification.create({
      recipient: complaint.submittedBy._id,
      title: 'Complaint Status Updated',
      body: `Your complaint "${complaint.title}" is now ${status.replace('_', ' ')}`,
      type: 'complaint_update',
      relatedComplaint: complaint._id,
    });

    // Send push notification
    if (complaint.submittedBy.fcmToken) {
      await sendPushNotification(
        complaint.submittedBy.fcmToken,
        'Complaint Update',
        `Your complaint "${complaint.title}" is now ${status.replace('_', ' ')}`,
        { complaintId: complaint._id.toString(), status }
      );
    }

    // Emit real-time event
    const io = req.app.get('io');
    io.to(complaint.submittedBy._id.toString()).emit('complaint_update', complaint);

    res.json({ success: true, message: 'Status updated', data: complaint });
  } catch (error) {
    next(error);
  }
});

// @route   PUT /api/complaints/:id/feedback
// @desc    Submit feedback for resolved complaint
// @access  Private (Student)
router.put('/:id/feedback', protect, authorize('student'), async (req, res, next) => {
  try {
    const { rating, comment } = req.body;

    const complaint = await Complaint.findById(req.params.id);
    if (!complaint) {
      return res.status(404).json({ success: false, message: 'Complaint not found' });
    }

    if (complaint.submittedBy.toString() !== req.user.id) {
      return res.status(403).json({ success: false, message: 'Not authorized' });
    }

    if (complaint.status !== 'resolved') {
      return res.status(400).json({ success: false, message: 'Can only provide feedback for resolved complaints' });
    }

    complaint.feedback = { rating, comment, submittedAt: new Date() };
    complaint.status = 'closed';
    complaint.statusHistory.push({
      status: 'closed',
      changedBy: req.user.id,
      notes: `Feedback: ${rating}/5 - ${comment || 'No comment'}`,
    });

    await complaint.save();

    res.json({ success: true, message: 'Feedback submitted', data: complaint });
  } catch (error) {
    next(error);
  }
});

// @route   POST /api/complaints/sync
// @desc    Sync offline complaints
// @access  Private (Student)
router.post('/sync', protect, async (req, res, next) => {
  try {
    const { complaints } = req.body;
    const synced = [];

    for (const c of complaints) {
      const complaint = await Complaint.create({
        ...c,
        submittedBy: req.user.id,
        isOfflineSubmission: true,
        statusHistory: [
          { status: 'pending', changedBy: req.user.id, notes: 'Synced from offline' },
        ],
      });
      synced.push(complaint);
    }

    res.status(201).json({
      success: true,
      message: `${synced.length} complaints synced`,
      data: synced,
    });
  } catch (error) {
    next(error);
  }
});

module.exports = router;
