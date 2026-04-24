const router = require('express').Router();
const { protect } = require('../middleware/auth');

// Simple AI chatbot responses based on keyword matching
const knowledgeBase = {
  electrical: {
    keywords: ['electric', 'power', 'light', 'fan', 'socket', 'switch', 'wire', 'voltage'],
    response: 'For electrical issues: 1) Check if circuit breaker is tripped. 2) Verify outlet/switch. 3) If persistent, submit a complaint under "Electrical" category. Emergency? Call hostel electrician at ext. 111.',
    category: 'electrical',
  },
  water: {
    keywords: ['water', 'plumb', 'tap', 'leak', 'pipe', 'drain', 'toilet', 'bathroom', 'shower'],
    response: 'For water/plumbing issues: 1) Turn off water valve if leaking. 2) Don\'t use blocked drains. 3) Submit complaint under "Water" category. Urgent leak? Call maintenance at ext. 112.',
    category: 'water',
  },
  internet: {
    keywords: ['internet', 'wifi', 'network', 'lan', 'connection', 'slow', 'disconnect'],
    response: 'For internet issues: 1) Restart your router/device. 2) Check LAN cable connection. 3) Clear DNS cache. 4) If still down, submit under "Internet" category. IT helpdesk: ext. 113.',
    category: 'internet',
  },
  cleaning: {
    keywords: ['clean', 'dirty', 'garbage', 'trash', 'sweep', 'mop', 'pest', 'cockroach', 'rat'],
    response: 'For cleaning issues: 1) Report in "Cleaning" category. 2) For pest control, mention type and location. Cleaning schedule: 8AM-12PM daily. Supervisor: ext. 114.',
    category: 'cleaning',
  },
  furniture: {
    keywords: ['furniture', 'bed', 'chair', 'desk', 'table', 'cupboard', 'door', 'window', 'lock'],
    response: 'For furniture issues: Submit under "Furniture" category with photos. Include item type and damage description. Replacement timeline: 3-5 business days.',
    category: 'furniture',
  },
  security: {
    keywords: ['security', 'theft', 'stolen', 'safe', 'guard', 'cctv', 'emergency', 'fire'],
    response: 'For security concerns: 1) Contact security desk immediately at ext. 100. 2) For fire emergencies, call 101. 3) File formal complaint under "Security". CCTV footage requests need admin approval.',
    category: 'security',
  },
  complaint: {
    keywords: ['complaint', 'complain', 'report', 'issue', 'problem', 'submit', 'file', 'how to'],
    response: 'To submit a complaint: 1) Go to Home > Submit Complaint. 2) Fill title, description, category. 3) Add photos if possible. 4) You can scan QR code for auto-location. Track status in "My Complaints".',
    category: null,
  },
  status: {
    keywords: ['status', 'track', 'progress', 'update', 'where', 'when', 'pending'],
    response: 'To check complaint status: Go to "My Complaints" tab. Statuses: Pending → Assigned → In Progress → Resolved. You\'ll receive push notifications for every update.',
    category: null,
  },
};

// POST /api/chatbot/message
router.post('/message', protect, async (req, res) => {
  try {
    const { message } = req.body;
    if (!message) return res.status(400).json({ success: false, message: 'Message required' });

    const lower = message.toLowerCase();
    let bestMatch = null;
    let maxScore = 0;

    for (const [key, data] of Object.entries(knowledgeBase)) {
      const score = data.keywords.filter((kw) => lower.includes(kw)).length;
      if (score > maxScore) {
        maxScore = score;
        bestMatch = data;
      }
    }

    const reply = bestMatch
      ? { message: bestMatch.response, suggestedCategory: bestMatch.category, confidence: Math.min(maxScore / 3, 1) }
      : { message: 'I can help with Electrical, Water, Internet, Cleaning, Furniture, or Security issues. Could you describe your problem?', suggestedCategory: null, confidence: 0 };

    // Quick replies
    reply.quickReplies = ['Electrical issue', 'Water problem', 'Internet down', 'Need cleaning', 'Submit complaint', 'Check status'];

    res.json({ success: true, data: reply });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Chatbot error' });
  }
});

// POST /api/chatbot/categorize
router.post('/categorize', protect, async (req, res) => {
  try {
    const { title, description } = req.body;
    const text = `${title} ${description}`.toLowerCase();
    let best = 'other';
    let maxScore = 0;

    for (const [key, data] of Object.entries(knowledgeBase)) {
      if (!data.category) continue;
      const score = data.keywords.filter((kw) => text.includes(kw)).length;
      if (score > maxScore) {
        maxScore = score;
        best = data.category;
      }
    }

    res.json({ success: true, data: { category: best, confidence: Math.min(maxScore / 2, 1) } });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Categorization error' });
  }
});

module.exports = router;
