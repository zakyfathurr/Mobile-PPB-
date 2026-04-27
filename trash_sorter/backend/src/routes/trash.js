const express = require('express');
const router = express.Router();
const { verifyFirebaseToken } = require('../middleware/authMiddleware');
const {
  createScan,
  getScans,
  updateScan,
  deleteScan,
} = require('../controllers/trashController');

router.use(verifyFirebaseToken);

router.post('/',      createScan);   // POST   /trash
router.get('/',       getScans);     // GET    /trash
router.put('/:id',    updateScan);   // PUT    /trash/:id
router.delete('/:id', deleteScan);   // DELETE /trash/:id

module.exports = router;
