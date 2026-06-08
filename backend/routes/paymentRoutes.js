const express = require('express');
const router = express.Router();
const paymentService = require('../services/paymentService');
const Payment = require('../models/Payment');
const { protect } = require('../middleware/authMiddleware');

router.use(protect);

// Create payment order
router.post('/create-order', async (req, res) => {
  try {
    const { amount, rideId, notes } = req.body;

    if (!amount || !rideId) {
      return res.status(400).json({
        success: false,
        message: 'Please provide amount and rideId',
      });
    }

    const order = await paymentService.createOrder(
      amount,
      'INR',
      `ride_${rideId}`,
      { rideId, userId: req.user._id.toString(), ...notes }
    );

    if (!order) {
      return res.status(500).json({
        success: false,
        message: 'Failed to create payment order',
      });
    }

    res.status(200).json({
      success: true,
      data: { order },
    });
  } catch (error) {
    console.error('Create order error:', error);
    res.status(400).json({ success: false, message: error.message });
  }
});

// Verify payment
router.post('/verify', async (req, res) => {
  try {
    const {
      razorpay_order_id,
      razorpay_payment_id,
      razorpay_signature,
      rideId,
    } = req.body;

    if (!razorpay_order_id || !razorpay_payment_id || !razorpay_signature || !rideId) {
      return res.status(400).json({
        success: false,
        message: 'Please provide all payment details',
      });
    }

    const isValid = paymentService.verifyPaymentSignature(
      razorpay_order_id,
      razorpay_payment_id,
      razorpay_signature
    );

    if (!isValid) {
      return res.status(400).json({
        success: false,
        message: 'Invalid payment signature',
      });
    }

    // Save payment to database
    const payment = await Payment.create({
      user: req.user._id,
      ride: rideId,
      razorpayOrderId: razorpay_order_id,
      razorpayPaymentId: razorpay_payment_id,
      amount: (await paymentService.fetchPayment(razorpay_payment_id)).amount / 100,
      paymentMethod: 'razorpay',
      status: 'completed',
    });

    res.status(200).json({
      success: true,
      message: 'Payment verified successfully',
      data: { payment },
    });
  } catch (error) {
    console.error('Verify payment error:', error);
    res.status(400).json({ success: false, message: error.message });
  }
});

module.exports = router;