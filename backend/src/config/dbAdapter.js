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
      return {
        _id: data.id,
        id: data.id,
        name: data.name,
        email: data.email,
        role: data.role,
        hostelBlock: data.hostel_block,
        roomNumber: data.room_number,
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

      const { data, error } = await supabase.from('complaints').insert([payload]).select().single();
      if (error) throw new Error(error.message);

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
        submittedBy: data.submitted_by,
        images: data.images,
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
      if (filter.assignedTo) query = query.eq('assigned_to', filter.assignedTo);
      if (filter.status) query = query.eq('status', filter.status);
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
      return data;
    } else {
      return await Complaint.findByIdAndUpdate(id, updateData, { new: true });
    }
  },
};

module.exports = dbAdapter;
