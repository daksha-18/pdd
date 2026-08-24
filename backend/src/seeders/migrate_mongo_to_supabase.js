const mongoose = require('mongoose');
const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();

const User = require('../models/User');
const Complaint = require('../models/Complaint');

const mongoUri = process.env.MONGODB_URI || 'mongodb://localhost:27017/hostelcare';
const supabaseUrl = process.env.SUPABASE_URL || '';
const supabaseKey = process.env.SUPABASE_KEY || process.env.SUPABASE_ANON_KEY || process.env.SUPABASE_SERVICE_ROLE_KEY || '';

async function migrateData() {
  console.log('🔄 Starting MongoDB to Supabase Data Migration...');

  if (!supabaseUrl || !supabaseKey) {
    console.error('❌ Error: SUPABASE_URL and SUPABASE_KEY are required in process.env');
    process.exit(1);
  }

  const supabase = createClient(supabaseUrl, supabaseKey);

  try {
    console.log('📡 Connecting to MongoDB...');
    await mongoose.connect(mongoUri, { serverSelectionTimeoutMS: 5000 });
    console.log('✅ Connected to MongoDB');

    // 1. Migrate Users
    const users = await User.find({}).lean();
    console.log(`📦 Found ${users.length} users in MongoDB`);
    for (const u of users) {
      const userPayload = {
        id: u._id.toString(),
        name: u.name,
        email: u.email,
        password: u.password,
        role: u.role || 'student',
        hostel_block: u.hostelBlock || '',
        room_number: u.roomNumber || '',
        phone: u.phone || '',
        specialization: u.specialization || 'general',
        is_approved: u.isApproved !== undefined ? u.isApproved : true,
        created_at: u.createdAt || new Date(),
        updated_at: u.updatedAt || new Date(),
      };

      const { error } = await supabase.from('users').upsert(userPayload);
      if (error) {
        console.error(`❌ Failed to migrate user ${u.email}:`, error.message);
      } else {
        console.log(`✅ Migrated user: ${u.email}`);
      }
    }

    // 2. Migrate Complaints
    const complaints = await Complaint.find({}).lean();
    console.log(`📦 Found ${complaints.length} complaints in MongoDB`);
    for (const c of complaints) {
      const complaintPayload = {
        id: c._id.toString(),
        complaint_id: c.complaintId || `HC-${String(c._id).slice(-5)}`,
        title: c.title,
        description: c.description,
        category: c.category,
        priority: c.priority || 'medium',
        status: c.status || 'pending',
        location: c.location || {},
        submitted_by: c.submittedBy ? c.submittedBy.toString() : null,
        assigned_to: c.assignedTo ? c.assignedTo.toString() : null,
        qr_scanned: c.qrScanned || false,
        images: c.images || [],
        completion_images: c.completionImages || [],
        resolution_notes: c.resolutionNotes || '',
        status_history: c.statusHistory || [],
        created_at: c.createdAt || new Date(),
        updated_at: c.updatedAt || new Date(),
      };

      const { error } = await supabase.from('complaints').upsert(complaintPayload);
      if (error) {
        console.error(`❌ Failed to migrate complaint ${c.complaintId}:`, error.message);
      } else {
        console.log(`✅ Migrated complaint: ${c.complaintId}`);
      }
    }

    console.log('🎉 Data migration completed successfully!');
    process.exit(0);
  } catch (err) {
    console.error('❌ Migration failed:', err.message);
    process.exit(1);
  }
}

migrateData();
