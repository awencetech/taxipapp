const express = require('express');
const router = express.Router();
const { autocomplete, placeDetails, distance, directions, reverseGeocode } = require('../controllers/mapsController');

// Make maps API public so they work before logging in
router.get('/autocomplete', autocomplete);
router.get('/place-details', placeDetails);
router.get('/distance', distance);
router.get('/directions', directions);
router.get('/reverse-geocode', reverseGeocode);

module.exports = router;
