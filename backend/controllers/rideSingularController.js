const Ride = require('../models/Ride');
const Driver = require('../models/Driver');
const User = require('../models/User');
const { findNearbyDrivers } = require('../services/rideService');

const formatRideResponse = (ride) => {
  if (!ride) return null;
  const rideObj = ride.toObject ? ride.toObject() : ride;

  if (rideObj._id && !rideObj.rideId) {
    rideObj.rideId = rideObj._id.toString();
  }

  if (rideObj.user) {
    if (rideObj.user._id) {
      rideObj.userId = rideObj.user._id.toString();
      rideObj.userName = rideObj.user.name;
    } else {
      rideObj.userId = rideObj.user.toString();
    }
  }

  if (rideObj.driver) {
    if (rideObj.driver._id) {
      rideObj.driverId = rideObj.driver._id.toString();
    } else {
      rideObj.driverId = rideObj.driver.toString();
    }

    if (typeof rideObj.driver === 'object') {
      if (rideObj.driver.user && typeof rideObj.driver.user === 'object') {
        rideObj.driver.name = rideObj.driver.user.name;
        rideObj.driver.email = rideObj.driver.user.email;
        rideObj.driver.profilePic = rideObj.driver.user.profilePic;
        rideObj.driver.mobile = rideObj.driver.user.mobile;
      }
      rideObj.driver.rating = rideObj.driver.ratings || rideObj.driver.rating || 5.0;
    }
  }

  return rideObj;
};

const requestRide = async (req, res) => {
  try {
    const { pickupLocation, dropLocation, fare, distance, duration, vehicleType, paymentMethod, vendorId } = req.body;

    if (!pickupLocation || !dropLocation || fare === undefined) {
      return res.status(400).json({
        status: 'error',
        message: 'Missing required fields'
      });
    }

    const ride = await Ride.create({
      user: req.user._id,
      userId: req.user._id.toString(),
      vendorId: vendorId || null,
      pickupLocation,
      dropLocation,
      fare,
      distance,
      duration,
      vehicleType: vehicleType || 'Auto',
      paymentMethod: paymentMethod || 'Cash',
      status: 'searching',
      otp: Math.floor(1000 + Math.random() * 9000).toString(),
    });

    ride.rideId = ride._id.toString();
    await ride.save();

    // Find nearby online drivers who are available
    const nearbyDrivers = await Driver.find({
      isOnline: true,
      isBusy: false,
      status: 'available',
      isApproved: true,
      approvalStatus: 'approved',
      accountStatus: 'approved',
      currentLocation: {
        $near: {
          $geometry: {
            type: 'Point',
            coordinates: [pickupLocation.coordinates[0], pickupLocation.coordinates[1]],
          },
          $maxDistance: 10 * 1000, // 10 km radius limit
        },
      },
    }).populate('user');

    const io = req.app.get('io');
    const populatedRide = await Ride.findById(ride._id).populate('user');
    const rideData = formatRideResponse(populatedRide);

    console.log(`Ride created and dispatched to ${nearbyDrivers.length} nearby drivers`);

    // Send ride request to nearby online drivers
    nearbyDrivers.forEach((driver) => {
      if (driver.user) {
        const driverRoom = driver._id.toString();
        const userRoom = driver.user._id.toString();
        console.log(`Sending newRideRequest to driver room ${driverRoom} and user room ${userRoom}`);
        io.to(userRoom).emit('newRideRequest', rideData);
        io.to(userRoom).emit('ride-request', rideData);
        io.to(driverRoom).emit('newRideRequest', rideData);
        io.to(driverRoom).emit('ride-request', rideData);
        io.to(userRoom).emit('notification', {
          type: 'ride',
          title: 'New Ride Request',
          message: `${req.user.name} requested a ride`,
          rideId: ride._id.toString(),
        });
      }
    });

    res.status(201).json({
      status: 'success',
      data: { ride: rideData, nearbyDriversCount: nearbyDrivers.length }
    });
  } catch (error) {
    console.error('requestRide singular controller error:', error);
    res.status(400).json({ status: 'error', message: error.message });
  }
};

const acceptRide = async (req, res) => {
  try {
    const { rideId } = req.body;
    const driver = await Driver.findOne({ user: req.user._id }).populate('user');

    if (!driver) {
      return res.status(404).json({ status: 'error', message: 'Driver profile not found' });
    }

    const ride = await Ride.findById(rideId);
    if (!ride) {
      return res.status(404).json({ status: 'error', message: 'Ride not found' });
    }

    if (ride.status !== 'searching') {
      return res.status(400).json({ status: 'error', message: 'Ride is no longer available' });
    }

    // Update ride status
    ride.driver = driver._id;
    ride.driverId = driver._id.toString();
    ride.status = 'accepted';
    await ride.save();

    // Update driver status
    driver.isBusy = true;
    driver.currentRide = ride._id.toString();
    driver.status = 'busy';
    await driver.save();

    const populatedRide = await Ride.findById(ride._id)
      .populate('user')
      .populate({
        path: 'driver',
        populate: { path: 'user' }
      });

    const formattedRide = formatRideResponse(populatedRide);
    const io = req.app.get('io');

    if (populatedRide.user) {
      console.log(`Driver accepted. Emitting driverAccepted to user ${populatedRide.user._id.toString()}`);
      io.to(populatedRide.user._id.toString()).emit('driverAccepted', formattedRide);
      io.to(populatedRide.user._id.toString()).emit('ride-accepted', formattedRide);
      io.to(populatedRide.user._id.toString()).emit('rideAccepted', formattedRide);
      io.to(populatedRide.user._id.toString()).emit('ride-updated', formattedRide);
      io.to(populatedRide.user._id.toString()).emit('rideUpdated', formattedRide);
    }

    res.status(200).json({
      status: 'success',
      data: { ride: formattedRide }
    });
  } catch (error) {
    console.error('acceptRide error:', error);
    res.status(400).json({ status: 'error', message: error.message });
  }
};

const rejectRide = async (req, res) => {
  try {
    const { rideId, reason } = req.body;
    const driver = await Driver.findOne({ user: req.user._id });

    if (!driver) {
      return res.status(404).json({ status: 'error', message: 'Driver not found' });
    }

    const ride = await Ride.findById(rideId);
    if (!ride) {
      return res.status(404).json({ status: 'error', message: 'Ride not found' });
    }

    // Add driver to rejectedDrivers list
    if (!ride.rejectedDrivers.includes(driver._id)) {
      ride.rejectedDrivers.push(driver._id);
      await ride.save();
    }

    const io = req.app.get('io');

    // Attempt to search next nearby online driver
    const nextDrivers = await Driver.find({
      isOnline: true,
      isBusy: false,
      status: 'available',
      _id: { $nin: ride.rejectedDrivers },
      currentLocation: {
        $near: {
          $geometry: {
            type: 'Point',
            coordinates: [ride.pickupLocation.coordinates[0], ride.pickupLocation.coordinates[1]],
          },
          $maxDistance: 10 * 1000,
        },
      },
    }).populate('user');

    if (nextDrivers.length > 0) {
      // Dispatch request to next driver
      const populatedRide = await Ride.findById(ride._id).populate('user');
      const rideData = formatRideResponse(populatedRide);
      console.log(`Dispatching rejected ride to next driver user: ${nextDrivers[0].user._id.toString()}`);
      io.to(nextDrivers[0].user._id.toString()).emit('newRideRequest', rideData);
    } else {
      // No more drivers nearby
      console.log(`No more drivers left for ride ${rideId}. Notifying user of reject.`);
      if (ride.user) {
        io.to(ride.user.toString()).emit('driverRejected', { rideId: ride._id });
        io.to(ride.user.toString()).emit('rideCancelled', { rideId: ride._id, reason: 'No captains accepted your request' });
      }
    }

    res.status(200).json({
      status: 'success',
      message: 'Ride rejected successfully'
    });
  } catch (error) {
    console.error('rejectRide error:', error);
    res.status(400).json({ status: 'error', message: error.message });
  }
};

const arrived = async (req, res) => {
  try {
    const { rideId } = req.body;
    const ride = await Ride.findById(rideId);

    if (!ride) {
      return res.status(404).json({ status: 'error', message: 'Ride not found' });
    }

    ride.status = 'driver_arriving'; // Let's use driver_arriving first, or arrived
    // Wait, the prompt says: "Status values: searching, accepted, driver_arriving, arrived, trip_started, completed, cancelled"
    // Let's set it to 'arrived' or 'driver_arriving' as appropriate.
    // The arrived flow accepts "POST /ride/arrived" and updates status to arrived:
    ride.status = 'arrived';
    await ride.save();

    const populatedRide = await Ride.findById(ride._id)
      .populate('user')
      .populate({
        path: 'driver',
        populate: { path: 'user' }
      });

    const formattedRide = formatRideResponse(populatedRide);
    const io = req.app.get('io');

    if (populatedRide.user) {
      console.log(`Driver arrived. Emitting to user ${populatedRide.user._id.toString()}`);
      io.to(populatedRide.user._id.toString()).emit('driverArrived', formattedRide);
      io.to(populatedRide.user._id.toString()).emit('rideUpdated', formattedRide);
    }

    res.status(200).json({
      status: 'success',
      data: { ride: formattedRide }
    });
  } catch (error) {
    console.error('arrived error:', error);
    res.status(400).json({ status: 'error', message: error.message });
  }
};

const startTrip = async (req, res) => {
  try {
    const { rideId } = req.body;
    const ride = await Ride.findById(rideId);

    if (!ride) {
      return res.status(404).json({ status: 'error', message: 'Ride not found' });
    }

    ride.status = 'trip_started';
    ride.startTime = Date.now();
    await ride.save();

    const populatedRide = await Ride.findById(ride._id)
      .populate('user')
      .populate({
        path: 'driver',
        populate: { path: 'user' }
      });

    const formattedRide = formatRideResponse(populatedRide);
    const io = req.app.get('io');

    if (populatedRide.user) {
      console.log(`Trip started. Emitting to user ${populatedRide.user._id.toString()}`);
      io.to(populatedRide.user._id.toString()).emit('tripStarted', formattedRide);
      io.to(populatedRide.user._id.toString()).emit('rideUpdated', formattedRide);
    }

    res.status(200).json({
      status: 'success',
      data: { ride: formattedRide }
    });
  } catch (error) {
    console.error('startTrip error:', error);
    res.status(400).json({ status: 'error', message: error.message });
  }
};

const completeTrip = async (req, res) => {
  try {
    const { rideId } = req.body;
    const ride = await Ride.findById(rideId);

    if (!ride) {
      return res.status(404).json({ status: 'error', message: 'Ride not found' });
    }

    ride.status = 'completed';
    ride.endTime = Date.now();
    await ride.save();

    // Release driver
    if (ride.driver) {
      const driver = await Driver.findById(ride.driver);
      if (driver) {
        driver.isBusy = false;
        driver.currentRide = null;
        driver.status = 'available';
        await driver.save();
      }
    }

    const populatedRide = await Ride.findById(ride._id)
      .populate('user')
      .populate({
        path: 'driver',
        populate: { path: 'user' }
      });

    const formattedRide = formatRideResponse(populatedRide);
    const io = req.app.get('io');

    if (populatedRide.user) {
      console.log(`Trip completed. Emitting to user ${populatedRide.user._id.toString()}`);
      io.to(populatedRide.user._id.toString()).emit('tripCompleted', formattedRide);
      io.to(populatedRide.user._id.toString()).emit('rideUpdated', formattedRide);
    }

    res.status(200).json({
      status: 'success',
      data: { ride: formattedRide }
    });
  } catch (error) {
    console.error('completeTrip error:', error);
    res.status(400).json({ status: 'error', message: error.message });
  }
};

module.exports = {
  requestRide,
  acceptRide,
  rejectRide,
  arrived,
  startTrip,
  completeTrip,
  formatRideResponse
};
