const { Server } = require('socket.io');
const Driver = require('../models/Driver');
const Ride = require('../models/Ride');

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
    socket.on('join', (userId) => {
      socket.join(userId);
      console.log(`User ${userId} joined their room`);
    });

    // Update driver location in real-time
    socket.on('updateLocation', async (data) => {
      const { driverId, lat, lng } = data;
      try {
        const driver = await Driver.findOneAndUpdate(
          { user: driverId },
          { currentLocation: { coordinates: [lng, lat] } },
          { new: true }
        );
        
        if (driver) {
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
      nearbyDrivers.forEach((driver) => {
        io.to(driver.user.toString()).emit('newRideRequest', rideData);
      });
    });

    // Driver accepts ride
    socket.on('acceptRide', async (data) => {
      const { rideId, driverId } = data;
      try {
        const driver = await Driver.findOne({ user: driverId });
        
        if (!driver) {
          console.error('Driver not found for user:', driverId);
          return;
        }
        
        const ride = await Ride.findByIdAndUpdate(
          rideId,
          { driver: driver._id, status: 'accepted' },
          { new: true }
        ).populate('user driver');
        
        if (!ride) {
          console.error('Ride not found:', rideId);
          return;
        }
        
        // Notify user that ride is accepted
        io.to(ride.user._id.toString()).emit('rideAccepted', ride);
      } catch (error) {
        console.error('Socket accept ride error:', error);
      }
    });

    // Driver rejects ride
    socket.on('rejectRide', async (data) => {
      const { rideId, driverId } = data;
      try {
        const ride = await Ride.findByIdAndUpdate(
          rideId,
          { status: 'cancelled',
            cancellationReason: 'Rejected by driver' },
          { new: true }
        ).populate('user');
        
        if (!ride) {
          console.log('Ride rejected:', rideId);
          // Notify user
          io.to(ride.user._id.toString()).emit('rideCancelled', ride);
        }
      } catch (error) {
        console.error('Socket reject ride error:', error);
      }
    });

    // Ride status updates
    socket.on('updateRideStatus', async (data) => {
      const { rideId, status, userId } = data;
      io.to(userId).emit('rideStatusUpdate', { rideId, status });
    });

    socket.on('disconnect', () => {
      console.log('Client disconnected');
    });
  });

  return io;
};

module.exports = initSocket;
