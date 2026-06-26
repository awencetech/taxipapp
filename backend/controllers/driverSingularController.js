const Driver = require('../models/Driver');
const Ride = require('../models/Ride');
const { formatRideResponse } = require('./rideSingularController');

const getPendingRides = async (req, res) => {
  try {
    const driver = await Driver.findOne({ user: req.user._id });
    if (!driver) {
      return res.status(404).json({ status: 'error', message: 'Driver profile not found' });
    }

    // Pending rides are those in "searching" status that this driver hasn't rejected
    const rides = await Ride.find({
      status: 'searching',
      driver: null,
      rejectedDrivers: { $ne: driver._id }
    }).populate('user');

    const formattedRides = rides.map(formatRideResponse);

    res.status(200).json({
      status: 'success',
      results: formattedRides.length,
      data: { rides: formattedRides }
    });
  } catch (error) {
    console.error('getPendingRides error:', error);
    res.status(400).json({ status: 'error', message: error.message });
  }
};

const updateStatus = async (req, res) => {
  try {
    const { isOnline, isBusy } = req.body;
    const update = {};
    if (isOnline !== undefined) {
      update.isOnline = isOnline;
      update.status = isOnline ? 'available' : 'offline';
    }
    if (isBusy !== undefined) {
      update.isBusy = isBusy;
      if (isBusy) update.status = 'busy';
      else if (isOnline !== false) update.status = 'available';
    }

    const driver = await Driver.findOneAndUpdate(
      { user: req.user._id },
      update,
      { new: true }
    ).populate('user');

    if (!driver) {
      return res.status(404).json({ status: 'error', message: 'Driver not found' });
    }

    res.status(200).json({
      status: 'success',
      data: { driver }
    });
  } catch (error) {
    console.error('updateStatus error:', error);
    res.status(400).json({ status: 'error', message: error.message });
  }
};

module.exports = {
  getPendingRides,
  updateStatus
};
