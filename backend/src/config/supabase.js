const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();

const supabaseUrl = process.env.SUPABASE_URL || '';
const supabaseKey = process.env.SUPABASE_KEY || process.env.SUPABASE_ANON_KEY || process.env.SUPABASE_SERVICE_ROLE_KEY || '';

let supabase = null;

if (supabaseUrl && supabaseKey) {
  supabase = createClient(supabaseUrl, supabaseKey);
  console.log('⚡ Supabase Client initialized successfully over HTTPS');
} else {
  console.warn('⚠️ Supabase credentials (SUPABASE_URL and SUPABASE_KEY) are missing in environment variables.');
}

module.exports = { supabase, createClient };
