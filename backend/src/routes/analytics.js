const router = require('express').Router();
const Complaint = require('../models/Complaint');
const User = require('../models/User');
const { protect, authorize } = require('../middleware/auth');

router.use(protect, authorize('admin'));

// GET /api/analytics/dashboard
router.get('/dashboard', async (req, res, next) => {
  try {
    const activeUsers = await User.find({ isActive: { $ne: false } }).select('_id');
    const activeUserIds = activeUsers.map((u) => u._id);
    const activeFilter = { submittedBy: { $in: activeUserIds } };

    const [totalComplaints, pending, assigned, inProgress, resolved, closed, totalStudents, totalStaff] = await Promise.all([
      Complaint.countDocuments(activeFilter),
      Complaint.countDocuments({ ...activeFilter, status: 'pending' }),
      Complaint.countDocuments({ ...activeFilter, status: 'assigned' }),
      Complaint.countDocuments({ ...activeFilter, status: 'in_progress' }),
      Complaint.countDocuments({ ...activeFilter, status: 'resolved' }),
      Complaint.countDocuments({ ...activeFilter, status: 'closed' }),
      User.countDocuments({ role: 'student', isActive: { $ne: false } }),
      User.countDocuments({ role: 'staff', isActive: { $ne: false } }),
    ]);

    const categoryDist = await Complaint.aggregate([
      { $group: { _id: '$category', count: { $sum: 1 } } },
      { $sort: { count: -1 } },
    ]);

    const priorityDist = await Complaint.aggregate([
      { $group: { _id: '$priority', count: { $sum: 1 } } },
    ]);

    // Average resolution time (hours)
    const avgResolution = await Complaint.aggregate([
      { $match: { resolvedAt: { $exists: true } } },
      { $project: { resTime: { $subtract: ['$resolvedAt', '$createdAt'] } } },
      { $group: { _id: null, avg: { $avg: '$resTime' } } },
    ]);
    const avgResolutionHours = avgResolution.length > 0 ? Math.round(avgResolution[0].avg / 3600000) : 0;

    // Monthly trend (last 6 months)
    const sixMonthsAgo = new Date();
    sixMonthsAgo.setMonth(sixMonthsAgo.getMonth() - 6);
    const monthlyTrend = await Complaint.aggregate([
      { $match: { createdAt: { $gte: sixMonthsAgo } } },
      { $group: { _id: { year: { $year: '$createdAt' }, month: { $month: '$createdAt' } }, count: { $sum: 1 } } },
      { $sort: { '_id.year': 1, '_id.month': 1 } },
    ]);

    res.json({
      success: true,
      data: {
        overview: { totalComplaints, pending, assigned, inProgress, resolved, closed, totalStudents, totalStaff },
        categoryDistribution: categoryDist,
        priorityDistribution: priorityDist,
        avgResolutionHours,
        monthlyTrend,
      },
    });
  } catch (error) { next(error); }
});

// GET /api/analytics/staff-performance
router.get('/staff-performance', async (req, res, next) => {
  try {
    const staff = await User.find({ role: 'staff', isActive: true });
    const performance = await Promise.all(staff.map(async (s) => {
      const [total, resolved, avgRes] = await Promise.all([
        Complaint.countDocuments({ assignedTo: s._id }),
        Complaint.countDocuments({ assignedTo: s._id, status: { $in: ['resolved', 'closed'] } }),
        Complaint.aggregate([
          { $match: { assignedTo: s._id, resolvedAt: { $exists: true } } },
          { $project: { t: { $subtract: ['$resolvedAt', '$assignedAt'] } } },
          { $group: { _id: null, avg: { $avg: '$t' } } },
        ]),
      ]);
      const avgFeedback = await Complaint.aggregate([
        { $match: { assignedTo: s._id, 'feedback.rating': { $exists: true } } },
        { $group: { _id: null, avg: { $avg: '$feedback.rating' } } },
      ]);
      return {
        staff: { id: s._id, name: s.name, specialization: s.specialization },
        totalAssigned: total,
        totalResolved: resolved,
        avgResolutionHours: avgRes.length ? Math.round(avgRes[0].avg / 3600000) : 0,
        avgRating: avgFeedback.length ? Math.round(avgFeedback[0].avg * 10) / 10 : 0,
      };
    }));
    res.json({ success: true, data: performance });
  } catch (error) { next(error); }
});

module.exports = router;
