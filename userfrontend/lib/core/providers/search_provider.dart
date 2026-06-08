import 'package:flutter/foundation.dart';
import 'dart:async';
import '../models/place_prediction_model.dart';
import '../models/place_details_model.dart';
import '../services/google_places_service.dart';

enum SearchStatus {
  initial,
  loading,
  success,
  error,
  noResults,
  noInternet,
}

class SearchProvider with ChangeNotifier {
  final GooglePlacesService _placesService = GooglePlacesService();

  SearchStatus _status = SearchStatus.initial;
  String _errorMessage = '';
  List<PlacePrediction> _predictions = [];
  List<PlacePrediction> _recentSearches = [];
  Timer? _debounceTimer;
  String _searchQuery = '';

  SearchStatus get status => _status;
  String get errorMessage => _errorMessage;
  List<PlacePrediction> get predictions => _predictions;
  List<PlacePrediction> get recentSearches => _recentSearches;
  String get searchQuery => _searchQuery;

  SearchProvider() {
    _loadRecentSearches();
  }

  Future<void> _loadRecentSearches() async {
    try {
      _recentSearches = await _placesService.getRecentSearches();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading recent searches: $e');
    }
  }

  void onSearchChanged(String query) {
    _searchQuery = query;

    if (_debounceTimer?.isActive ?? false) {
      _debounceTimer!.cancel();
    }

    if (query.length < 2) {
      _predictions = [];
      _status = SearchStatus.initial;
      notifyListeners();
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _searchPlaces(query);
    });
  }

  Future<void> _searchPlaces(String query) async {
    _status = SearchStatus.loading;
    notifyListeners();

    try {
      final results = await _placesService.getPlacePredictions(query);

      if (results.isEmpty) {
        _status = SearchStatus.noResults;
      } else {
        _predictions = results;
        _status = SearchStatus.success;
      }
    } catch (e) {
      _errorMessage = e.toString();
      if (e.toString().contains('DioExceptionType.connectionError')) {
        _status = SearchStatus.noInternet;
      } else {
        _status = SearchStatus.error;
      }
      debugPrint('Search error: $e');
    }

    notifyListeners();
  }

  Future<PlaceDetails> selectPlace(PlacePrediction place) async {
    final details = await _placesService.getPlaceDetails(place.placeId);
    await _placesService.addToRecentSearches(place);
    await _loadRecentSearches();
    return details;
  }

  void clearSearch() {
    _searchQuery = '';
    _predictions = [];
    _status = SearchStatus.initial;
    notifyListeners();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}