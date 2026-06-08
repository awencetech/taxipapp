const express = require('express');
const router = express.Router();
const { autocomplete, placeDetails } = require('../controllers/mapsController');

// Make maps API public so they work before logging in
router.get('/autocomplete', autocomplete);
router.get('/place-details', placeDetails);

module.exports = router;
