const {
  getAllowedTransitions,
  transitionRideStatus,
} = require('../services/rideLifecycleService');

describe('ride lifecycle state machine', () => {
  it('should allow the accepted path from searching to arrived to trip_started to completed', () => {
    expect(getAllowedTransitions('searching')).toEqual(expect.arrayContaining(['accepted']));
    expect(getAllowedTransitions('accepted')).toEqual(expect.arrayContaining(['driver_arriving', 'cancelled']));
    expect(getAllowedTransitions('driver_arriving')).toEqual(expect.arrayContaining(['arrived']));
    expect(getAllowedTransitions('arrived')).toEqual(expect.arrayContaining(['trip_started']));
    expect(getAllowedTransitions('trip_started')).toEqual(expect.arrayContaining(['completed']));
  });

  it('should return the lifecycle timestamp field for a valid transition', () => {
    expect(transitionRideStatus('searching', 'accepted')).toEqual({
      nextStatus: 'accepted',
      timestampField: 'acceptedTime',
      valid: true,
    });

    expect(transitionRideStatus('accepted', 'driver_arriving')).toEqual({
      nextStatus: 'driver_arriving',
      timestampField: 'arrivedTime',
      valid: true,
    });
  });

  it('should reject invalid ride state transitions', () => {
    expect(transitionRideStatus('completed', 'trip_started')).toEqual({
      valid: false,
      reason: 'Invalid status transition from completed to trip_started',
    });
  });
});
