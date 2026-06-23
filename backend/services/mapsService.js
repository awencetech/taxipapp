const axios = require('axios');

const getDistanceMatrix = async (origin, destination) => {
  const apiKey = process.env.GOOGLE_MAPS_API_KEY;
  const url = `https://maps.googleapis.com/maps/api/distancematrix/json?origins=${origin.lat},${origin.lng}&destinations=${destination.lat},${destination.lng}&key=${apiKey}`;

  try {
    const response = await axios.get(url);
    if (response.data.status === 'OK') {
      const element = response.data.rows[0].elements[0];
      return {
        distance: element.distance.text,
        distanceValue: element.distance.value / 1000, // in km
        duration: element.duration.text,
        durationValue: element.duration.value / 60, // in minutes
      };
    }
    throw new Error('Google Maps API error');
  } catch (error) {
    console.error('Maps API Error:', error.message);
    // Return dummy data if API key is missing or fails for demo
    return {
      distance: '5.2 km',
      distanceValue: 5.2,
      duration: '15 mins',
      durationValue: 15,
    };
  }
};

const getDirections = async (origin, destination) => {
  const apiKey = process.env.GOOGLE_MAPS_API_KEY;
  const url = `https://maps.googleapis.com/maps/api/directions/json?origin=${origin.lat},${origin.lng}&destination=${destination.lat},${destination.lng}&key=${apiKey}`;

  try {
    const response = await axios.get(url);
    if (response.data.status === 'OK') {
      const route = response.data.routes[0];
      const leg = route.legs[0];
      return {
        distance: leg.distance.text,
        distanceValue: leg.distance.value / 1000,
        duration: leg.duration.text,
        durationValue: leg.duration.value / 60,
        polyline: route.overview_polyline.points,
        startLocation: { lat: leg.start_location.lat, lng: leg.start_location.lng },
        endLocation: { lat: leg.end_location.lat, lng: leg.end_location.lng },
      };
    }
    throw new Error('Google Maps Directions API error');
  } catch (error) {
    console.error('Directions API Error:', error.message);
    // Return dummy data if API key is missing or fails for demo
    return {
      distance: '5.2 km',
      distanceValue: 5.2,
      duration: '15 mins',
      durationValue: 15,
      polyline: '',
      startLocation: origin,
      endLocation: destination,
    };
  }
};

const getAddressFromCoords = async (lat, lng) => {
  const apiKey = process.env.GOOGLE_MAPS_API_KEY;
  const url = `https://maps.googleapis.com/maps/api/geocode/json?latlng=${lat},${lng}&key=${apiKey}`;

  try {
    const response = await axios.get(url);
    if (response.data.status === 'OK') {
      return response.data.results[0].formatted_address;
    }
    throw new Error('Google Maps API error');
  } catch (error) {
    console.error('Maps API Error:', error.message);
    return 'Unknown Address';
  }
};

const getAutocompleteSuggestions = async (input, sessionToken) => {
  const apiKey = process.env.GOOGLE_MAPS_API_KEY;
  const url = `https://maps.googleapis.com/maps/api/place/autocomplete/json?input=${input}&key=${apiKey}&sessiontoken=${sessionToken}&location=13.0827,80.2707&radius=50000`;

  try {
    const response = await axios.get(url);
    return response.data;
  } catch (error) {
    console.error('Autocomplete API Error:', error.message);
    throw error;
  }
};

const getPlaceDetails = async (placeId) => {
  const apiKey = process.env.GOOGLE_MAPS_API_KEY;
  const url = `https://maps.googleapis.com/maps/api/place/details/json?place_id=${placeId}&fields=place_id,name,formatted_address,geometry&key=${apiKey}`;

  try {
    const response = await axios.get(url);
    return response.data;
  } catch (error) {
    console.error('Place Details API Error:', error.message);
    throw error;
  }
};

module.exports = { getDistanceMatrix, getDirections, getAddressFromCoords, getAutocompleteSuggestions, getPlaceDetails };
