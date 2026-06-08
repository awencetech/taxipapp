import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class GoogleMapsService {
  final String baseUrl = ApiService.baseUrl;

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<List<dynamic>> getAutocomplete(
      String input, String sessionToken) async {
    if (input.isEmpty) return [];

    final String url =
        '${baseUrl.replaceAll('/api/v1', '')}/api/v1/maps/autocomplete?input=$input&sessionToken=$sessionToken';

    try {
      developer.log('Fetching autocomplete via proxy for: $input');
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          return data['predictions'];
        } else if (data['status'] == 'ZERO_RESULTS') {
          return [];
        } else {
          developer.log(
              'Proxy Places API Error: ${data['status']} - ${data['error_message']}');
          throw Exception(
              data['error_message'] ?? 'Places API Error: ${data['status']}');
        }
      } else {
        developer.log('Proxy HTTP Error: ${response.statusCode}');
        throw Exception(
            'Failed to connect to Maps Proxy (${response.statusCode})');
      }
    } catch (e) {
      developer.log('Proxy Autocomplete Exception: $e');
      rethrow;
    }
  }

  Future<LatLng> getPlaceDetails(String placeId) async {
    final String url =
        '${baseUrl.replaceAll('/api/v1', '')}/api/v1/maps/place-details?placeId=$placeId';

    try {
      developer.log('Fetching details via proxy for placeId: $placeId');
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final location = data['result']['geometry']['location'];
          return LatLng(location['lat'], location['lng']);
        } else {
          developer.log(
              'Proxy Place Details API Error: ${data['status']} - ${data['error_message']}');
          throw Exception(data['error_message'] ??
              'Place Details API Error: ${data['status']}');
        }
      } else {
        developer.log('Proxy HTTP Error: ${response.statusCode}');
        throw Exception(
            'Failed to connect to Maps Proxy (${response.statusCode})');
      }
    } catch (e) {
      developer.log('Proxy Place Details Exception: $e');
      rethrow;
    }
  }
}
