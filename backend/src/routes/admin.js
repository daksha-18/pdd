const router = require('express').Router();
const User = require('../models/User');
const Complaint = require('../models/Complaint');
const Notification = require('../models/Notification');
const { protect, authorize } = require('../middleware/auth');
const { sendPushNotification } = require('../config/firebase');

router.use(protect, authorize('admin'));

// GET /api/admin/users
router.get('/users', async (req, res, next) => {
  try {
    const { role, search, page = 1, limit = 20 } = req.query;
    const filter = { isActive: { $ne: false } };
    if (role) filter.role = role;
    if (search) {
      filter.$or = [
        { name: { $regex: search, $options: 'i' } },
        { email: { $regex: search, $options: 'i' } },
      ];
    }
    const total = await User.countDocuments(filter);
    const users = await User.find(filter)
      .sort('-createdAt')
      .skip((page - 1) * limit)
      .limit(parseInt(limit));
    res.json({ success: true, data: users, pagination: { total, page: parseInt(page), pages: Math.ceil(total / limit) } });
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
    if (status) filter.status = status;
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
      .populate('assignedTo', 'name email specialization')
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
      return { ...s.toObject(), activeAssignments: count };
    }));
    res.json({ success: true, data: result });
  } catch (error) { next(error); }
});

module.exports = router;
