require('dotenv').config();
const mongoose = require('mongoose');
const User = require('../models/User');
const Complaint = require('../models/Complaint');

const seed = async () => {
  await mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/hostelcare');
  console.log('Connected to MongoDB');

  // Clear existing data
  await User.deleteMany({});
  await Complaint.deleteMany({});

  // Create admin
  const admin = await User.create({
    name: 'Admin User', email: 'admin@hostelcare.com', password: 'admin123',
    role: 'admin', phone: '9876543210',
  });

  // Create staff
  const staff1 = await User.create({
    name: 'Rajesh Kumar', email: 'rajesh@hostelcare.com', password: 'staff123',
    role: 'staff', phone: '9876543211', specialization: 'electrical',
  });
  const staff2 = await User.create({
    name: 'Suresh Patel', email: 'suresh@hostelcare.com', password: 'staff123',
    role: 'staff', phone: '9876543212', specialization: 'plumbing',
  });

  // Create students
  const student1 = await User.create({
    name: 'Amit Sharma', email: 'amit@student.com', password: 'student123',
    role: 'student', hostelBlock: 'Block A', roomNumber: '101',
  });
  const student2 = await User.create({
    name: 'Priya Singh', email: 'priya@student.com', password: 'student123',
    role: 'student', hostelBlock: 'Block B', roomNumber: '205',
  });

  // Create sample complaints
  const sampleComplaints = [
    {
      title: 'Broken ceiling fan', description: 'The ceiling fan in my room is not working and makes noise.',
      category: 'electrical', priority: 'high', status: 'assigned', submittedBy: student1._id,
      assignedTo: staff1._id, location: { hostelBlock: 'Block A', roomNumber: '101', floor: '1' },
      statusHistory: [{ status: 'pending', changedBy: student1._id, notes: 'Submitted' }, { status: 'assigned', changedBy: admin._id, notes: 'Assigned to Rajesh' }],
    },
    {
      title: 'Water leakage in bathroom', description: 'There is a continuous water leak from the bathroom pipe.',
      category: 'water', priority: 'urgent', status: 'in_progress', submittedBy: student2._id,
      assignedTo: staff2._id, location: { hostelBlock: 'Block B', roomNumber: '205', floor: '2' },
      statusHistory: [{ status: 'pending', changedBy: student2._id }, { status: 'in_progress', changedBy: staff2._id }],
    },
    {
      title: 'WiFi not working', description: 'Internet connectivity has been down since yesterday.',
      category: 'internet', priority: 'medium', status: 'pending', submittedBy: student1._id,
      location: { hostelBlock: 'Block A', roomNumber: '101', floor: '1' },
    },
  ];

  for (const complaintData of sampleComplaints) {
    await Complaint.create(complaintData);
  }

  console.log('✅ Database seeded successfully');
  console.log('Admin: admin@hostelcare.com / admin123');
  console.log('Staff: rajesh@hostelcare.com / staff123');
  console.log('Student: amit@student.com / student123');
  process.exit(0);
};

seed().catch((err) => { console.error(err); process.exit(1); });
