const { Server } = require('socket.io');
const Driver = require('../models/Driver');
const Ride = require('../models/Ride');
const { applyRideStatusTransition } = require('../services/rideLifecycleService');

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

// Helper to broadcast driver status change to vendor
const broadcastDriverStatus = async (io, driver) => {
  try {
    // If driver has a vendor, broadcast to that vendor's room
    if (driver.vendor) {
      const vendorId = driver.vendor.toString();
      const statusData = {
        driverId: driver._id.toString(),
        isOnline: driver.isOnline,
        status: driver.status,
        isBusy: driver.isBusy,
        lastSeen: driver.lastSeen
      };
      console.log(`Broadcasting driver status to vendor ${vendorId}:`, statusData);
      io.to(`vendor-${vendorId}`).emit('driverStatusChanged', statusData);
    }
    // Also broadcast to all (for cases where vendor isn't in a specific room yet)
    io.emit('driverStatusChanged', {
      driverId: driver._id.toString(),
      isOnline: driver.isOnline,
      status: driver.status,
      isBusy: driver.isBusy,
      lastSeen: driver.lastSeen
    });
  } catch (err) {
    console.error('Error broadcasting driver status:', err);
  }
};

const initSocket = (server) => {
  const io = new Server(server, {
    cors: {
      origin: '*',
      methods: ['GET', 'POST'],
    },
  });

  io.on('connection', (socket) => {
    console.log('Driver connected:', socket.id);

    // Join user/driver to their own room
    socket.on('join', async (driverId) => {
      console.log(`Driver socket join requested: driverId=${driverId} socketId=${socket.id}`);
      try {
        let driver = await Driver.findOne({ user: driverId }).populate('user');

        if (!driver) {
          driver = await Driver.findById(driverId).populate('user');
        }

        if (driver) {
          const driverRoom = driver._id.toString();
          const userRoom = driver.user ? driver.user._id.toString() : driverId;

          socket.join(driverRoom);
          socket.join(userRoom);

          await Driver.findByIdAndUpdate(
            driver._id,
            { socketId: socket.id, lastSeen: new Date() },
            { new: true }
          );

          console.log(`Driver room joined: ${driverRoom} | User room joined: ${userRoom} | Socket ID: ${socket.id}`);
        } else {
          socket.join(driverId);
          console.log(`Fallback room joined: ${driverId}`);
        }
      } catch (err) {
        console.error('Error associating driver socket:', err);
      }
    });

    // Vendor joins their specific room for driver updates
    socket.on('joinVendor', async (vendorId) => {
      const vendorRoom = `vendor-${vendorId}`;
      socket.join(vendorRoom);
      console.log(`Vendor ${vendorId} joined room ${vendorRoom}`);
    });

    // Driver goes online
    socket.on('goOnline', async (data) => {
      const { driverId } = data; // driverId here can be user._id or standalone Driver _id
      console.log(`goOnline event received for driverId=${driverId} payload=${JSON.stringify(data)}`);
      try {
        let driver = await Driver.findOneAndUpdate(
          { user: driverId },
          {
            isOnline: true,
            isAvailable: true,
            status: 'available',
            lastSeen: new Date(),
            socketId: socket.id,
            ...(data?.lat && data?.lng ? {
              currentLocation: { coordinates: [data.lng, data.lat] },
              currentLatitude: data.lat,
              currentLongitude: data.lng,
            } : {})
          },
          { new: true }
        );

        if (!driver) {
          console.log(`goOnline fallback: driver not found by user=${driverId}, trying by _id`);
          driver = await Driver.findByIdAndUpdate(
            driverId,
            {
              isOnline: true,
              isAvailable: true,
              status: 'available',
              lastSeen: new Date(),
              socketId: socket.id,
              ...(data?.lat && data?.lng ? {
                currentLocation: { coordinates: [data.lng, data.lat] },
                currentLatitude: data.lat,
                currentLongitude: data.lng,
              } : {})
            },
            { new: true }
          );
        }

        if (driver) {
          console.log(`Driver ${driverId} (${driver._id}) is now online`);
          await broadcastDriverStatus(io, driver);
        }
      } catch (err) {
        console.error('Error setting driver online:', err);
      }
    });

    // Driver goes offline
    socket.on('goOffline', async (data) => {
      const { driverId } = data; // driverId here can be user._id or standalone Driver _id
      console.log(`goOffline event received for driverId=${driverId} payload=${JSON.stringify(data)}`);
      try {
        let driver = await Driver.findOneAndUpdate(
          { user: driverId },
          {
            isOnline: false,
            isAvailable: false,
            status: 'offline',
            lastSeen: new Date()
          },
          { new: true }
        );

        if (!driver) {
          console.log(`goOffline fallback: driver not found by user=${driverId}, trying by _id`);
          driver = await Driver.findByIdAndUpdate(
            driverId,
            {
              isOnline: false,
              isAvailable: false,
              status: 'offline',
              lastSeen: new Date()
            },
            { new: true }
          );
        }

        if (driver) {
          console.log(`Driver ${driverId} (${driver._id}) is now offline`);
          await broadcastDriverStatus(io, driver);
        }
      } catch (err) {
        console.error('Error setting driver offline:', err);
      }
    });

    // Update driver location in real-time
    socket.on('updateLocation', async (data) => {
      const { driverId, lat, lng } = data;
      try {
        let driver = await Driver.findOneAndUpdate(
          { user: driverId },
          { 
            currentLocation: { coordinates: [lng, lat] },
            currentLatitude: lat,
            currentLongitude: lng,
            lastSeen: new Date()
          },
          { new: true }
        );

        if (!driver) {
          driver = await Driver.findByIdAndUpdate(
            driverId,
            {
              currentLocation: { coordinates: [lng, lat] },
              currentLatitude: lat,
              currentLongitude: lng,
              lastSeen: new Date()
            },
            { new: true }
          );
        }
        
        if (driver) {
          // Track driver path while ride is active
          if (driver.currentRide) {
            const ride = await Ride.findById(driver.currentRide);
            if (ride) {
              ride.driverLocation = {
                type: 'Point',
                coordinates: [lng, lat],
              };
              ride.route = ride.route || [];
              ride.route.push({
                latitude: lat,
                longitude: lng,
                timestamp: new Date(),
              });
              await ride.save();

              if (ride.user) {
                io.to(ride.user.toString()).emit('driverLocationUpdated', {
                  driverId,
                  latitude: lat,
                  longitude: lng,
                  coordinates: [lng, lat],
                  rideId: ride._id,
                });
              }
            }
          }

          // Broadcast location to all users tracking this driver
          io.emit(`driverLocation-${driverId}`, { coordinates: [lng, lat] });
        }
      } catch (error) {
        console.error('Socket location update error:', error);
      }
    });

    // Ride request broadcasting
    socket.on('requestRide', async (rideData) => {
      const { rideId, nearbyDrivers } = rideData;
      console.log(`Socket requestRide event received for rideId=${rideId} drivers=${nearbyDrivers?.length || 0}`);
      nearbyDrivers.forEach((driver) => {
        const driverRoom = driver?._id?.toString();
        const userRoom = driver?.user?._id?.toString() || driver?.user?.toString();

        if (userRoom) {
          io.to(userRoom).emit('newRideRequest', rideData);
          io.to(userRoom).emit('ride-request', rideData);
        }

        if (driverRoom) {
          io.to(driverRoom).emit('newRideRequest', rideData);
          io.to(driverRoom).emit('ride-request', rideData);
        }
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
        
        const ride = await Ride.findById(rideId);
        
        if (!ride) {
          console.error('Ride not found:', rideId);
          return;
        }

        const transition = applyRideStatusTransition(ride, 'accepted');
        if (!transition.valid) {
          console.error('Invalid ride acceptance transition:', transition.reason);
          return;
        }

        ride.driver = driver._id;
        ride.driverId = driver._id.toString();
        await ride.save();

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
        const ride = await Ride.findById(rideId);
        if (!ride) return;

        const transition = applyRideStatusTransition(ride, 'arrived');
        if (!transition.valid) {
          console.error('Invalid arrive transition:', transition.reason);
          return;
        }

        await ride.save();

        const populatedRide = await Ride.findById(ride._id)
          .populate('user')
          .populate({
            path: 'driver',
            populate: { path: 'user' }
          });

        if (populatedRide && populatedRide.user) {
          const formattedRide = formatRideResponse(populatedRide);
          io.to(populatedRide.user._id.toString()).emit('driverArrived', formattedRide);
          io.to(populatedRide.user._id.toString()).emit('rideUpdated', formattedRide);
        }
      } catch (error) {
        console.error('Socket driverArrived error:', error);
      }
    });

    // Trip Started
    socket.on('tripStarted', async (data) => {
      const { rideId } = data;
      try {
        const ride = await Ride.findById(rideId);
        if (!ride) return;

        const transition = applyRideStatusTransition(ride, 'trip_started');
        if (!transition.valid) {
          console.error('Invalid trip start transition:', transition.reason);
          return;
        }

        await ride.save();

        const populatedRide = await Ride.findById(ride._id)
          .populate('user')
          .populate({
            path: 'driver',
            populate: { path: 'user' }
          });

        if (populatedRide && populatedRide.user) {
          const formattedRide = formatRideResponse(populatedRide);
          io.to(populatedRide.user._id.toString()).emit('tripStarted', formattedRide);
          io.to(populatedRide.user._id.toString()).emit('rideUpdated', formattedRide);
        }
      } catch (error) {
        console.error('Socket tripStarted error:', error);
      }
    });

    // Trip Completed
    socket.on('tripCompleted', async (data) => {
      const { rideId } = data;
      try {
        const ride = await Ride.findById(rideId);
        if (!ride) return;

        const transition = applyRideStatusTransition(ride, 'completed');
        if (!transition.valid) {
          console.error('Invalid trip completion transition:', transition.reason);
          return;
        }

        await ride.save();

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

        if (populatedRide && populatedRide.user) {
          const formattedRide = formatRideResponse(populatedRide);
          io.to(populatedRide.user._id.toString()).emit('tripCompleted', formattedRide);
          io.to(populatedRide.user._id.toString()).emit('rideUpdated', formattedRide);
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
          {
            socketId: null,
            isOnline: false,
            status: 'offline',
            lastSeen: new Date()
          },
          { new: true }
        );
        if (driver) {
          console.log(`Driver ${driver._id} disconnected, marked as offline`);
          await broadcastDriverStatus(io, driver);
        }
      } catch (err) {
        console.error('Error handling driver disconnect:', err);
      }
    });
  });

  return io;
};

module.exports = initSocket;
