const { getAutocompleteSuggestions, getPlaceDetails, getDistanceMatrix, getDirections, getAddressFromCoords } = require('../services/mapsService');

const autocomplete = async (req, res) => {
  try {
    const { input, sessionToken } = req.query;
    if (!input) {
      return res.status(400).json({ success: false, message: 'Input is required' });
    }

    const data = await getAutocompleteSuggestions(input, sessionToken);
    res.status(200).json(data);
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

const placeDetails = async (req, res) => {
  try {
    const { placeId } = req.query;
    if (!placeId) {
      return res.status(400).json({ success: false, message: 'placeId is required' });
    }

    const data = await getPlaceDetails(placeId);
    res.status(200).json(data);
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

const distance = async (req, res) => {
  try {
    const { originLat, originLng, destLat, destLng } = req.query;
    if (!originLat || !originLng || !destLat || !destLng) {
      return res.status(400).json({ success: false, message: 'Origin and destination coordinates are required' });
    }

    const data = await getDistanceMatrix(
      { lat: parseFloat(originLat), lng: parseFloat(originLng) },
      { lat: parseFloat(destLat), lng: parseFloat(destLng) }
    );
    res.status(200).json(data);
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

const directions = async (req, res) => {
  try {
    const { originLat, originLng, destLat, destLng } = req.query;
    if (!originLat || !originLng || !destLat || !destLng) {
      return res.status(400).json({ success: false, message: 'Origin and destination coordinates are required' });
    }

    const data = await getDirections(
      { lat: parseFloat(originLat), lng: parseFloat(originLng) },
      { lat: parseFloat(destLat), lng: parseFloat(destLng) }
    );
    res.status(200).json(data);
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

const reverseGeocode = async (req, res) => {
  try {
    const { lat, lng } = req.query;
    if (!lat || !lng) {
      return res.status(400).json({ success: false, message: 'Latitude and longitude are required' });
    }

    const address = await getAddressFromCoords(parseFloat(lat), parseFloat(lng));
    res.status(200).json({ success: true, address });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

module.exports = { autocomplete, placeDetails, distance, directions, reverseGeocode };
