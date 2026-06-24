const express = require('express');
const router = express.Router();
const {
  getMyWallet,
  topUpWallet,
  deductFromWallet,
  getAllWallets
} = require('../controllers/walletController');
const { protect, authorize } = require('../middleware/authMiddleware');

router.use(protect);

router.route('/')
  .get(authorize('admin'), getAllWallets);

router.route('/my-wallet').get(getMyWallet);
router.route('/top-up').post(topUpWallet);
router.route('/deduct').post(deductFromWallet);

module.exports = router;
