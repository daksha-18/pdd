const { supabase } = require('./supabase');
const User = require('../models/User');
const Complaint = require('../models/Complaint');
const bcrypt = require('bcryptjs');
const crypto = require('crypto');

const useSupabase = () => !!supabase;

// Helper to generate unique IDs if mongo ObjectId is not used
const generateId = () => crypto.randomBytes(12).toString('hex');

const dbAdapter = {
  useSupabase,

  // --- USER OPERATIONS ---
  async findUserByEmail(email) {
    if (useSupabase()) {
      const { data, error } = await supabase
        .from('users')
        .select('*')
        .eq('email', email.toLowerCase())
        .single();
      if (error || !data) return null;
      return {
        _id: data.id,
        id: data.id,
        name: data.name,
        email: data.email,
        password: data.password,
        role: data.role,
        hostelBlock: data.hostel_block,
        roomNumber: data.room_number,
        phone: data.phone,
        specialization: data.specialization,
        isApproved: data.is_approved,
        comparePassword: async (candidatePassword) => {
          return await bcrypt.compare(candidatePassword, data.password);
        },
      };
    } else {
      return await User.findOne({ email }).select('+password');
    }
  },

  async findUserById(id) {
    if (useSupabase()) {
      const { data, error } = await supabase
        .from('users')
        .select('*')
        .eq('id', id)
        .single();
      if (error || !data) return null;
      return {
        _id: data.id,
        id: data.id,
        name: data.name,
        email: data.email,
        role: data.role,
        hostelBlock: data.hostel_block,
        roomNumber: data.room_number,
        phone: data.phone,
        specialization: data.specialization,
        isApproved: data.is_approved,
      };
    } else {
      return await User.findById(id);
    }
  },

  async createUser(userData) {
    if (useSupabase()) {
      const salt = await bcrypt.genSalt(12);
      const hashedPassword = await bcrypt.hash(userData.password, salt);
      const newId = generateId();

      const payload = {
        id: newId,
        name: userData.name,
        email: userData.email.toLowerCase(),
        password: hashedPassword,
        role: userData.role || 'student',
        hostel_block: userData.hostelBlock || '',
        room_number: userData.roomNumber || '',
        phone: userData.phone || '',
        specialization: userData.specialization || 'general',
        is_approved: userData.isApproved !== undefined ? userData.isApproved : true,
      };

      const { data, error } = await supabase
        .from('users')
        .insert([payload])
        .select()
        .single();

      if (error) throw new Error(error.message);

      // Dual Sync to MongoDB
      User.findOneAndUpdate(
        { email: data.email },
        {
          name: data.name,
          email: data.email,
          password: payload.password,
          role: data.role,
          hostelBlock: data.hostel_block,
          roomNumber: data.room_number,
          phone: data.phone,
          specialization: data.specialization,
          isApproved: data.is_approved,
        },
        { upsert: true }
      ).catch(() => {});

      return {
        _id: data.id,
        id: data.id,
        name: data.name,
        email: data.email,
        role: data.role,
        hostelBlock: data.hostel_block,
        roomNumber: data.room_number,
        phone: data.phone,
        specialization: data.specialization,
      };
    } else {
      return await User.create(userData);
    }
  },

  async updateUser(id, updateData) {
    if (useSupabase()) {
      const payload = {};
      if (updateData.name !== undefined) payload.name = updateData.name;
      if (updateData.phone !== undefined) payload.phone = updateData.phone;
      if (updateData.hostelBlock !== undefined) payload.hostel_block = updateData.hostelBlock;
      if (updateData.roomNumber !== undefined) payload.room_number = updateData.roomNumber;
      if (updateData.isApproved !== undefined) payload.is_approved = updateData.isApproved;
      if (updateData.password !== undefined) {
        const salt = await bcrypt.genSalt(12);
        payload.password = await bcrypt.hash(updateData.password, salt);
      }

      const { data, error } = await supabase
        .from('users')
        .update(payload)
        .eq('id', id)
        .select()
        .single();

      if (error) throw new Error(error.message);

      // Dual Sync to MongoDB
      User.findOneAndUpdate({ email: data.email }, updateData).catch(() => {});

      return {
        _id: data.id,
        id: data.id,
        name: data.name,
        email: data.email,
        role: data.role,
        hostelBlock: data.hostel_block,
        roomNumber: data.room_number,
        phone: data.phone,
      };
    } else {
      return await User.findByIdAndUpdate(id, updateData, { new: true });
    }
  },

  async deleteUser(id) {
    if (useSupabase()) {
      const { error } = await supabase.from('users').delete().eq('id', id);
      if (error) throw new Error(error.message);
      return true;
    } else {
      return await User.findByIdAndDelete(id);
    }
  },

  async findUsers(query = {}) {
    if (useSupabase()) {
      let req = supabase.from('users').select('*');
      if (query.role) req = req.eq('role', query.role);
      const { data, error } = await req;
      if (error) throw new Error(error.message);
      return data.map((u) => ({
        _id: u.id,
        id: u.id,
        name: u.name,
        email: u.email,
        role: u.role,
        hostelBlock: u.hostel_block,
        roomNumber: u.room_number,
        phone: u.phone,
        specialization: u.specialization,
        isApproved: u.is_approved,
      }));
    } else {
      return await User.find(query);
    }
  },

  // --- COMPLAINT OPERATIONS ---
  async createComplaint(complaintData) {
    if (useSupabase()) {
      const newId = generateId();
      const { count } = await supabase.from('complaints').select('*', { count: 'exact', head: true });
      const complaintId = `HC-${String((count || 0) + 1).padStart(5, '0')}`;

      const payload = {
        id: newId,
        complaint_id: complaintId,
        title: complaintData.title,
        description: complaintData.description,
        category: complaintData.category,
        priority: complaintData.priority || 'medium',
        status: 'pending',
        location: complaintData.location || {},
        submitted_by: complaintData.submittedBy,
        qr_scanned: complaintData.qrScanned || false,
        images: complaintData.images || [],
        status_history: [{ status: 'pending', notes: 'Complaint submitted', timestamp: new Date() }],
      };

      // Auto-assign department staff based on category
      const mapCat = (c) => {
        const cat = (c || '').toLowerCase();
        if (cat === 'water' || cat === 'plumbing') return 'plumbing';
        if (cat === 'electrical') return 'electrical';
        if (cat === 'internet' || cat === 'wifi') return 'internet';
        if (cat === 'cleaning' || cat === 'housekeeping') return 'cleaning';
        return 'general';
      };
      const spec = mapCat(complaintData.category);

      try {
        const { data: sStaff } = await supabase.from('users').select('*').eq('role', 'staff');
        const { data: allComplaints } = await supabase.from('complaints').select('*');
        let eligible = (sStaff || []).filter((s) => s.is_approved !== false && (s.specialization || '').toLowerCase() === spec);
        if (eligible.length === 0) eligible = (sStaff || []).filter((s) => s.is_approved !== false && (s.specialization || '').toLowerCase() === 'general');
        if (eligible.length === 0) eligible = (sStaff || []).filter((s) => s.is_approved !== false);

        if (eligible.length > 0) {
          const activeComplaints = allComplaints || [];
          const workloads = eligible.map((s) => {
            const count = activeComplaints.filter((c) => c.assigned_to === s.id && ['assigned', 'in_progress'].includes(c.status)).length;
            return { staff: s, count };
          });
          workloads.sort((a, b) => a.count - b.count);
          const chosen = workloads[0].staff;

          payload.assigned_to = chosen.id;
          payload.status = 'assigned';
          payload.status_history.push({
            status: 'assigned',
            notes: `Auto-assigned to ${chosen.name} (${chosen.specialization || 'Department Staff'}) based on category (${complaintData.category})`,
            timestamp: new Date(),
          });
        }
      } catch (err) {
        console.warn('Auto assign error:', err.message);
      }

      const { data, error } = await supabase.from('complaints').insert([payload]).select('*, submitted_by(*), assigned_to(*)').single();
      if (error) throw new Error(error.message);

      // Dual Sync to MongoDB
      Complaint.findOneAndUpdate(
        { complaintId: data.complaint_id },
        {
          complaintId: data.complaint_id,
          title: data.title,
          description: data.description,
          category: data.category,
          priority: data.priority,
          status: data.status,
          location: data.location,
          submittedBy: data.submitted_by?.id || data.submitted_by,
          assignedTo: data.assigned_to?.id || data.assigned_to,
          images: data.images,
          statusHistory: data.status_history,
          createdAt: data.created_at,
        },
        { upsert: true }
      ).catch(() => {});

      return {
        _id: data.id,
        id: data.id,
        complaintId: data.complaint_id,
        title: data.title,
        description: data.description,
        category: data.category,
        priority: data.priority,
        status: data.status,
        location: data.location,
        submittedBy: data.submitted_by ? {
          _id: data.submitted_by.id,
          id: data.submitted_by.id,
          name: data.submitted_by.name,
          email: data.submitted_by.email,
        } : null,
        assignedTo: data.assigned_to ? {
          _id: data.assigned_to.id,
          id: data.assigned_to.id,
          name: data.assigned_to.name,
          specialization: data.assigned_to.specialization,
        } : null,
        images: data.images || [],
        statusHistory: data.status_history || [],
        createdAt: data.created_at,
      };
    } else {
      return await Complaint.create(complaintData);
    }
  },

  async findComplaints(filter = {}, options = {}) {
    if (useSupabase()) {
      let query = supabase.from('complaints').select('*, submitted_by(*), assigned_to(*)');
      if (filter.submittedBy) query = query.eq('submitted_by', filter.submittedBy);
      if (filter.staffUser) {
        const getCats = (spec) => {
          const s = (spec || '').toLowerCase();
          if (s === 'electrical') return ['electrical'];
          if (s === 'plumbing') return ['water', 'plumbing'];
          if (s === 'internet') return ['internet', 'wifi'];
          if (s === 'cleaning') return ['cleaning', 'housekeeping'];
          return ['furniture', 'security', 'other'];
        };
        const cats = getCats(filter.staffUser.specialization);
        query = query.or(`assigned_to.eq.${filter.staffUser.id},category.in.(${cats.join(',')})`);
      } else if (filter.assignedTo) {
        query = query.eq('assigned_to', filter.assignedTo);
      }
      if (filter.status) {
        if (typeof filter.status === 'object' && filter.status.$in) {
          query = query.in('status', filter.status.$in);
        } else {
          query = query.eq('status', filter.status);
        }
      }
      if (filter.category) query = query.eq('category', filter.category);

      query = query.order('created_at', { ascending: false });

      if (options.limit) {
        const page = options.page || 1;
        const from = (page - 1) * options.limit;
        const to = from + options.limit - 1;
        query = query.range(from, to);
      }

      const { data, error } = await query;
      if (error) throw new Error(error.message);

      return data.map((c) => ({
        _id: c.id,
        id: c.id,
        complaintId: c.complaint_id,
        title: c.title,
        description: c.description,
        category: c.category,
        priority: c.priority,
        status: c.status,
        location: c.location,
        submittedBy: c.submitted_by ? {
          _id: c.submitted_by.id,
          name: c.submitted_by.name,
          email: c.submitted_by.email,
          hostelBlock: c.submitted_by.hostel_block,
          roomNumber: c.submitted_by.room_number,
        } : null,
        assignedTo: c.assigned_to ? {
          _id: c.assigned_to.id,
          name: c.assigned_to.name,
          specialization: c.assigned_to.specialization,
        } : null,
        images: c.images || [],
        completionImages: c.completion_images || [],
        resolutionNotes: c.resolution_notes,
        statusHistory: c.status_history || [],
        qrScanned: c.qr_scanned,
        createdAt: c.created_at,
        updatedAt: c.updated_at,
      }));
    } else {
      let q = Complaint.find(filter).populate('submittedBy', 'name email hostelBlock roomNumber').populate('assignedTo', 'name specialization');
      if (options.limit) q = q.limit(options.limit).skip(((options.page || 1) - 1) * options.limit);
      return await q.sort({ createdAt: -1 });
    }
  },

  async findComplaintById(id) {
    if (useSupabase()) {
      const { data, error } = await supabase
        .from('complaints')
        .select('*, submitted_by(*), assigned_to(*)')
        .eq('id', id)
        .single();
      if (error || !data) return null;

      return {
        _id: data.id,
        id: data.id,
        complaintId: data.complaint_id,
        title: data.title,
        description: data.description,
        category: data.category,
        priority: data.priority,
        status: data.status,
        location: data.location,
        submittedBy: data.submitted_by ? {
          _id: data.submitted_by.id,
          name: data.submitted_by.name,
          email: data.submitted_by.email,
          hostelBlock: data.submitted_by.hostel_block,
          roomNumber: data.submitted_by.room_number,
        } : null,
        assignedTo: data.assigned_to ? {
          _id: data.assigned_to.id,
          name: data.assigned_to.name,
          specialization: data.assigned_to.specialization,
        } : null,
        images: data.images || [],
        completionImages: data.completion_images || [],
        resolutionNotes: data.resolution_notes,
        statusHistory: data.status_history || [],
        qrScanned: data.qr_scanned,
        createdAt: data.created_at,
        updatedAt: data.updated_at,
      };
    } else {
      return await Complaint.findById(id).populate('submittedBy', 'name email hostelBlock roomNumber').populate('assignedTo', 'name specialization');
    }
  },

  async updateComplaint(id, updateData) {
    if (useSupabase()) {
      const payload = {};
      if (updateData.status) payload.status = updateData.status;
      if (updateData.priority) payload.priority = updateData.priority;
      if (updateData.assignedTo) payload.assigned_to = updateData.assignedTo;
      if (updateData.resolutionNotes !== undefined) payload.resolution_notes = updateData.resolutionNotes;
      if (updateData.statusHistory) payload.status_history = updateData.statusHistory;
      if (updateData.completionImages) payload.completion_images = updateData.completionImages;

      const { data, error } = await supabase.from('complaints').update(payload).eq('id', id).select().single();
      if (error) throw new Error(error.message);

      // Dual Sync to MongoDB
      Complaint.findOneAndUpdate(
        { $or: [{ _id: id }, { complaintId: id }] },
        updateData
      ).catch(() => {});

      return data;
    } else {
      return await Complaint.findByIdAndUpdate(id, updateData, { new: true });
    }
  },

  async getAnalyticsDashboard() {
    if (useSupabase()) {
      const { data: users, error: uErr } = await supabase.from('users').select('*');
      if (uErr) throw new Error(uErr.message);

      const activeUsers = (users || []).filter((u) => u.is_approved !== false);
      const activeUserIds = new Set(activeUsers.map((u) => u.id));

      const { data: complaints, error: cErr } = await supabase.from('complaints').select('*');
      if (cErr) throw new Error(cErr.message);

      const filteredComplaints = (complaints || []).filter((c) => activeUserIds.has(c.submitted_by));

      const totalComplaints = filteredComplaints.length;
      const pending = filteredComplaints.filter((c) => c.status === 'pending').length;
      const assigned = filteredComplaints.filter((c) => c.status === 'assigned').length;
      const inProgress = filteredComplaints.filter((c) => c.status === 'in_progress').length;
      const resolved = filteredComplaints.filter((c) => ['resolved', 'closed'].includes(c.status)).length;
      const closed = filteredComplaints.filter((c) => c.status === 'closed').length;

      const totalStudents = activeUsers.filter((u) => u.role === 'student').length;
      const totalStaff = activeUsers.filter((u) => u.role === 'staff').length;

      const catMap = {};
      filteredComplaints.forEach((c) => {
        const cat = c.category || 'other';
        catMap[cat] = (catMap[cat] || 0) + 1;
      });
      const categoryDistribution = Object.keys(catMap)
        .map((cat) => ({ _id: cat, count: catMap[cat] }))
        .sort((a, b) => b.count - a.count);

      const prioMap = {};
      filteredComplaints.forEach((c) => {
        const prio = c.priority || 'medium';
        prioMap[prio] = (prioMap[prio] || 0) + 1;
      });
      const priorityDistribution = Object.keys(prioMap).map((prio) => ({
        _id: prio,
        count: prioMap[prio],
      }));

      const resTimes = filteredComplaints
        .filter((c) => c.resolved_at)
        .map((c) => new Date(c.resolved_at) - new Date(c.created_at));
      const avgResMs = resTimes.length > 0 ? resTimes.reduce((a, b) => a + b, 0) / resTimes.length : 0;
      const avgResolutionHours = Math.round(avgResMs / 3600000);

      const trendMap = {};
      filteredComplaints.forEach((c) => {
        const d = new Date(c.created_at || Date.now());
        const key = `${d.getFullYear()}-${d.getMonth() + 1}`;
        trendMap[key] = (trendMap[key] || 0) + 1;
      });
      const monthlyTrend = Object.keys(trendMap).map((k) => {
        const [year, month] = k.split('-').map(Number);
        return { _id: { year, month }, count: trendMap[k] };
      });

      return {
        overview: { totalComplaints, pending, assigned, inProgress, resolved, closed, totalStudents, totalStaff },
        categoryDistribution,
        priorityDistribution,
        avgResolutionHours,
        monthlyTrend,
      };
    } else {
      const activeUsers = await User.find({ isActive: { $ne: false } }).select('_id');
      const activeUserIds = activeUsers.map((u) => u._id);
      const activeFilter = { submittedBy: { $in: activeUserIds } };

      const [totalComplaints, pending, assigned, inProgress, resolved, closed, totalStudents, totalStaff] = await Promise.all([
        Complaint.countDocuments(activeFilter),
        Complaint.countDocuments({ ...activeFilter, status: 'pending' }),
        Complaint.countDocuments({ ...activeFilter, status: 'assigned' }),
        Complaint.countDocuments({ ...activeFilter, status: 'in_progress' }),
        Complaint.countDocuments({ ...activeFilter, status: { $in: ['resolved', 'closed'] } }),
        Complaint.countDocuments({ ...activeFilter, status: 'closed' }),
        User.countDocuments({ role: 'student', isActive: { $ne: false } }),
        User.countDocuments({ role: 'staff', isActive: { $ne: false } }),
      ]);

      const categoryDist = await Complaint.aggregate([
        { $match: activeFilter },
        { $group: { _id: '$category', count: { $sum: 1 } } },
        { $sort: { count: -1 } },
      ]);

      const priorityDist = await Complaint.aggregate([
        { $match: activeFilter },
        { $group: { _id: '$priority', count: { $sum: 1 } } },
      ]);

      const avgResolution = await Complaint.aggregate([
        { $match: { resolvedAt: { $exists: true } } },
        { $project: { resTime: { $subtract: ['$resolvedAt', '$createdAt'] } } },
        { $group: { _id: null, avg: { $avg: '$resTime' } } },
      ]);
      const avgResolutionHours = avgResolution.length > 0 ? Math.round(avgResolution[0].avg / 3600000) : 0;

      const sixMonthsAgo = new Date();
      sixMonthsAgo.setMonth(sixMonthsAgo.getMonth() - 6);
      const monthlyTrend = await Complaint.aggregate([
        { $match: { createdAt: { $gte: sixMonthsAgo } } },
        { $group: { _id: { year: { $year: '$createdAt' }, month: { $month: '$createdAt' } }, count: { $sum: 1 } } },
        { $sort: { '_id.year': 1, '_id.month': 1 } },
      ]);

      return {
        overview: { totalComplaints, pending, assigned, inProgress, resolved, closed, totalStudents, totalStaff },
        categoryDistribution: categoryDist,
        priorityDistribution: priorityDist,
        avgResolutionHours,
        monthlyTrend,
      };
    }
  },

  async getStaffPerformance() {
    if (useSupabase()) {
      const { data: staff } = await supabase.from('users').select('*').eq('role', 'staff');
      const { data: complaints } = await supabase.from('complaints').select('*');
      const staffList = staff || [];
      const complaintList = complaints || [];

      return staffList.map((s) => {
        const assigned = complaintList.filter((c) => c.assigned_to === s.id);
        const resolved = assigned.filter((c) => (c.status === 'resolved' || c.status === 'closed') && c.resolved_at);
        const ratings = assigned.filter((c) => c.feedback && c.feedback.rating).map((c) => c.feedback.rating);

        const avgRating = ratings.length ? Math.round((ratings.reduce((a, b) => a + b, 0) / ratings.length) * 10) / 10 : (s.average_rating || 0);

        return {
          staff: { id: s.id, name: s.name, specialization: s.specialization },
          totalAssigned: assigned.length,
          totalResolved: resolved.length,
          avgResolutionHours: 0,
          avgRating,
        };
      });
    } else {
      const staff = await User.find({ role: 'staff', isActive: true });
      return await Promise.all(staff.map(async (s) => {
        const [total, resolved, avgRes] = await Promise.all([
          Complaint.countDocuments({ assignedTo: s._id }),
          Complaint.countDocuments({ assignedTo: s._id, status: { $in: ['resolved', 'closed'] }, resolvedAt: { $exists: true } }),
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
          avgRating: avgFeedback.length ? Math.round(avgFeedback[0].avg * 10) / 10 : (s.averageRating || 0),
        };
      }));
    }
  },
};

module.exports = dbAdapter;
