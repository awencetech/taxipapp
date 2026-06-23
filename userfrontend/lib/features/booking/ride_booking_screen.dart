import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/location_provider.dart';
import '../../core/providers/booking_provider.dart';
import '../../core/models/place_prediction_model.dart';
import '../../core/models/place_details_model.dart';
import '../../core/models/ride_type.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/api_service.dart';
import 'booking_confirmation_screen.dart';

class RideBookingScreen extends StatefulWidget {
  final Function(Map<String, dynamic>)? onBookingConfirmed;

  const RideBookingScreen({super.key, this.onBookingConfirmed});

  @override
  State<RideBookingScreen> createState() => _RideBookingScreenState();
}

class _RideBookingScreenState extends State<RideBookingScreen> {
  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _dropController = TextEditingController();
  final ApiService _apiService = ApiService();
  final FocusNode _pickupFocusNode = FocusNode();
  final FocusNode _dropFocusNode = FocusNode();

  PlaceDetails? _pickupLocation;
  PlaceDetails? _dropLocation;
  String? _distance;
  String? _duration;
  double? _distanceKm;
  int? _selectedVehicleIndex = 0;

  bool _isCalculating = false;
  List<PlacePrediction> _pickupSuggestions = [];
  List<PlacePrediction> _dropSuggestions = [];
  Timer? _debounceTimer;
  final String _sessionToken = DateTime.now().millisecondsSinceEpoch.toString();

  @override
  void initState() {
    super.initState();
    _getCurrentLocationAsPickup();
  }

  @override
  void dispose() {
    _pickupController.dispose();
    _dropController.dispose();
    _pickupFocusNode.dispose();
    _dropFocusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _getCurrentLocationAsPickup() async {
    final locationProvider = context.read<LocationProvider>();
    await locationProvider.getCurrentLocation();

    if (locationProvider.currentPosition != null) {
      setState(() {
        _pickupLocation = PlaceDetails(
          placeId: 'current_location',
          name: 'Current Location',
          address: 'Your current location',
          latitude: locationProvider.currentPosition!.latitude,
          longitude: locationProvider.currentPosition!.longitude,
        );
        _pickupController.text = 'Current Location';
      });
    }
  }

  void _onPickupTap() {}
  void _onDropTap() {}

  void _onPickupSearchChanged(String query) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    if (query.length < 2) {
      setState(() {
        _pickupSuggestions = [];
      });
      return;
    }
    _debounceTimer =
        Timer(const Duration(milliseconds: 500), () => _searchPickup(query));
  }

  void _onDropSearchChanged(String query) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    if (query.length < 2) {
      setState(() {
        _dropSuggestions = [];
      });
      return;
    }
    _debounceTimer =
        Timer(const Duration(milliseconds: 500), () => _searchDrop(query));
  }

  Future<void> _searchPickup(String query) async {
    try {
      final response = await _apiService.dio.get(
        '/maps/autocomplete',
        queryParameters: {'input': query, 'sessionToken': _sessionToken},
      );
      if (response.data['status'] == 'OK') {
        final List predictions = response.data['predictions'];
        setState(() {
          _pickupSuggestions = predictions
              .map((json) => PlacePrediction.fromJson(json))
              .toList();
        });
      } else {
        setState(() {
          _pickupSuggestions = [];
        });
      }
    } catch (e) {
      setState(() {
        _pickupSuggestions = [];
      });
    }
  }

  Future<void> _searchDrop(String query) async {
    try {
      final response = await _apiService.dio.get(
        '/maps/autocomplete',
        queryParameters: {'input': query, 'sessionToken': _sessionToken},
      );
      if (response.data['status'] == 'OK') {
        final List predictions = response.data['predictions'];
        setState(() {
          _dropSuggestions = predictions
              .map((json) => PlacePrediction.fromJson(json))
              .toList();
        });
      } else {
        setState(() {
          _dropSuggestions = [];
        });
      }
    } catch (e) {
      setState(() {
        _dropSuggestions = [];
      });
    }
  }

  Future<void> _selectPickupPrediction(PlacePrediction prediction) async {
    try {
      setState(() {
        _pickupSuggestions = [];
        _pickupController.text = prediction.mainText;
      });

      final response = await _apiService.dio.get(
        '/maps/place-details',
        queryParameters: {'placeId': prediction.placeId},
      );

      if (response.data['status'] == 'OK') {
        final result = response.data['result'];
        final geometry = result['geometry'];
        final location = geometry['location'];
        setState(() {
          _pickupLocation = PlaceDetails(
            placeId: prediction.placeId,
            name: prediction.mainText,
            address: prediction.description,
            latitude: location['lat'],
            longitude: location['lng'],
          );
        });

        if (_dropLocation != null) {
          await _calculateDistanceAndTime();
        }
      }
    } catch (e) {
      // Ignore errors for location selection
    }
  }

  Future<void> _selectDropPrediction(PlacePrediction prediction) async {
    try {
      setState(() {
        _dropSuggestions = [];
        _dropController.text = prediction.mainText;
      });

      final response = await _apiService.dio.get(
        '/maps/place-details',
        queryParameters: {'placeId': prediction.placeId},
      );

      if (response.data['status'] == 'OK') {
        final result = response.data['result'];
        final geometry = result['geometry'];
        final location = geometry['location'];
        setState(() {
          _dropLocation = PlaceDetails(
            placeId: prediction.placeId,
            name: prediction.mainText,
            address: prediction.description,
            latitude: location['lat'],
            longitude: location['lng'],
          );
        });

        if (_pickupLocation != null) {
          await _calculateDistanceAndTime();
        }
      }
    } catch (e) {
      // Ignore errors for location selection
    }
  }

  Future<void> _calculateDistanceAndTime() async {
    if (_pickupLocation == null || _dropLocation == null) return;

    setState(() {
      _isCalculating = true;
    });

    try {
      final response = await _apiService.dio.get(
        '/maps/distance',
        queryParameters: {
          'originLat': _pickupLocation!.latitude,
          'originLng': _pickupLocation!.longitude,
          'destLat': _dropLocation!.latitude,
          'destLng': _dropLocation!.longitude,
        },
      );

      setState(() {
        _distance = response.data['distance'];
        _duration = response.data['duration'];
        _distanceKm = response.data['distanceValue'];
        _isCalculating = false;
      });
    } catch (e) {
      // Fallback to dummy calculation
      final lat1 = _pickupLocation!.latitude;
      final lng1 = _pickupLocation!.longitude;
      final lat2 = _dropLocation!.latitude;
      final lng2 = _dropLocation!.longitude;

      final distance = _calculateHaversine(lat1, lng1, lat2, lng2);
      setState(() {
        _distance = '${distance.toStringAsFixed(1)} km';
        _duration = '${(distance * 3).round()} min';
        _distanceKm = distance;
        _isCalculating = false;
      });
    }
  }

  double _calculateHaversine(
      double lat1, double lng1, double lat2, double lng2) {
    const R = 6371.0; // Earth radius in km
    final dLat = (lat2 - lat1) * (pi / 180.0);
    final dLng = (lng2 - lng1) * (pi / 180.0);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * (pi / 180.0)) *
            cos(lat2 * (pi / 180.0)) *
            sin(dLng / 2) *
            sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  int _calculateDurationMinutes(String? durationStr) {
    if (durationStr == null || durationStr.isEmpty) return 10;
    // Try to extract number from string like "15 min"
    final match = RegExp(r'(\d+)').firstMatch(durationStr);
    if (match != null) {
      return int.parse(match.group(1)!);
    }
    return 10;
  }

  void _swapLocations() {
    setState(() {
      final tempLocation = _pickupLocation;
      _pickupLocation = _dropLocation;
      _dropLocation = tempLocation;

      final tempText = _pickupController.text;
      _pickupController.text = _dropController.text;
      _dropController.text = tempText;

      if (_pickupLocation != null && _dropLocation != null) {
        _calculateDistanceAndTime();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final rideTypes = _distanceKm != null
        ? RideType.getDummyRides(_distanceKm!)
        : RideType.getDummyRides(5.0);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Book a Ride'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Location Selection Card
            Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Pickup Location
                  _LocationField(
                    controller: _pickupController,
                    focusNode: _pickupFocusNode,
                    icon: Icons.my_location,
                    iconColor: AppColors.secondary,
                    hint: 'Pickup Location',
                    onChanged: _onPickupSearchChanged,
                    onTap: _onPickupTap,
                  ),

                  if (_pickupSuggestions.isNotEmpty)
                    _SuggestionsList(
                      suggestions: _pickupSuggestions,
                      onSelected: _selectPickupPrediction,
                    ),

                  const SizedBox(height: 12),

                  // Swap Button
                  Row(
                    children: [
                      const SizedBox(width: 20),
                      GestureDetector(
                        onTap: _swapLocations,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                            color: AppColors.grey100,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.swap_vert,
                              size: 20, color: AppColors.grey600),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Drop Location
                  _LocationField(
                    controller: _dropController,
                    focusNode: _dropFocusNode,
                    icon: Icons.location_pin,
                    iconColor: Colors.red,
                    hint: 'Drop Location',
                    onChanged: _onDropSearchChanged,
                    onTap: _onDropTap,
                  ),

                  if (_dropSuggestions.isNotEmpty)
                    _SuggestionsList(
                      suggestions: _dropSuggestions,
                      onSelected: _selectDropPrediction,
                    ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Distance & Time
            if (_distance != null && _duration != null)
              Container(
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: AppColors.secondary.withValues(alpha: 0.3)),
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.route,
                        color: AppColors.secondary, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Trip Details',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.secondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$_distance • $_duration',
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.grey600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_isCalculating) const CircularProgressIndicator(),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // Vehicle Selection
            const Text(
              'Select Vehicle',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.black,
              ),
            ),

            const SizedBox(height: 16),

            ...List.generate(
              rideTypes.length,
              (index) {
                final ride = rideTypes[index];
                final isSelected = _selectedVehicleIndex == index;
                return _VehicleCard(
                  ride: ride,
                  isSelected: isSelected,
                  onTap: () {
                    setState(() {
                      _selectedVehicleIndex = index;
                      context.read<BookingProvider>().selectRideType(ride);
                    });
                  },
                );
              },
            ),

            const SizedBox(height: 32),

            // Book Button
            ElevatedButton(
              onPressed: _pickupLocation != null && _dropLocation != null
                  ? () {
                      final rideTypes = _distanceKm != null
                          ? RideType.getDummyRides(_distanceKm!)
                          : RideType.getDummyRides(5.0);
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => BookingConfirmationScreen(
                          pickupAddress: _pickupLocation?.address ?? '',
                          dropAddress: _dropLocation?.address ?? '',
                          distance: _distance ?? '',
                          duration: _duration ?? '',
                          distanceKm: _distanceKm ?? 0.0,
                          durationMinutes: _calculateDurationMinutes(_duration),
                          selectedRide: rideTypes[_selectedVehicleIndex!],
                          pickupLocation: {
                            'latitude': _pickupLocation!.latitude,
                            'longitude': _pickupLocation!.longitude,
                          },
                          dropLocation: {
                            'latitude': _dropLocation!.latitude,
                            'longitude': _dropLocation!.longitude,
                          },
                          onBookingConfirmed: widget.onBookingConfirmed,
                        ),
                      );
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: AppColors.secondary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Book Now',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final IconData icon;
  final Color iconColor;
  final String hint;
  final Function(String) onChanged;
  final VoidCallback onTap;

  const _LocationField({
    required this.controller,
    required this.focusNode,
    required this.icon,
    required this.iconColor,
    required this.hint,
    required this.onChanged,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              onTap: onTap,
              onChanged: onChanged,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.black,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(
                  fontSize: 16,
                  color: AppColors.grey600,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestionsList extends StatelessWidget {
  final List<PlacePrediction> suggestions;
  final Function(PlacePrediction) onSelected;

  const _SuggestionsList({
    required this.suggestions,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      constraints: const BoxConstraints(maxHeight: 250),
      child: ListView.builder(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: suggestions.length,
        itemBuilder: (context, index) {
          final prediction = suggestions[index];
          return ListTile(
            leading: const Icon(Icons.location_on, color: AppColors.grey600),
            title: Text(
              prediction.mainText,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              prediction.secondaryText,
              style: const TextStyle(color: AppColors.grey600),
            ),
            onTap: () => onSelected(prediction),
          );
        },
      ),
    );
  }
}

class _VehicleCard extends StatelessWidget {
  final RideType ride;
  final bool isSelected;
  final VoidCallback onTap;

  const _VehicleCard({
    required this.ride,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.secondary.withValues(alpha: 0.08)
              : AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.secondary : AppColors.grey200,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.secondary.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            // Vehicle Icon with Image Placeholder
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: ride.iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  'https://picsum.photos/seed/${ride.id}/200/200',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      ride.icon,
                      size: 36,
                      color: ride.iconColor,
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ride.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ride.description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.grey600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.people,
                          size: 16, color: AppColors.grey400),
                      const SizedBox(width: 4),
                      Text(
                        '${ride.maxPassengers} passengers',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.grey400,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Icon(Icons.timer,
                          size: 16, color: AppColors.grey400),
                      const SizedBox(width: 4),
                      Text(
                        '${ride.estimatedTime} min',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.grey400,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Price
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹${ride.estimatedPrice}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.black,
                  ),
                ),
                if (isSelected)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Selected',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
