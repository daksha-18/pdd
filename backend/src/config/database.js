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

const connectDB = async () => {
  if (supabase) {
    console.log('⚡ Using Supabase (PostgreSQL over HTTPS / Port 443) - College Wi-Fi Compatible!');
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
