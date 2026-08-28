const mongoose = require('mongoose');
const { supabase } = require('./supabase');

const syncSupabaseToMongo = async () => {
  if (!supabase) return;
  try {
    if (mongoose.connection.readyState === 0) {
      await mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/hostelcare', {
        serverSelectionTimeoutMS: 5000,
      });
    }

    const User = require('../models/User');
    const Complaint = require('../models/Complaint');

    const { data: sUsers } = await supabase.from('users').select('*');
    if (sUsers && sUsers.length > 0) {
      for (const u of sUsers) {
        await User.findOneAndUpdate(
          { email: u.email.toLowerCase() },
          {
            name: u.name,
            email: u.email.toLowerCase(),
            password: u.password,
            role: u.role,
            hostelBlock: u.hostel_block,
            roomNumber: u.room_number,
            phone: u.phone,
            specialization: u.specialization,
            isApproved: u.is_approved,
          },
          { upsert: true }
        ).catch(() => {});
      }
    }

    const { data: sComplaints } = await supabase.from('complaints').select('*');
    if (sComplaints && sComplaints.length > 0) {
      for (const c of sComplaints) {
        await Complaint.findOneAndUpdate(
          { complaintId: c.complaint_id },
          {
            complaintId: c.complaint_id,
            title: c.title,
            description: c.description,
            category: c.category,
            priority: c.priority,
            status: c.status,
            location: c.location,
            submittedBy: c.submitted_by,
            assignedTo: c.assigned_to,
            images: c.images || [],
            completionImages: c.completion_images || [],
            resolutionNotes: c.resolution_notes,
            statusHistory: c.status_history || [],
            qrScanned: c.qr_scanned,
            createdAt: c.created_at,
          },
          { upsert: true }
        ).catch(() => {});
      }
    }
    console.log('🔄 Dual Sync: Supabase database synced to MongoDB successfully.');
  } catch (err) {
    console.warn('⚠️ Dual Sync warning:', err.message);
  }
};

const autoAssignPendingComplaints = async () => {
  try {
    if (supabase) {
      const { data: pendingComplaints } = await supabase.from('complaints').select('*').or('status.eq.pending,assigned_to.is.null');
      const { data: sStaff } = await supabase.from('users').select('*').eq('role', 'staff');
      const staffList = sStaff || [];

      if (pendingComplaints && pendingComplaints.length > 0 && staffList.length > 0) {
        for (const c of pendingComplaints) {
          const mapCat = (cat) => {
            const k = (cat || '').toLowerCase();
            if (k === 'water' || k === 'plumbing') return 'plumbing';
            if (k === 'electrical') return 'electrical';
            if (k === 'internet' || k === 'wifi') return 'internet';
            if (k === 'cleaning' || k === 'housekeeping') return 'cleaning';
            return 'general';
          };
          const target = mapCat(c.category);
          let eligible = staffList.filter((s) => s.is_approved !== false && s.specialization === target);
          if (eligible.length === 0) eligible = staffList.filter((s) => s.is_approved !== false && s.specialization === 'general');
          if (eligible.length === 0) eligible = staffList.filter((s) => s.is_approved !== false);

          if (eligible.length > 0) {
            const chosen = eligible[0];
            const history = c.status_history || [];
            history.push({
              status: 'assigned',
              notes: `Auto-assigned to ${chosen.name} (${chosen.specialization || 'Department Staff'}) based on category (${c.category})`,
              timestamp: new Date(),
            });
            await supabase.from('complaints').update({
              assigned_to: chosen.id,
              status: 'assigned',
              status_history: history,
            }).eq('id', c.id);
          }
        }
      }
    }
  } catch (e) {
    console.warn('⚠️ Auto assign migration warning:', e.message);
  }
};

const connectDB = async () => {
  if (supabase) {
    console.log('⚡ Using Supabase (PostgreSQL over HTTPS / Port 443) - College Wi-Fi Compatible!');
    await autoAssignPendingComplaints();
    await syncSupabaseToMongo();
    return;
  }

  try {
    const conn = await mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/hostelcare', {
      serverSelectionTimeoutMS: 5000,
    });
    console.log(`✅ MongoDB Connected: ${conn.connection.host}`);
    try {
      const Complaint = require('../models/Complaint');
      await Complaint.updateMany(
        { status: 'closed', resolvedAt: { $exists: false }, 'feedback.rating': { $exists: false } },
        { $set: { status: 'withdrawn' } }
      );
    } catch (_) {}
  } catch (error) {
    console.error(`⚠️ MongoDB Connection Warning (College Wi-Fi port block): ${error.message}`);
  }
};

module.exports = connectDB;
