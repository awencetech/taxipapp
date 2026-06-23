import 'dart:async';
import 'dart:developer';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/place_prediction_model.dart';
import '../models/place_details_model.dart';
import 'api_service.dart';

class GooglePlacesService {
  final ApiService _apiService = ApiService();
  final String _sessionToken = DateTime.now().millisecondsSinceEpoch.toString();

  GooglePlacesService();

  Future<List<PlacePrediction>> getPlacePredictions(
    String input,
  ) async {
    try {
      log('Calling Backend Maps Autocomplete API for: $input',
          name: 'GooglePlacesService');

      final response = await _apiService.dio.get(
        '/maps/autocomplete',
        queryParameters: {
          'input': input,
          'sessionToken': _sessionToken,
        },
      );

      log('Backend Maps API Response Status: ${response.statusCode}',
          name: 'GooglePlacesService');
      log('Backend Maps API Response Data: ${response.data}',
          name: 'GooglePlacesService');

      if (response.statusCode == 200) {
        // Check if there are any API errors
        if (response.data['status'] != 'OK') {
          throw Exception(
              'Google Places API Error: ${response.data['status']}');
        }

        final List predictions = response.data['predictions'];
        log('Number of predictions found: ${predictions.length}',
            name: 'GooglePlacesService');

        return predictions
            .map((json) => PlacePrediction.fromJson(json))
            .toList();
      } else {
        throw Exception('Failed to fetch predictions');
      }
    } catch (e) {
      log('Error in getPlacePredictions: $e', name: 'GooglePlacesService');
      rethrow;
    }
  }

  Future<PlaceDetails> getPlaceDetails(String placeId) async {
    try {
      final response = await _apiService.dio.get(
        '/maps/place-details',
        queryParameters: {
          'placeId': placeId,
        },
      );

      if (response.statusCode == 200) {
        return PlaceDetails.fromJson(response.data);
      } else {
        throw Exception('Failed to fetch place details');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<PlacePrediction>> getRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? recent = prefs.getStringList('recent_searches');

    if (recent == null) return [];

    return recent.map((item) {
      final parts = item.split('|');
      return PlacePrediction(
        placeId: parts[0],
        mainText: parts[1],
        secondaryText: parts.length > 2 ? parts[2] : '',
        description: parts.length > 3 ? parts[3] : '',
      );
    }).toList();
  }

  Future<void> addToRecentSearches(PlacePrediction place) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> recent = prefs.getStringList('recent_searches') ?? [];

    final String searchString =
        '${place.placeId}|${place.mainText}|${place.secondaryText}|${place.description}';
    recent.removeWhere((item) => item.startsWith('${place.placeId}|'));
    recent.insert(0, searchString);

    if (recent.length > 10) {
      recent = recent.sublist(0, 10);
    }

    await prefs.setStringList('recent_searches', recent);
  }
}
