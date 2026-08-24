const mongoose = require('mongoose');
const { supabase } = require('./supabase');

const connectDB = async () => {
  if (supabase) {
    console.log('⚡ Using Supabase (PostgreSQL over HTTPS / Port 443) - College Wi-Fi Compatible!');
    return;
  }

  try {
    const conn = await mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/hostelcare', {
      serverSelectionTimeoutMS: 5000,
    });
    console.log(`✅ MongoDB Connected: ${conn.connection.host}`);
  } catch (error) {
    console.error(`⚠️ MongoDB Connection Warning (College Wi-Fi port block): ${error.message}`);
  }
};

module.exports = connectDB;
