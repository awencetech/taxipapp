const Ride = require('../models/Ride');
const Notification = require('../models/Notification');
const { findNearbyDrivers, calculateFare } = require('../services/rideService');
const { getDistanceMatrix } = require('../services/mapsService');

const estimateFare = async (req, res) => {
  try {
    const { pickup, drop, vehicleType } = req.body; // {lat, lng}
    const distanceData = await getDistanceMatrix(pickup, drop);
    const fare = calculateFare(distanceData.distanceValue, vehicleType);

    res.status(200).json({
      status: 'success',
      data: {
        fare,
        distance: distanceData.distance,
        duration: distanceData.duration,
      },
    });
  } catch (error) {
    res.status(400).json({ status: 'error', message: error.message });
  }
};

const createRide = async (req, res) => {
  try {
    console.log('createRide - req.user:', req.user);
    console.log('createRide - req.body:', req.body);
    
    const { pickupLocation, dropLocation, fare, distance, duration, vehicleType, paymentMethod } = req.body;
    
    // Validate required fields
    if (!pickupLocation || !dropLocation || fare === undefined) {
      return res.status(400).json({ 
        status: 'error', 
        message: 'Missing required fields',
        received: req.body 
      });
    }
    
    const ride = await Ride.create({
      user: req.user._id,
      pickupLocation,
      dropLocation,
      fare,
      distance,
      duration,
      vehicleType: vehicleType || 'standard',
      paymentMethod: paymentMethod || 'cash',
      status: 'pending',
      otp: Math.floor(1000 + Math.random() * 9000).toString(),
    });

    // Find nearby drivers and notify them
    const nearbyDrivers = await findNearbyDrivers(
      pickupLocation.coordinates[1],
      pickupLocation.coordinates[0]
    );

    // Create notifications for all nearby drivers
    const notifications = [];
    for (const driver of nearbyDrivers) {
      const notification = await Notification.create({
        user: driver.user,
        title: 'New Ride Request!',
        message: `${req.user.name} has requested a ride`,
        type: 'ride',
        isRead: false,
        data: { rideId: ride._id },
      });
      notifications.push(notification);
    }

    // Get io instance and emit ride request to nearby drivers
    const io = req.app.get('io');
    const rideData = ride.toObject();
    rideData.user = { _id: req.user._id, name: req.user.name };

    // Emit rideCreated event to user
    const populatedRide = await Ride.findById(ride._id).populate('driver');
    io.to(req.user._id.toString()).emit('rideCreated', populatedRide);

    nearbyDrivers.forEach((driver) => {
      io.to(driver.user.toString()).emit('newRideRequest', rideData);
    });

    res.status(201).json({
      status: 'success',
      data: { ride, nearbyDriversCount: nearbyDrivers.length, notificationsCount: notifications.length },
    });
  } catch (error) {
    console.error('=== createRide Error ===');
    console.error('Error name:', error.name);
    console.error('Error message:', error.message);
    console.error('Error stack:', error.stack);
    res.status(400).json({ 
      status: 'error', 
      message: error.message,
      errorName: error.name,
      stack: process.env.NODE_ENV === 'development' ? error.stack : undefined
    });
  }
};

const cancelRide = async (req, res) => {
  try {
    const { rideId } = req.params;
    const { reason } = req.body;
    
    const ride = await Ride.findById(rideId);
    if (!ride) {
      return res.status(404).json({ status: 'error', message: 'Ride not found' });
    }

    // Check if ride is already cancelled or completed
    if (['completed', 'cancelled'].includes(ride.status)) {
      return res.status(400).json({ status: 'error', message: 'Ride cannot be cancelled' });
    }

    ride.status = 'cancelled';
    ride.cancellationReason = reason;
    await ride.save();

    // Get io instance
    const io = req.app.get('io');
    const populatedRide = await Ride.findById(ride._id).populate('driver');

    // Notify driver if assigned
    if (ride.driver) {
      io.to(ride.driver.toString()).emit('rideCancelled', { rideId: ride._id });
    }

    // Notify user
    if (ride.user) {
      io.to(ride.user.toString()).emit('rideUpdated', populatedRide);
    }

    res.status(200).json({
      status: 'success',
      data: { ride },
    });
  } catch (error) {
    res.status(400).json({ status: 'error', message: error.message });
  }
};

const updateRideStatus = async (req, res) => {
  try {
    const { status } = req.body;
    const ride = await Ride.findById(req.params.id);

    if (!ride) {
      return res.status(404).json({ status: 'fail', message: 'Ride not found' });
    }

    // Role based status update logic can be added here
    ride.status = status;
    if (status === 'started') ride.startTime = Date.now();
    if (status === 'completed') ride.endTime = Date.now();

    await ride.save();

    res.status(200).json({ status: 'success', data: { ride } });
  } catch (error) {
    res.status(400).json({ status: 'error', message: error.message });
  }
};

const getRide = async (req, res) => {
  try {
    const ride = await Ride.findById(req.params.id)
      .populate('user')
      .populate({
        path: 'driver',
        populate: { path: 'user vehicle' },
      });
    
    if (!ride) {
      return res.status(404).json({ status: 'fail', message: 'Ride not found' });
    }

    res.status(200).json({ status: 'success', data: { ride } });
  } catch (error) {
    res.status(400).json({ status: 'error', message: error.message });
  }
};

const getDriverRides = async (req, res) => {
  try {
    const Driver = require('../models/Driver');
    let driver = await Driver.findOne({ user: req.user._id });
    
    if (!driver) {
      console.log('Driver not found, creating new driver for user:', req.user._id);
      const uniqueTempLicense = `TEMP-LICENSE-${Date.now()}`;
      driver = await Driver.create({
        user: req.user._id,
        licenseNumber: uniqueTempLicense,
        vehicleType: 'Car',
        vehicleNumber: 'TN 01 AB 1234',
        address: '',
        bankName: '',
        accountHolderName: '',
        accountNumber: '',
        ifscCode: '',
        branchName: '',
      });
      console.log('New driver created:', driver._id);
    }

    const rides = await Ride.find({ driver: driver._id })
      .populate('user')
      .sort({ createdAt: -1 });

    res.status(200).json({ status: 'success', data: { rides } });
  } catch (error) {
    res.status(400).json({ status: 'error', message: error.message });
  }
};

const getUserRides = async (req, res) => {
  try {
    const rides = await Ride.find({ user: req.user._id })
      .populate('driver')
      .sort({ createdAt: -1 });

    res.status(200).json({ status: 'success', data: { rides } });
  } catch (error) {
    res.status(400).json({ status: 'error', message: error.message });
  }
};

// ---------------------------
// New Driver Specific APIs
// ---------------------------

const getDriverHistory = async (req, res) => {
  try {
    const Driver = require('../models/Driver');
    let driver = await Driver.findOne({ user: req.user._id });

    if (!driver) {
      return res.status(404).json({ status: 'error', message: 'Driver not found' });
    }

    const rides = await Ride.find({
      driver: driver._id
    })
      .populate('user')
      .sort({ createdAt: -1 });

    res.status(200).json({
      status: 'success',
      data: { rides },
    });
  } catch (error) {
    res.status(400).json({ status: 'error', message: error.message });
  }
};

const getDriverCurrentRide = async (req, res) => {
  try {
    const Driver = require('../models/Driver');
    let driver = await Driver.findOne({ user: req.user._id });

    if (!driver) {
      return res.status(404).json({ status: 'error', message: 'Driver not found' });
    }

    const ride = await Ride.findOne({
      driver: driver._id,
      status: { $in: ['accepted', 'arrived', 'started'] },
    }).populate('user');

    res.status(200).json({
      status: 'success',
      data: { ride },
    });
  } catch (error) {
    res.status(400).json({ status: 'error', message: error.message });
  }
};

const driverAcceptRide = async (req, res) => {
  try {
    const Driver = require('../models/Driver');
    let driver = await Driver.findOne({ user: req.user._id });

    if (!driver) {
      return res.status(404).json({ status: 'error', message: 'Driver not found' });
    }

    const { rideId } = req.body;
    const ride = await Ride.findById(rideId);

    if (!ride) {
      return res.status(404).json({ status: 'error', message: 'Ride not found' });
    }

    if (ride.status !== 'pending') {
      return res.status(400).json({ status: 'error', message: 'Ride is not available' });
    }

    ride.driver = driver._id;
    ride.status = 'accepted';
    await ride.save();

    const io = req.app.get('io');
    const populatedRide = await Ride.findById(ride._id).populate('user driver');
    io.to(populatedRide.user._id.toString()).emit('rideAccepted', populatedRide);
    io.to(populatedRide.user._id.toString()).emit('rideUpdated', populatedRide);

    res.status(200).json({
      status: 'success',
      data: { ride: populatedRide },
    });
  } catch (error) {
    res.status(400).json({ status: 'error', message: error.message });
  }
};

const driverRejectRide = async (req, res) => {
  try {
    const { rideId, reason } = req.body;
    const ride = await Ride.findById(rideId);

    if (!ride) {
      return res.status(404).json({ status: 'error', message: 'Ride not found' });
    }

    if (['completed', 'cancelled'].includes(ride.status)) {
      return res.status(400).json({ status: 'error', message: 'Ride cannot be rejected' });
    }

    ride.status = 'cancelled';
    ride.cancellationReason = reason || 'Rejected by driver';
    await ride.save();

    const io = req.app.get('io');
    const populatedRide = await Ride.findById(ride._id).populate('driver');

    if (ride.user) {
      io.to(ride.user.toString()).emit('rideCancelled', { rideId: ride._id });
      io.to(ride.user.toString()).emit('rideUpdated', populatedRide);
    }

    res.status(200).json({
      status: 'success',
      data: { ride },
    });
  } catch (error) {
    res.status(400).json({ status: 'error', message: error.message });
  }
};

const driverArrived = async (req, res) => {
  try {
    const { rideId } = req.body;
    const ride = await Ride.findById(rideId);

    if (!ride) {
      return res.status(404).json({ status: 'error', message: 'Ride not found' });
    }

    if (ride.status !== 'accepted') {
      return res.status(400).json({ status: 'error', message: 'Ride not in accepted status' });
    }

    ride.status = 'arrived';
    await ride.save();

    const io = req.app.get('io');
    const populatedRide = await Ride.findById(ride._id).populate('driver');
    if (ride.user) {
      io.to(ride.user.toString()).emit('driverArrived', { rideId: ride._id });
      io.to(ride.user.toString()).emit('rideUpdated', populatedRide);
    }

    res.status(200).json({
      status: 'success',
      data: { ride },
    });
  } catch (error) {
    res.status(400).json({ status: 'error', message: error.message });
  }
};

const driverStartTrip = async (req, res) => {
  try {
    const { rideId } = req.body;
    const ride = await Ride.findById(rideId);

    if (!ride) {
      return res.status(404).json({ status: 'error', message: 'Ride not found' });
    }

    if (ride.status !== 'arrived') {
      return res.status(400).json({ status: 'error', message: 'Driver not at pickup' });
    }

    ride.status = 'started';
    ride.startTime = Date.now();
    await ride.save();

    const io = req.app.get('io');
    const populatedRide = await Ride.findById(ride._id).populate('driver');
    if (ride.user) {
      io.to(ride.user.toString()).emit('tripStarted', { rideId: ride._id });
      io.to(ride.user.toString()).emit('rideUpdated', populatedRide);
    }

    res.status(200).json({
      status: 'success',
      data: { ride },
    });
  } catch (error) {
    res.status(400).json({ status: 'error', message: error.message });
  }
};

const driverCompleteTrip = async (req, res) => {
  try {
    const { rideId } = req.body;
    const ride = await Ride.findById(rideId);

    if (!ride) {
      return res.status(404).json({ status: 'error', message: 'Ride not found' });
    }

    if (ride.status !== 'started') {
      return res.status(400).json({ status: 'error', message: 'Trip not started' });
    }

    ride.status = 'completed';
    ride.endTime = Date.now();
    await ride.save();

    // Create notifications for both user and driver
    const Driver = require('../models/Driver');
    const driver = await Driver.findById(ride.driver);

    // Notification for user
    await Notification.create({
      user: ride.user,
      title: 'Trip Completed!',
      message: 'Your trip has been completed successfully!',
      type: 'ride',
      data: { rideId: ride._id }
    });

    // Notification for driver
    if (driver) {
      await Notification.create({
        user: driver.user,
        title: 'Trip Completed!',
        message: 'You have successfully completed a trip!',
        type: 'ride',
        data: { rideId: ride._id }
      });
    }

    const io = req.app.get('io');
    const populatedRide = await Ride.findById(ride._id).populate('driver');
    if (ride.user) {
      io.to(ride.user.toString()).emit('tripCompleted', { rideId: ride._id });
      io.to(ride.user.toString()).emit('rideUpdated', populatedRide);
    }

    if (driver && driver.user) {
      io.to(driver.user.toString()).emit('tripCompleted', { rideId: ride._id });
    }

    res.status(200).json({
      status: 'success',
      data: { ride },
    });
  } catch (error) {
    console.error('Complete Trip Error:', error);
    res.status(400).json({ status: 'error', message: error.message });
  }
};

module.exports = {
  estimateFare,
  createRide,
  cancelRide,
  updateRideStatus,
  getRide,
  getDriverRides,
  getUserRides,
  getDriverHistory,
  getDriverCurrentRide,
  driverAcceptRide,
  driverRejectRide,
  driverArrived,
  driverStartTrip,
  driverCompleteTrip
};
// End of file
