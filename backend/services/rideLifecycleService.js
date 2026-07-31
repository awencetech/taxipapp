const RIDE_LIFECYCLE_TRANSITIONS = {
  searching: ['accepted', 'cancelled'],
  accepted: ['driver_arriving', 'arrived', 'cancelled'],
  driver_arriving: ['arrived', 'cancelled'],
  arrived: ['trip_started', 'cancelled'],
  trip_started: ['completed', 'cancelled'],
  completed: [],
  cancelled: [],
};

const RIDE_STATUS_TIMESTAMPS = {
  searching: null,
  accepted: 'acceptedTime',
  driver_arriving: 'arrivedTime',
  arrived: 'arrivedTime',
  trip_started: 'startedTime',
  completed: 'completedTime',
  cancelled: 'cancelledTime',
};

const getAllowedTransitions = (status) => RIDE_LIFECYCLE_TRANSITIONS[status] || [];

const transitionRideStatus = (currentStatus, nextStatus) => {
  const allowedTransitions = getAllowedTransitions(currentStatus);

  if (!allowedTransitions.includes(nextStatus)) {
    return {
      valid: false,
      reason: `Invalid status transition from ${currentStatus} to ${nextStatus}`,
    };
  }

  return {
    valid: true,
    nextStatus,
    timestampField: RIDE_STATUS_TIMESTAMPS[nextStatus],
  };
};

const applyRideStatusTransition = (ride, nextStatus) => {
  const transition = transitionRideStatus(ride.status, nextStatus);

  if (!transition.valid) {
    return transition;
  }

  const timestamp = new Date();
  ride.status = transition.nextStatus;

  if (transition.timestampField) {
    ride[transition.timestampField] = timestamp;
  }

  if (nextStatus === 'accepted') {
    ride.acceptedTime = timestamp;
  }

  if (nextStatus === 'arrived') {
    ride.arrivedTime = timestamp;
  }

  if (nextStatus === 'trip_started') {
    ride.startedTime = timestamp;
    ride.startTime = timestamp;
  }

  if (nextStatus === 'completed') {
    ride.completedTime = timestamp;
    ride.endTime = timestamp;
  }

  if (nextStatus === 'cancelled') {
    ride.cancelledTime = timestamp;
  }

  return transition;
};

module.exports = {
  getAllowedTransitions,
  transitionRideStatus,
  applyRideStatusTransition,
};
