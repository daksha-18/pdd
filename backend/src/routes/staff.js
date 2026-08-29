const router = require('express').Router();
const Complaint = require('../models/Complaint');
const User = require('../models/User');
const Notification = require('../models/Notification');
const dbAdapter = require('../config/dbAdapter');
const { protect, authorize } = require('../middleware/auth');
const { analyzeSentiment } = require('../utils/sentiment');
const { upload } = require('../config/cloudinary');
const { sendPushNotification } = require('../config/firebase');

router.use(protect, authorize('staff'));

const getCategoriesForStaffSpec = (spec) => {
  const s = (spec || '').toLowerCase();
  if (s === 'electrical') return ['electrical'];
  if (s === 'plumbing') return ['water', 'plumbing'];
  if (s === 'internet') return ['internet', 'wifi'];
  if (s === 'cleaning') return ['cleaning', 'housekeeping'];
  return ['furniture', 'security', 'other'];
};

// GET /api/staff/assignments
router.get('/assignments', async (req, res, next) => {
  try {
    const { status, page = 1, limit = 20 } = req.query;
    const specCategories = getCategoriesForStaffSpec(req.user.specialization);

    const baseFilter = {
      $or: [
        { assignedTo: req.user.id },
        { category: { $in: specCategories } },
      ],
    };

    if (status === 'resolved') {
      baseFilter.status = { $in: ['resolved', 'closed'] };
    } else if (status) {
      baseFilter.status = status;
    }

    let complaints;
    let total;

    if (dbAdapter.useSupabase()) {
      complaints = await dbAdapter.findComplaints({ ...baseFilter, staffUser: req.user }, { page: parseInt(page), limit: parseInt(limit) });
      total = complaints.length;
    } else {
      const activeUsers = await User.find({ isActive: { $ne: false } }).select('_id');
      const activeUserIds = activeUsers.map((u) => u._id);
      const mongoFilter = { ...baseFilter, submittedBy: { $in: activeUserIds } };
      total = await Complaint.countDocuments(mongoFilter);
      complaints = await Complaint.find(mongoFilter)
        .populate('submittedBy', 'name email hostelBlock roomNumber')
        .populate('assignedTo', 'name email specialization')
        .sort('-createdAt')
        .skip((page - 1) * limit)
        .limit(parseInt(limit));
    }

    res.json({
      success: true,
      data: complaints,
      pagination: { total, page: parseInt(page), pages: Math.ceil(total / (parseInt(limit) || 20)) },
    });
  } catch (error) {
    next(error);
  }
});

// PUT /api/staff/assignments/:id/status
router.put('/assignments/:id/status', async (req, res, next) => {
  try {
    const { status, notes } = req.body;
    let complaint;

    if (dbAdapter.useSupabase()) {
      complaint = await dbAdapter.findComplaintById(req.params.id);
      if (!complaint) return res.status(404).json({ success: false, message: 'Assignment not found' });

      const history = complaint.statusHistory || [];
      history.push({ status, changedBy: req.user.id, notes: notes || `Status: ${status}`, timestamp: new Date() });

      const updatePayload = {
        status,
        assigned_to: req.user.id,
        status_history: history,
      };
      if (status === 'resolved') updatePayload.resolved_at = new Date();
      if (notes) updatePayload.resolution_notes = notes;

      await dbAdapter.supabase.from('complaints').update(updatePayload).eq('id', req.params.id);
      complaint = await dbAdapter.findComplaintById(req.params.id);
    } else {
      complaint = await Complaint.findById(req.params.id);
      if (!complaint) return res.status(404).json({ success: false, message: 'Assignment not found' });

      complaint.status = status;
      complaint.assignedTo = req.user.id;
      complaint.statusHistory.push({ status, changedBy: req.user.id, notes: notes || `Status: ${status}` });
      if (status === 'resolved') complaint.resolvedAt = new Date();
      if (notes) complaint.resolutionNotes = notes;
      await complaint.save();
      await complaint.populate('submittedBy', 'name email fcmToken');
      await complaint.populate('assignedTo', 'name email specialization');
    }

    try {
      const submitterId = complaint.submittedBy?._id || complaint.submittedBy?.id;
      if (submitterId) {
        await Notification.create({
          recipient: submitterId,
          title: 'Status Update',
          body: `"${complaint.title}" is now ${status.replace('_', ' ')}`,
          type: 'complaint_update',
          relatedComplaint: complaint._id || complaint.id,
        }).catch(() => {});
      }
    } catch (_) {}

    res.json({ success: true, data: complaint });
  } catch (error) {
    next(error);
  }
});

// POST /api/staff/assignments/:id/completion-images
router.post('/assignments/:id/completion-images', upload.array('images', 3), async (req, res, next) => {
  try {
    let complaint;
    if (dbAdapter.useSupabase()) {
      complaint = await dbAdapter.findComplaintById(req.params.id);
      if (!complaint) return res.status(404).json({ success: false, message: 'Not found' });
      const images = req.files.map((f) => ({ url: f.path, publicId: f.filename }));
      const existing = complaint.completionImages || [];
      const updated = [...existing, ...images];
      await dbAdapter.supabase.from('complaints').update({ completion_images: updated }).eq('id', req.params.id);
      complaint.completionImages = updated;
    } else {
      complaint = await Complaint.findById(req.params.id);
      if (!complaint) return res.status(404).json({ success: false, message: 'Not found' });

      const images = req.files.map((f) => ({ url: f.path, publicId: f.filename }));
      complaint.completionImages.push(...images);
      await complaint.save();
    }

    res.json({ success: true, data: complaint });
  } catch (error) {
    next(error);
  }
});

// GET /api/staff/stats
router.get('/stats', async (req, res, next) => {
  try {
    let assigned = 0;
    let inProgress = 0;
    let resolved = 0;
    let averageRating = 0;
    let averageSentimentScore = 0;
    let totalRatingsCount = 0;
    const specCategories = getCategoriesForStaffSpec(req.user.specialization);

    if (dbAdapter.useSupabase()) {
      const allAssigned = await dbAdapter.findComplaints({ staffUser: req.user });
      assigned = allAssigned.filter((c) => c.status === 'assigned').length;
      inProgress = allAssigned.filter((c) => c.status === 'in_progress').length;
      resolved = allAssigned.filter((c) => ['resolved', 'closed'].includes(c.status)).length;

      const { data: userDoc } = await dbAdapter.supabase.from('users').select('average_rating, average_sentiment_score, total_ratings_count').eq('id', req.user.id).single();
      if (userDoc) {
        averageRating = userDoc.average_rating || 0;
        averageSentimentScore = userDoc.average_sentiment_score || 0;
        totalRatingsCount = userDoc.total_ratings_count || 0;
      }
    } else {
      const activeUsers = await User.find({ isActive: { $ne: false } }).select('_id');
      const activeUserIds = activeUsers.map((u) => u._id);
      const baseFilter = {
        $or: [
          { assignedTo: req.user._id || req.user.id },
          { category: { $in: specCategories } },
        ],
        submittedBy: { $in: activeUserIds },
      };

      const userDoc = await User.findById(req.user._id || req.user.id).select('averageRating averageSentimentScore totalRatingsCount');

      const ratedComplaints = await Complaint.find({
        assignedTo: req.user._id || req.user.id,
        'feedback.rating': { $exists: true, $ne: null },
      });

      [assigned, inProgress, resolved] = await Promise.all([
        Complaint.countDocuments({ ...baseFilter, status: 'assigned' }),
        Complaint.countDocuments({ ...baseFilter, status: 'in_progress' }),
        Complaint.countDocuments({ ...baseFilter, status: { $in: ['resolved', 'closed'] } }),
      ]);

      if (ratedComplaints.length > 0) {
        totalRatingsCount = ratedComplaints.length;
        const totalRatingSum = ratedComplaints.reduce((acc, c) => acc + (c.feedback.rating || 0), 0);
        const totalSentSum = ratedComplaints.reduce((acc, c) => {
          const sentScore = c.feedback.sentimentScore !== undefined
            ? c.feedback.sentimentScore
            : analyzeSentiment(c.feedback.comment || '').score;
          return acc + sentScore;
        }, 0);
        averageRating = Math.round((totalRatingSum / totalRatingsCount) * 10) / 10;
        averageSentimentScore = Math.round((totalSentSum / totalRatingsCount) * 100) / 100;
      } else {
        averageRating = userDoc?.averageRating || 0;
        averageSentimentScore = userDoc?.averageSentimentScore || 0;
        totalRatingsCount = userDoc?.totalRatingsCount || 0;
      }
    }

    res.json({
      success: true,
      data: {
        assigned,
        inProgress,
        resolved,
        total: assigned + inProgress + resolved,
        averageRating,
        averageSentimentScore,
        avgSentiment: averageSentimentScore,
        totalRatingsCount,
      },
    });
  } catch (error) {
    next(error);
  }
});

module.exports = router;
