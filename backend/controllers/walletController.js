const Wallet = require('../models/Wallet');

// @desc    Get or create user's wallet
// @route   GET /api/wallets/my-wallet
// @access  Private
exports.getMyWallet = async (req, res, next) => {
  try {
    let wallet = await Wallet.findOne({
      userType: req.user.role === 'driver' ? 'Driver' : 'User',
      userId: req.user.role === 'driver' ? req.user.id : req.user.id
    });
    
    if (!wallet) {
      wallet = await Wallet.create({
        userType: req.user.role === 'driver' ? 'Driver' : 'User',
        userId: req.user.id,
        balance: 0
      });
    }
    
    res.status(200).json({ success: true, data: wallet });
  } catch (error) {
    next(error);
  }
};

// @desc    Add money to wallet
// @route   POST /api/wallets/top-up
// @access  Private
exports.topUpWallet = async (req, res, next) => {
  try {
    const { amount, reference } = req.body;
    const wallet = await Wallet.findOne({
      userType: req.user.role === 'driver' ? 'Driver' : 'User',
      userId: req.user.id
    });
    
    if (!wallet) {
      return res.status(404).json({ success: false, message: 'Wallet not found' });
    }
    
    wallet.balance += amount;
    wallet.transactions.push({
      amount,
      type: 'credit',
      description: 'Wallet top-up',
      reference
    });
    
    await wallet.save();
    res.status(200).json({ success: true, data: wallet });
  } catch (error) {
    next(error);
  }
};

// @desc    Deduct money from wallet
// @route   POST /api/wallets/deduct
// @access  Private
exports.deductFromWallet = async (req, res, next) => {
  try {
    const { amount, reference, description } = req.body;
    const wallet = await Wallet.findOne({
      userType: req.user.role === 'driver' ? 'Driver' : 'User',
      userId: req.user.id
    });
    
    if (!wallet) {
      return res.status(404).json({ success: false, message: 'Wallet not found' });
    }
    
    if (wallet.balance < amount) {
      return res.status(400).json({ success: false, message: 'Insufficient balance' });
    }
    
    wallet.balance -= amount;
    wallet.transactions.push({
      amount,
      type: 'debit',
      description: description || 'Wallet debit',
      reference
    });
    
    await wallet.save();
    res.status(200).json({ success: true, data: wallet });
  } catch (error) {
    next(error);
  }
};

// @desc    Get all wallets (admin)
// @route   GET /api/wallets
// @access  Private/Admin
exports.getAllWallets = async (req, res, next) => {
  try {
    const wallets = await Wallet.find();
    res.status(200).json({ success: true, data: wallets });
  } catch (error) {
    next(error);
  }
};
