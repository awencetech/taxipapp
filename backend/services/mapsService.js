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
  const url = `https://maps.googleapis.com/maps/api/place/autocomplete/json?input=${input}&key=${apiKey}&sessiontoken=${sessionToken}`;

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
  const url = `https://maps.googleapis.com/maps/api/place/details/json?place_id=${placeId}&fields=geometry&key=${apiKey}`;

  try {
    const response = await axios.get(url);
    return response.data;
  } catch (error) {
    console.error('Place Details API Error:', error.message);
    throw error;
  }
};

module.exports = { getDistanceMatrix, getAddressFromCoords, getAutocompleteSuggestions, getPlaceDetails };
