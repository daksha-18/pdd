const router = require('express').Router();
const dbAdapter = require('../config/dbAdapter');
const { protect, authorize } = require('../middleware/auth');

router.use(protect, authorize('admin'));

// GET /api/analytics/dashboard
router.get('/dashboard', async (req, res, next) => {
  try {
    const data = await dbAdapter.getAnalyticsDashboard();
    res.json({ success: true, data });
  } catch (error) { next(error); }
});

// GET /api/analytics/staff-performance
router.get('/staff-performance', async (req, res, next) => {
  try {
    const data = await dbAdapter.getStaffPerformance();
    res.json({ success: true, data });
  } catch (error) { next(error); }
});

module.exports = router;
