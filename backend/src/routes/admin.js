const router = require('express').Router();
const User = require('../models/User');
const Complaint = require('../models/Complaint');
const Notification = require('../models/Notification');
const { protect, authorize } = require('../middleware/auth');
const { analyzeSentiment } = require('../utils/sentiment');
const { sendPushNotification } = require('../config/firebase');

router.use(protect, authorize('admin'));

// GET /api/admin/users
router.get('/users', async (req, res, next) => {
  try {
    const { role, search, page = 1, limit = 50 } = req.query;
    const dbAdapter = require('../config/dbAdapter');

    const filter = {};
    if (role) filter.role = role;

    let users = await dbAdapter.findUsers(filter);
    if (Array.isArray(users)) {
      users = users.filter((u) => u.isActive !== false);
    }

    if (search) {
      const s = search.toLowerCase();
      users = users.filter((u) => (u.name && u.name.toLowerCase().includes(s)) || (u.email && u.email.toLowerCase().includes(s)));
    }

    const total = users.length;
    const pagedUsers = users.slice((page - 1) * limit, page * limit);

    const usersWithRatings = await Promise.all(pagedUsers.map(async (u) => {
      const uObj = typeof u.toObject === 'function' ? u.toObject() : { ...u };
      if (u.role === 'staff') {
        try {
          const perfData = await dbAdapter.getStaffPerformance();
          const p = perfData.find((fp) => fp.staff && (fp.staff.id === u.id || fp.staff.id === u._id || String(fp.staff.id) === String(u._id)));
          if (p) {
            uObj.averageRating = p.avgRating || 0;
            uObj.averageSentimentScore = p.avgSentiment !== undefined ? p.avgSentiment : (p.averageSentimentScore || uObj.averageSentimentScore || 0);
            uObj.totalRatingsCount = p.totalResolved || 0;
          }
        } catch (e) {}
      }
      return uObj;
    }));

    res.json({ success: true, data: usersWithRatings, pagination: { total, page: parseInt(page), pages: Math.ceil(total / limit) } });
  } catch (error) { next(error); }
});

// POST /api/admin/users
router.post('/users', async (req, res, next) => {
  try {
    const { name, email, password, role, phone, specialization } = req.body;
    const user = await User.create({ name, email, password, role, phone, specialization: role === 'staff' ? specialization : 'general' });
    res.status(201).json({ success: true, data: user });
  } catch (error) { next(error); }
});

// PUT /api/admin/users/:id/approve
router.put('/users/:id/approve', async (req, res, next) => {
  try {
    const user = await User.findByIdAndUpdate(req.params.id, { isApproved: true }, { new: true });
    if (!user) return res.status(404).json({ success: false, message: 'User not found' });
    res.json({ success: true, message: 'User approved successfully', data: user });
  } catch (error) { next(error); }
});

// PUT /api/admin/users/:id
router.put('/users/:id', async (req, res, next) => {
  try {
    const user = await User.findByIdAndUpdate(req.params.id, req.body, { new: true, runValidators: true });
    if (!user) return res.status(404).json({ success: false, message: 'User not found' });
    res.json({ success: true, data: user });
  } catch (error) { next(error); }
});

// DELETE /api/admin/users/:id (soft delete)
router.delete('/users/:id', async (req, res, next) => {
  try {
    await User.findByIdAndUpdate(req.params.id, { isActive: false });
    res.json({ success: true, message: 'User deactivated' });
  } catch (error) { next(error); }
});

// DELETE /api/admin/users/:id/reject (hard delete for pending users)
router.delete('/users/:id/reject', async (req, res, next) => {
  try {
    const user = await User.findById(req.params.id);
    if (!user) return res.status(404).json({ success: false, message: 'User not found' });
    await User.findByIdAndDelete(req.params.id);
    res.json({ success: true, message: 'User application rejected' });
  } catch (error) { next(error); }
});

// GET /api/admin/complaints
router.get('/complaints', async (req, res, next) => {
  try {
    const { status, category, priority, search, page = 1, limit = 20, sort = '-createdAt' } = req.query;
    const filter = {};
    if (status === 'resolved') {
      filter.status = { $in: ['resolved', 'closed'] };
    } else if (status) {
      filter.status = status;
    }
    if (category) filter.category = category;
    if (priority) filter.priority = priority;
    if (search) {
      filter.$or = [
        { title: { $regex: search, $options: 'i' } },
        { complaintId: { $regex: search, $options: 'i' } },
      ];
    }

    // Exclude complaints submitted by deactivated users
    const activeUsers = await User.find({ isActive: { $ne: false } }).select('_id');
    const activeUserIds = activeUsers.map((u) => u._id);
    filter.submittedBy = { $in: activeUserIds };

    const total = await Complaint.countDocuments(filter);
    const complaints = await Complaint.find(filter)
      .populate('submittedBy', 'name email hostelBlock roomNumber')
      .populate('assignedTo', 'name email specialization averageRating totalRatingsCount')
      .sort(sort).skip((page - 1) * limit).limit(parseInt(limit));
    res.json({ success: true, data: complaints, pagination: { total, page: parseInt(page), pages: Math.ceil(total / limit) } });
  } catch (error) { next(error); }
});

// PUT /api/admin/complaints/:id/assign
router.put('/complaints/:id/assign', async (req, res, next) => {
  try {
    const { staffId, priority } = req.body;
    const staff = await User.findById(staffId);
    if (!staff || staff.role !== 'staff') return res.status(400).json({ success: false, message: 'Invalid staff' });
    const complaint = await Complaint.findById(req.params.id);
    if (!complaint) return res.status(404).json({ success: false, message: 'Not found' });

    complaint.assignedTo = staffId;
    complaint.status = 'assigned';
    complaint.assignedAt = new Date();
    if (priority) complaint.priority = priority;
    complaint.statusHistory.push({ status: 'assigned', changedBy: req.user.id, notes: `Assigned to ${staff.name}` });
    await complaint.save();
    await complaint.populate('submittedBy', 'name email fcmToken');
    await complaint.populate('assignedTo', 'name email');

    await Notification.create({ recipient: complaint.submittedBy._id, title: 'Complaint Assigned', body: `"${complaint.title}" assigned to ${staff.name}`, type: 'assignment', relatedComplaint: complaint._id });
    await Notification.create({ recipient: staffId, title: 'New Assignment', body: `Assigned: "${complaint.title}"`, type: 'assignment', relatedComplaint: complaint._id });

    if (complaint.submittedBy.fcmToken) await sendPushNotification(complaint.submittedBy.fcmToken, 'Assigned', `Complaint assigned to ${staff.name}`);
    if (staff.fcmToken) await sendPushNotification(staff.fcmToken, 'New Assignment', `"${complaint.title}"`);

    const io = req.app.get('io');
    if (io) {
      io.to(complaint.submittedBy._id.toString()).emit('complaint_update', complaint);
      io.to(staffId).emit('new_assignment', complaint);
    }

    res.json({ success: true, data: complaint });
  } catch (error) { next(error); }
});

// PUT /api/admin/complaints/:id/priority
router.put('/complaints/:id/priority', async (req, res, next) => {
  try {
    const complaint = await Complaint.findByIdAndUpdate(req.params.id, { priority: req.body.priority }, { new: true })
      .populate('submittedBy', 'name email').populate('assignedTo', 'name email');
    if (!complaint) return res.status(404).json({ success: false, message: 'Not found' });
    res.json({ success: true, data: complaint });
  } catch (error) { next(error); }
});

// GET /api/admin/staff
router.get('/staff', async (req, res, next) => {
  try {
    const staff = await User.find({ role: 'staff', isActive: true });
    const result = await Promise.all(staff.map(async (s) => {
      const count = await Complaint.countDocuments({ assignedTo: s._id, status: { $in: ['assigned', 'in_progress'] } });
      const ratedComplaints = await Complaint.find({
        assignedTo: s._id,
        'feedback.rating': { $exists: true, $ne: null }
      });
      const totalRatingsCount = ratedComplaints.length;
      let averageRating = s.averageRating || 0;
      if (totalRatingsCount > 0) {
        const sum = ratedComplaints.reduce((acc, c) => acc + (c.feedback.rating || 0), 0);
        averageRating = Math.round((sum / totalRatingsCount) * 10) / 10;
      }

      return {
        ...s.toObject(),
        activeAssignments: count,
        averageRating,
        totalRatingsCount
      };
    }));
    res.json({ success: true, data: result });
  } catch (error) { next(error); }
});

// GET /api/admin/staff/:id/feedback
router.get('/staff/:id/feedback', async (req, res, next) => {
  try {
    const staffId = req.params.id;
    const { supabase } = require('../config/supabase');
    const mongoose = require('mongoose');

    let staff = null;

    if (supabase) {
      const { data, error } = await supabase
        .from('users')
        .select('id, name, email, specialization, average_rating, total_ratings_count')
        .eq('id', staffId)
        .maybeSingle();

      if (data) {
        staff = {
          _id: data.id,
          id: data.id,
          name: data.name,
          email: data.email,
          specialization: data.specialization || 'general',
          averageRating: data.average_rating || 0,
          totalRatingsCount: data.total_ratings_count || 0
        };
      }
    }

    if (!staff) {
      if (mongoose.connection.readyState !== 0) {
        if (mongoose.Types.ObjectId.isValid(staffId)) {
          staff = await User.findById(staffId).select('name email specialization averageRating totalRatingsCount');
        }
        if (!staff) {
          staff = await User.findOne({ $or: [{ _id: staffId }, { id: staffId }] }).select('name email specialization averageRating totalRatingsCount');
        }
      }
    }

    if (!staff) {
      return res.status(404).json({ success: false, message: 'Staff member not found' });
    }

    let feedbacks = [];

    if (supabase) {
      const { data: cList } = await supabase
        .from('complaints')
        .select('*, submitted_by(*)')
        .eq('assigned_to', staffId);

      if (cList && cList.length > 0) {
        feedbacks = cList
          .filter(c => c && c.feedback && (c.feedback.rating !== undefined && c.feedback.rating !== null))
          .map(c => {
            const sent = (c.feedback.sentimentScore !== undefined && c.feedback.sentimentLabel)
              ? { score: c.feedback.sentimentScore, label: c.feedback.sentimentLabel }
              : analyzeSentiment(c.feedback.comment || '');
            return {
              id: c.id,
              complaintId: c.complaint_id || '',
              title: c.title || '',
              category: c.category || '',
              rating: c.feedback.rating,
              comment: c.feedback.comment || '',
              sentimentScore: sent.score,
              sentimentLabel: sent.label,
              submittedAt: c.feedback.submittedAt || c.created_at,
              student: c.submitted_by ? {
                id: c.submitted_by.id,
                name: c.submitted_by.name || 'Student',
                email: c.submitted_by.email || '',
                hostelBlock: c.submitted_by.hostel_block || '',
                roomNumber: c.submitted_by.room_number || '',
              } : null
            };
          });
      }
    }

    if (feedbacks.length === 0 && mongoose.connection.readyState !== 0) {
      let complaintsWithFeedback = [];
      if (mongoose.Types.ObjectId.isValid(staff._id || staffId)) {
        complaintsWithFeedback = await Complaint.find({
          assignedTo: staff._id || staffId,
          'feedback.rating': { $exists: true, $ne: null }
        })
        .populate('submittedBy', 'name email hostelBlock roomNumber')
        .sort({ 'feedback.submittedAt': -1, updatedAt: -1 });
      }

      feedbacks = (complaintsWithFeedback || [])
        .filter(c => c && c.feedback && c.feedback.rating)
        .map(c => {
          const sent = (c.feedback.sentimentScore !== undefined && c.feedback.sentimentLabel)
            ? { score: c.feedback.sentimentScore, label: c.feedback.sentimentLabel }
            : analyzeSentiment(c.feedback.comment || '');
          return {
            id: c._id,
            complaintId: c.complaintId || '',
            title: c.title || '',
            category: c.category || '',
            rating: c.feedback.rating,
            comment: c.feedback.comment || '',
            sentimentScore: sent.score,
            sentimentLabel: sent.label,
            submittedAt: c.feedback ? (c.feedback.submittedAt || c.updatedAt) : c.updatedAt,
            student: c.submittedBy ? {
              id: c.submittedBy._id,
              name: c.submittedBy.name || 'Student',
              email: c.submittedBy.email || '',
              hostelBlock: c.submittedBy.hostelBlock || '',
              roomNumber: c.submittedBy.roomNumber || '',
            } : null
          };
        });
    }

    const totalRatingsCount = feedbacks.length;
    const avgRating = totalRatingsCount > 0
      ? Math.round((feedbacks.reduce((acc, f) => acc + (f.rating || 0), 0) / totalRatingsCount) * 10) / 10
      : (staff.averageRating || 0);
    const avgSentimentScore = totalRatingsCount > 0
      ? Math.round((feedbacks.reduce((acc, f) => acc + (f.sentimentScore || 0), 0) / totalRatingsCount) * 100) / 100
      : (staff.averageSentimentScore || 0);

    return res.json({
      success: true,
      data: {
        staff: {
          id: staff._id || staff.id,
          name: staff.name,
          email: staff.email,
          specialization: staff.specialization,
          averageRating: avgRating,
          averageSentimentScore: avgSentimentScore,
          totalRatingsCount
        },
        feedbacks
      }
    });
  } catch (error) { next(error); }
});

module.exports = router;

