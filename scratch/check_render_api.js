const https = require('https');

function checkRender() {
  https.get('https://pdd-1-n2am.onrender.com/api/health', (res) => {
    let data = '';
    res.on('data', (chunk) => data += chunk);
    res.on('end', () => console.log('Render Health Status:', res.statusCode, data));
  }).on('error', (err) => console.error('Render error:', err.message));
}

checkRender();
