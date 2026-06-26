const { Server } = require('socket.io');
const Driver = require('../models/Driver');
const Ride = require('../models/Ride');

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

const initSocket = (server) => {
  const io = new Server(server, {
    cors: {
      origin: '*',
      methods: ['GET', 'POST'],
    },
  });

  io.on('connection', (socket) => {
    console.log('New client connected:', socket.id);

    // Join user/driver to their own room
    socket.on('join', async (userId) => {
      socket.join(userId);
      console.log(`User ${userId} joined their room ${userId}`);
      
      // Update socketId in Driver collection if this user is a driver
      try {
        const driver = await Driver.findOneAndUpdate(
          { user: userId },
          { socketId: socket.id, isOnline: true, status: 'available' },
          { new: true }
        );
        if (driver) {
          console.log(`Associated driver user ${userId} with socket ID ${socket.id}`);
        }
      } catch (err) {
        console.error('Error associating driver socket:', err);
      }
    });

    // Update driver location in real-time
    socket.on('updateLocation', async (data) => {
      const { driverId, lat, lng } = data;
      try {
        const driver = await Driver.findOneAndUpdate(
          { user: driverId },
          { 
            currentLocation: { coordinates: [lng, lat] },
            currentLatitude: lat,
            currentLongitude: lng
          },
          { new: true }
        );
        
        if (driver) {
          // Broadcast location to all users tracking this driver
          io.emit(`driverLocation-${driverId}`, { coordinates: [lng, lat] });

          // Send driverLocationUpdated to the active passenger
          if (driver.currentRide) {
            const ride = await Ride.findById(driver.currentRide);
            if (ride && ride.user) {
              io.to(ride.user.toString()).emit('driverLocationUpdated', {
                driverId,
                latitude: lat,
                longitude: lng,
                coordinates: [lng, lat]
              });
            }
          }
        }
      } catch (error) {
        console.error('Socket location update error:', error);
      }
    });

    // Ride request broadcasting
    socket.on('requestRide', async (rideData) => {
      const { rideId, nearbyDrivers } = rideData;
      nearbyDrivers.forEach((driver) => {
        io.to(driver.user.toString()).emit('newRideRequest', rideData);
      });
    });

    // Driver accepts ride
    socket.on('rideAccepted', async (data) => {
      const { rideId, driverId } = data;
      console.log(`Socket event rideAccepted received: rideId=${rideId}, driverId=${driverId}`);
      try {
        const driver = await Driver.findOne({ user: driverId }).populate('user');
        
        if (!driver) {
          console.error('Driver not found for user:', driverId);
          return;
        }
        
        const ride = await Ride.findByIdAndUpdate(
          rideId,
          { driver: driver._id, driverId: driver._id.toString(), status: 'accepted' },
          { new: true }
        );
        
        if (!ride) {
          console.error('Ride not found:', rideId);
          return;
        }

        driver.isBusy = true;
        driver.currentRide = rideId;
        driver.status = 'busy';
        await driver.save();
        
        const populatedRide = await Ride.findById(ride._id)
          .populate('user')
          .populate({
            path: 'driver',
            populate: { path: 'user' }
          });
        
        const formattedRide = formatRideResponse(populatedRide);

        // Notify user that ride is accepted
        if (populatedRide.user) {
          const userRoom = populatedRide.user._id.toString();
          console.log(`Emitting driverAccepted and rideAccepted to user room: ${userRoom}`);
          io.to(userRoom).emit('driverAccepted', formattedRide);
          io.to(userRoom).emit('rideAccepted', formattedRide);
          io.to(userRoom).emit('rideUpdated', formattedRide);
        }
      } catch (error) {
        console.error('Socket accept ride error:', error);
      }
    });

    // Driver rejects ride
    socket.on('rideRejected', async (data) => {
      const { rideId, driverId } = data;
      console.log(`Socket event rideRejected received: rideId=${rideId}, driverId=${driverId}`);
      try {
        const driver = await Driver.findOne({ user: driverId });
        if (!driver) return;

        const ride = await Ride.findById(rideId);
        if (!ride) return;

        if (!ride.rejectedDrivers.includes(driver._id)) {
          ride.rejectedDrivers.push(driver._id);
          await ride.save();
        }

        // Try to dispatch to next online available driver
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
          const populatedRide = await Ride.findById(ride._id).populate('user');
          const rideData = formatRideResponse(populatedRide);
          console.log(`Socket reject dispatching to next driver user room: ${nextDrivers[0].user._id.toString()}`);
          io.to(nextDrivers[0].user._id.toString()).emit('newRideRequest', rideData);
        } else {
          console.log(`Socket reject: no more drivers left. Notifying user.`);
          if (ride.user) {
            io.to(ride.user.toString()).emit('driverRejected', { rideId: ride._id });
            io.to(ride.user.toString()).emit('rideCancelled', { rideId: ride._id, reason: 'No captains accepted your request' });
          }
        }
      } catch (error) {
        console.error('Socket reject ride error:', error);
      }
    });

    // Driver Arrived
    socket.on('driverArrived', async (data) => {
      const { rideId } = data;
      try {
        const ride = await Ride.findByIdAndUpdate(
          rideId,
          { status: 'arrived' },
          { new: true }
        ).populate('user').populate({
          path: 'driver',
          populate: { path: 'user' }
        });

        if (ride && ride.user) {
          const formattedRide = formatRideResponse(ride);
          io.to(ride.user._id.toString()).emit('driverArrived', formattedRide);
          io.to(ride.user._id.toString()).emit('rideUpdated', formattedRide);
        }
      } catch (error) {
        console.error('Socket driverArrived error:', error);
      }
    });

    // Trip Started
    socket.on('tripStarted', async (data) => {
      const { rideId } = data;
      try {
        const ride = await Ride.findByIdAndUpdate(
          rideId,
          { status: 'trip_started', startTime: Date.now() },
          { new: true }
        ).populate('user').populate({
          path: 'driver',
          populate: { path: 'user' }
        });

        if (ride && ride.user) {
          const formattedRide = formatRideResponse(ride);
          io.to(ride.user._id.toString()).emit('tripStarted', formattedRide);
          io.to(ride.user._id.toString()).emit('rideUpdated', formattedRide);
        }
      } catch (error) {
        console.error('Socket tripStarted error:', error);
      }
    });

    // Trip Completed
    socket.on('tripCompleted', async (data) => {
      const { rideId } = data;
      try {
        const ride = await Ride.findByIdAndUpdate(
          rideId,
          { status: 'completed', endTime: Date.now() },
          { new: true }
        ).populate('user').populate({
          path: 'driver',
          populate: { path: 'user' }
        });

        if (ride) {
          if (ride.driver) {
            const driver = await Driver.findById(ride.driver);
            if (driver) {
              driver.isBusy = false;
              driver.currentRide = null;
              driver.status = 'available';
              await driver.save();
            }
          }
          if (ride.user) {
            const formattedRide = formatRideResponse(ride);
            io.to(ride.user._id.toString()).emit('tripCompleted', formattedRide);
            io.to(ride.user._id.toString()).emit('rideUpdated', formattedRide);
          }
        }
      } catch (error) {
        console.error('Socket tripCompleted error:', error);
      }
    });

    // Ride status updates
    socket.on('updateRideStatus', async (data) => {
      const { rideId, status, userId } = data;
      io.to(userId).emit('rideStatusUpdate', { rideId, status });
    });

    socket.on('disconnect', async () => {
      console.log('Client disconnected:', socket.id);
      try {
        const driver = await Driver.findOneAndUpdate(
          { socketId: socket.id },
          { socketId: null }
        );
        if (driver) {
          console.log(`Cleared socket association for driver user ${driver.user}`);
        }
      } catch (err) {
        console.error('Error clearing socket association:', err);
      }
    });
  });

  return io;
};

module.exports = initSocket;
