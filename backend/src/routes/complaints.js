const router = require('express').Router();
const Complaint = require('../models/Complaint');
const User = require('../models/User');
const Notification = require('../models/Notification');
const dbAdapter = require('../config/dbAdapter');
const { protect, authorize } = require('../middleware/auth');
const { complaintValidation } = require('../middleware/validate');
const { upload } = require('../config/cloudinary');
const mapCategoryToSpec = (cat) => {
  const c = (cat || '').toLowerCase();
  if (c === 'water' || c === 'plumbing') return 'plumbing';
  if (c === 'electrical') return 'electrical';
  if (c === 'internet' || c === 'wifi') return 'internet';
  if (c === 'cleaning' || c === 'housekeeping') return 'cleaning';
  return 'general';
};

const autoAssignDepartmentStaff = async (complaint, userId, io) => {
  try {
    const targetSpec = mapCategoryToSpec(complaint.category);

    let candidateStaff = await User.find({
      role: 'staff',
      isActive: { $ne: false },
      specialization: targetSpec,
    });

    if (candidateStaff.length === 0) {
      candidateStaff = await User.find({
        role: 'staff',
        isActive: { $ne: false },
        specialization: 'general',
      });
    }

    if (candidateStaff.length === 0) {
      candidateStaff = await User.find({
        role: 'staff',
        isActive: { $ne: false },
      });
    }

    if (candidateStaff.length > 0) {
      const workloads = await Promise.all(
        candidateStaff.map(async (s) => {
          const count = await Complaint.countDocuments({
            assignedTo: s._id,
            status: { $in: ['assigned', 'in_progress'] },
          });
          return { staff: s, count };
        })
      );

      workloads.sort((a, b) => a.count - b.count);
      const chosenStaff = workloads[0].staff;

      complaint.assignedTo = chosenStaff._id;
      complaint.status = 'assigned';
      complaint.assignedAt = new Date();
      complaint.statusHistory.push({
        status: 'assigned',
        changedBy: userId,
        notes: `Auto-assigned to ${chosenStaff.name} (${chosenStaff.specialization || 'Department Staff'}) based on category (${complaint.category})`,
        timestamp: new Date(),
      });

      await complaint.save();
      await complaint.populate('assignedTo', 'name email specialization');

      try {
        const autoNotif = await Notification.create({
          recipient: chosenStaff._id,
          title: `⚡ Complaint Auto-Assigned: ${complaint.complaintId || complaint._id}`,
          message: `New ${complaint.category} complaint "${complaint.title}" auto-assigned to you.`,
          type: 'status_change',
          relatedComplaint: complaint._id,
        });

        if (io) {
          io.to(chosenStaff._id.toString()).emit('new_notification', autoNotif);
          io.to(chosenStaff._id.toString()).emit('complaint_assigned', complaint);
        }

        if (chosenStaff.fcmToken) {
          sendPushNotification(
            chosenStaff.fcmToken,
            `⚡ Auto-Assigned: ${complaint.title}`,
            `New ${complaint.category} issue.`
          ).catch(() => {});
        }
      } catch (_) {}
    }
  } catch (err) {
    console.error('autoAssignDepartmentStaff error:', err);
  }
  return complaint;
};

// @route   POST /api/complaints
// @desc    Submit a new complaint
// @access  Private (Student)
router.post('/', protect, upload.array('images', 3), async (req, res, next) => {
  try {
    const { title, description, category, location, priority, qrScanned, isOfflineSubmission, isCommonArea } = req.body;

    const parsedLocation = typeof location === 'string' ? JSON.parse(location) : (location || {});

    if (parsedLocation.roomNumber) {
      const match = parsedLocation.roomNumber.toString().match(/\d+/);
      if (match) {
        const numStr = match[0];
        const num = parseInt(numStr, 10);
        const floorNum = numStr.length >= 3 ? Math.floor(num / 100) : 0;
        const suffixes = ['Ground', '1st', '2nd', '3rd'];
        const derivedFloor = suffixes[floorNum] || `${floorNum}th`;
        if (!parsedLocation.floor || parsedLocation.floor === '') {
          parsedLocation.floor = derivedFloor;
        }
      }
    }

    const images = req.files
      ? req.files.map((file) => {
          const isCloudinary = file.path && (file.path.startsWith('http://') || file.path.startsWith('https://'));
          return {
            url: isCloudinary ? file.path : `${req.protocol}://${req.get('host')}/uploads/${file.filename}`,
            publicId: file.filename,
          };
        })
      : [];

    let complaint;

    if (dbAdapter.useSupabase()) {
      complaint = await dbAdapter.createComplaint({
        title,
        description,
        category,
        priority: priority || 'medium',
        submittedBy: req.user.id,
        location: parsedLocation,
        images,
        qrScanned: qrScanned === 'true' || qrScanned === true,
        isOfflineSubmission: isOfflineSubmission === 'true' || isOfflineSubmission === true,
        isCommonArea: isCommonArea === 'true' || isCommonArea === true,
      });
    } else {
      complaint = await Complaint.create({
        title,
        description,
        category,
        priority: priority || 'medium',
        submittedBy: req.user.id,
        location: parsedLocation,
        images,
        qrScanned: qrScanned === 'true' || qrScanned === true,
        isOfflineSubmission: isOfflineSubmission === 'true' || isOfflineSubmission === true,
        isCommonArea: isCommonArea === 'true' || isCommonArea === true,
        statusHistory: [
          {
            status: 'pending',
            changedBy: req.user.id,
            notes: 'Complaint submitted',
          },
        ],
      });

      await complaint.populate('submittedBy', 'name email');

      const io = req.app.get('io');
      await autoAssignDepartmentStaff(complaint, req.user.id, io);
    }

    // Emit real-time event
    const io = req.app.get('io');
    if (io) {
      io.emit('new_complaint', complaint);
    }

    res.status(201).json({
      success: true,
      message: complaint.status === 'assigned' ? 'Complaint submitted and auto-assigned to department staff' : 'Complaint submitted successfully',
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
    const { status, category, priority, isCommonArea, page = 1, limit = 10, sort = '-createdAt' } = req.query;

    const filter = {};

    // Students see their complaints, OR all common area complaints if isCommonArea=true
    if (req.user.role === 'student') {
      if (isCommonArea === 'true') {
        filter.isCommonArea = true;
      } else {
        filter.submittedBy = req.user.id;
      }
    } else if (isCommonArea === 'true') {
      filter.isCommonArea = true;
    }

    // Staff see assigned complaints (or common area if requested)
    if (req.user.role === 'staff' && isCommonArea !== 'true') {
      filter.assignedTo = req.user.id;
    }

    // Admin sees complaints from active users only
    if (req.user.role === 'admin' && isCommonArea !== 'true') {
      const activeUsers = await User.find({ isActive: { $ne: false } }).select('_id');
      filter.submittedBy = { $in: activeUsers.map((u) => u._id) };
    }

    if (status === 'resolved') {
      filter.status = { $in: ['resolved', 'closed'] };
    } else if (status) {
      filter.status = status;
    }
    if (category) filter.category = category;
    if (priority) filter.priority = priority;

    let total;
    let complaints;
    if (dbAdapter.useSupabase()) {
      complaints = await dbAdapter.findComplaints(filter, { page: parseInt(page), limit: parseInt(limit), sort });
      total = complaints.length;
    } else {
      total = await Complaint.countDocuments(filter);
      complaints = await Complaint.find(filter)
        .populate('submittedBy', 'name email hostelBlock roomNumber')
        .populate('assignedTo', 'name email specialization')
        .sort(sort)
        .skip((page - 1) * limit)
        .limit(parseInt(limit));
    }

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
    let complaint;
    if (dbAdapter.useSupabase()) {
      complaint = await dbAdapter.findComplaintById(req.params.id);
    } else {
      complaint = await Complaint.findById(req.params.id)
        .populate('submittedBy', 'name email hostelBlock roomNumber avatar')
        .populate('assignedTo', 'name email specialization avatar')
        .populate('statusHistory.changedBy', 'name role')
        .populate('upvotedBy', 'name email');
    }

    if (!complaint) {
      return res.status(404).json({ success: false, message: 'Complaint not found' });
    }

    // Check authorization for students: must be submitter, upvoter, or a common area complaint
    if (
      req.user.role === 'student' &&
      !complaint.isCommonArea &&
      complaint.submittedBy._id.toString() !== req.user.id &&
      !complaint.upvotedBy.some((u) => u._id.toString() === req.user.id)
    ) {
      return res.status(403).json({ success: false, message: 'Not authorized' });
    }

    res.json({ success: true, data: complaint });
  } catch (error) {
    next(error);
  }
});

// @route   PUT /api/complaints/:id/upvote
// @desc    Upvote / Me-Too a common area complaint
// @access  Private (Student)
router.put('/:id/upvote', protect, authorize('student'), async (req, res, next) => {
  try {
    const complaint = await Complaint.findById(req.params.id);
    if (!complaint) {
      return res.status(404).json({ success: false, message: 'Complaint not found' });
    }

    if (['closed', 'rejected'].includes(complaint.status)) {
      return res.status(400).json({ success: false, message: 'Cannot upvote closed or rejected complaints' });
    }

    const userIdStr = req.user.id.toString();
    const existingIndex = complaint.upvotedBy.findIndex((id) => id.toString() === userIdStr);

    if (existingIndex > -1) {
      // Remove upvote
      complaint.upvotedBy.splice(existingIndex, 1);
    } else {
      // Add upvote
      complaint.upvotedBy.push(req.user.id);
    }

    complaint.upvoteCount = complaint.upvotedBy.length;
    await complaint.save();

    await complaint.populate('submittedBy', 'name email hostelBlock roomNumber');
    await complaint.populate('assignedTo', 'name email specialization');

    const io = req.app.get('io');
    if (io) {
      io.emit('complaint_upvoted', { complaintId: complaint._id, upvoteCount: complaint.upvoteCount, upvotedBy: complaint.upvotedBy });
    }

    res.json({
      success: true,
      message: existingIndex > -1 ? 'Upvote removed' : 'Complaint upvoted successfully',
      data: complaint,
    });
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
    await complaint.populate('upvotedBy', 'name email fcmToken');

    // Notification recipients: submitter + all upvoters
    const recipients = [complaint.submittedBy._id, ...complaint.upvotedBy.map((u) => u._id)];
    const uniqueRecipients = [...new Set(recipients.map((id) => id.toString()))];

    for (const recipientId of uniqueRecipients) {
      await Notification.create({
        recipient: recipientId,
        title: 'Complaint Status Updated',
        body: `Complaint "${complaint.title}" is now ${status.replace('_', ' ')}`,
        type: 'complaint_update',
        relatedComplaint: complaint._id,
      });

      const userDoc = recipientId === complaint.submittedBy._id.toString()
        ? complaint.submittedBy
        : complaint.upvotedBy.find((u) => u._id.toString() === recipientId);

      if (userDoc && userDoc.fcmToken) {
        await sendPushNotification(
          userDoc.fcmToken,
          'Complaint Update',
          `Complaint "${complaint.title}" is now ${status.replace('_', ' ')}`,
          { complaintId: complaint._id.toString(), status }
        );
      }

      const io = req.app.get('io');
      if (io) {
        io.to(recipientId).emit('complaint_update', complaint);
      }
    }

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

    // Recalculate assigned staff rating if staff was assigned
    if (complaint.assignedTo) {
      const ratedComplaints = await Complaint.find({
        assignedTo: complaint.assignedTo,
        'feedback.rating': { $exists: true, $ne: null },
      });

      if (ratedComplaints.length > 0) {
        const totalRatingSum = ratedComplaints.reduce((acc, curr) => acc + (curr.feedback.rating || 0), 0);
        const avg = Math.round((totalRatingSum / ratedComplaints.length) * 10) / 10;
        await User.findByIdAndUpdate(complaint.assignedTo, {
          averageRating: avg,
          totalRatingsCount: ratedComplaints.length,
        });
      }
    }

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
    const io = req.app.get('io');

    for (const c of complaints) {
      const complaint = await Complaint.create({
        ...c,
        submittedBy: req.user.id,
        isOfflineSubmission: true,
        statusHistory: [
          { status: 'pending', changedBy: req.user.id, notes: 'Synced from offline' },
        ],
      });
      await autoAssignDepartmentStaff(complaint, req.user.id, io);
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

// @route   PUT /api/complaints/:id/withdraw
// @desc    Withdraw/cancel complaint by student
// @access  Private (Student)
router.put('/:id/withdraw', protect, authorize('student'), async (req, res, next) => {
  try {
    const complaint = await Complaint.findById(req.params.id);
    if (!complaint) {
      return res.status(404).json({ success: false, message: 'Complaint not found' });
    }

    if (complaint.submittedBy.toString() !== req.user.id) {
      return res.status(403).json({ success: false, message: 'Not authorized' });
    }

    if (['resolved', 'closed', 'rejected', 'withdrawn'].includes(complaint.status)) {
      return res.status(400).json({
        success: false,
        message: `Cannot withdraw complaint that is already ${complaint.status}`,
      });
    }

    complaint.status = 'withdrawn';
    complaint.statusHistory.push({
      status: 'withdrawn',
      changedBy: req.user.id,
      notes: 'Complaint withdrawn by student',
    });

    await complaint.save();

    const io = req.app.get('io');
    if (io) {
      io.emit('complaint_update', complaint);
    }

    res.json({
      success: true,
      message: 'Complaint withdrawn successfully',
      data: complaint,
    });
  } catch (error) {
    next(error);
  }
});

module.exports = router;
