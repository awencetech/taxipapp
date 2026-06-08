const { getAutocompleteSuggestions, getPlaceDetails } = require('../services/mapsService');

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

module.exports = { autocomplete, placeDetails };
