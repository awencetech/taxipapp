const Driver = require('../models/Driver');

const findNearbyDrivers = async (lat, lng, radiusInKm = 5) => {
  const drivers = await Driver.find({
    isOnline: true,
    status: 'available',
    currentLocation: {
      $near: {
        $geometry: {
          type: 'Point',
          coordinates: [lng, lat],
        },
        $maxDistance: radiusInKm * 1000, // convert to meters
      },
    },
  }).populate('user').populate('vehicle');

  return drivers;
};

const calculateFare = (distanceInKm, vehicleType) => {
  const baseFare = {
    mini: 50,
    sedan: 80,
    suv: 120,
    bike: 30,
  };

  const perKmRate = {
    mini: 12,
    sedan: 15,
    suv: 20,
    bike: 8,
  };

  const fare = baseFare[vehicleType] + (distanceInKm * perKmRate[vehicleType]);
  return Math.round(fare);
};

module.exports = { findNearbyDrivers, calculateFare };
