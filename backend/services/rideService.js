const Driver = require('../models/Driver');

const findNearbyDrivers = async (lat, lng, radiusInKm = 5, vendorId = null) => {
  const query = {
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
          coordinates: [lng, lat],
        },
        $maxDistance: radiusInKm * 1000, // convert to meters
      },
    },
  };

  if (vendorId) {
    query.vendor = vendorId;
  }

  const drivers = await Driver.find(query).populate('user').populate('vehicle');

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
