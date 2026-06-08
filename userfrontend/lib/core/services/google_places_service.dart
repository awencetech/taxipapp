import 'dart:async';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/place_prediction_model.dart';
import '../models/place_details_model.dart';

class GooglePlacesService {
  static const String _apiKey = 'AIzaSyAZ0IMMHkEXG6PfafxQpkp38O3AgBRKZRg';
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api';
  final Dio _dio = Dio();

  GooglePlacesService() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          return handler.next(options);
        },
      ),
    );
  }

  Future<List<PlacePrediction>> getPlacePredictions(
    String input,
  ) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/place/autocomplete/json',
        queryParameters: {
          'input': input,
          'key': _apiKey,
          'types': '(cities)',
        },
      );

      if (response.statusCode == 200) {
        final List predictions = response.data['predictions'];
        return predictions
            .map((json) => PlacePrediction.fromJson(json))
            .toList();
      } else {
        throw Exception('Failed to fetch predictions');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<PlaceDetails> getPlaceDetails(String placeId) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/place/details/json',
        queryParameters: {
          'place_id': placeId,
          'key': _apiKey,
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
