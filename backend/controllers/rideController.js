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
    const { pickupLocation, dropLocation, fare, distance, duration, vehicleType } = req.body;
    
    const ride = await Ride.create({
      user: req.user._id,
      pickupLocation,
      dropLocation,
      fare,
      distance,
      duration,
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

    nearbyDrivers.forEach((driver) => {
      io.to(driver.user.toString()).emit('newRideRequest', rideData);
    });

    res.status(201).json({
      status: 'success',
      data: { ride, nearbyDriversCount: nearbyDrivers.length, notificationsCount: notifications.length },
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
    const driver = await Driver.findOne({ user: req.user._id });
    
    if (!driver) {
      return res.status(404).json({ status: 'fail', message: 'Driver not found' });
    }

    const rides = await Ride.find({ driver: driver._id })
      .populate('user')
      .sort({ createdAt: -1 });

    res.status(200).json({ status: 'success', data: { rides } });
  } catch (error) {
    res.status(400).json({ status: 'error', message: error.message });
  }
};

module.exports = { estimateFare, createRide, updateRideStatus, getRide, getDriverRides };
