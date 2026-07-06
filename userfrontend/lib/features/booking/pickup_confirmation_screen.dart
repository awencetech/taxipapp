import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/booking_provider.dart';
import '../../core/providers/location_provider.dart';
import '../../core/models/place_details_model.dart';
import 'searching_driver_screen.dart';

class PickupConfirmationScreen extends StatefulWidget {
  final BookingProvider bookingProvider;
  final String selectedPaymentMethod;
  final String? appliedCoupon;
  final double calculatedFare;

  const PickupConfirmationScreen({
    super.key,
    required this.bookingProvider,
    required this.selectedPaymentMethod,
    required this.appliedCoupon,
    required this.calculatedFare,
  });

  @override
  State<PickupConfirmationScreen> createState() =>
      _PickupConfirmationScreenState();
}

class _PickupConfirmationScreenState extends State<PickupConfirmationScreen> {
  final Completer<GoogleMapController> _mapController = Completer();
  LatLng? _selectedPickupLocation;
  PlaceDetails? _updatedPickupDetails;
  final Set<Marker> _markers = {};
  bool _isFetchingLocation = false;
  bool _isFetchingAddress = false;

  @override
  void initState() {
    super.initState();
    if (widget.bookingProvider.pickupLocation != null) {
      _selectedPickupLocation = LatLng(
        widget.bookingProvider.pickupLocation!.latitude,
        widget.bookingProvider.pickupLocation!.longitude,
      );
      _updatedPickupDetails = widget.bookingProvider.pickupLocation;
      _addMarker();
    } else {
      _fetchCurrentLocation();
    }
  }

  void _addMarker() {
    if (_selectedPickupLocation != null) {
      setState(() {
        _markers.clear();
        _markers.add(
          Marker(
            markerId: const MarkerId('pickup'),
            position: _selectedPickupLocation!,
            anchor: const Offset(0.5, 1.0), // Anchor at bottom center of marker
            icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueGreen),
          ),
        );
      });
    }
  }

  Future<void> _fetchCurrentLocation() async {
    if (_isFetchingLocation) return;

    setState(() {
      _isFetchingLocation = true;
    });

    final locationProvider = context.read<LocationProvider>();
    final position = await locationProvider.getCurrentLocation();

    if (position != null && mounted) {
      setState(() {
        _selectedPickupLocation = LatLng(
          position.latitude,
          position.longitude,
        );
        _addMarker();
      });

      final controller = await _mapController.future;
      await controller.animateCamera(
        CameraUpdate.newLatLngZoom(_selectedPickupLocation!, 16),
      );

      setState(() {
        _isFetchingAddress = true;
      });

      final address = await locationProvider.getAddressFromLatLng(
        _selectedPickupLocation!.latitude,
        _selectedPickupLocation!.longitude,
      );

      if (mounted) {
        setState(() {
          _updatedPickupDetails = PlaceDetails(
            placeId: '',
            name: address,
            address: address,
            latitude: _selectedPickupLocation!.latitude,
            longitude: _selectedPickupLocation!.longitude,
          );
          _isFetchingAddress = false;
        });
      }
    }

    if (mounted) {
      setState(() {
        _isFetchingLocation = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Google Map
          Positioned.fill(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target:
                    _selectedPickupLocation ?? const LatLng(11.0168, 76.9558),
                zoom: 16,
              ),
              mapType: MapType.satellite,
              markers: _markers,
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
              zoomGesturesEnabled: true,
              scrollGesturesEnabled: true,
              rotateGesturesEnabled: false,
              tiltGesturesEnabled: false,
              onMapCreated: (controller) {
                _mapController.complete(controller);
                if (_selectedPickupLocation != null) {
                  controller.animateCamera(
                    CameraUpdate.newLatLngZoom(_selectedPickupLocation!, 16),
                  );
                }
              },
              onCameraMove: (position) {
                setState(() {
                  _selectedPickupLocation = position.target;
                });
              },
              onCameraIdle: () async {
                if (_selectedPickupLocation != null) {
                  _addMarker();
                  setState(() {
                    _isFetchingAddress = true;
                  });
                  final locationProvider = context.read<LocationProvider>();
                  final address = await locationProvider.getAddressFromLatLng(
                    _selectedPickupLocation!.latitude,
                    _selectedPickupLocation!.longitude,
                  );
                  if (mounted) {
                    setState(() {
                      _updatedPickupDetails = PlaceDetails(
                        placeId: '',
                        name: address,
                        address: address,
                        latitude: _selectedPickupLocation!.latitude,
                        longitude: _selectedPickupLocation!.longitude,
                      );
                      _isFetchingAddress = false;
                    });
                  }
                }
              },
            ),
          ),

          // Loading indicator
          if (_isFetchingLocation)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: Colors.white,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Fetching current location...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Back button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ),

          // My Location Floating Action Button
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: FloatingActionButton(
                  heroTag: 'pickup_my_location',
                  backgroundColor: Colors.white,
                  onPressed: _isFetchingLocation ? null : _fetchCurrentLocation,
                  child: _isFetchingLocation
                      ? const CircularProgressIndicator(strokeWidth: 2)
                      : const Icon(Icons.my_location, color: Colors.black),
                ),
              ),
            ),
          ),

          // Bottom sheet
          DraggableScrollableSheet(
            initialChildSize: 0.4,
            minChildSize: 0.4,
            maxChildSize: 0.7,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24),
                  children: [
                    // Drag indicator
                    Center(
                      child: Container(
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: AppColors.grey300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Title
                    const Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: Colors.green,
                          size: 36,
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Select a pickup point',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.black,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Adjust your pickup location as needed',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.grey600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Selected address
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.grey100,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.green,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _updatedPickupDetails?.name ??
                                  'Select a location',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.black,
                              ),
                            ),
                          ),
                          if (_isFetchingAddress)
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Confirm pickup button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _updatedPickupDetails == null ||
                                _isFetchingAddress
                            ? null
                            : () async {
                                // Update booking provider with new pickup details
                                widget.bookingProvider
                                    .setPickupLocation(_updatedPickupDetails!);

                                // Create ride
                                final success =
                                    await widget.bookingProvider.requestRide({
                                  'pickupLocation': {
                                    'type': 'Point',
                                    'coordinates': [
                                      _updatedPickupDetails!.longitude,
                                      _updatedPickupDetails!.latitude
                                    ],
                                    'address': _updatedPickupDetails!.address
                                  },
                                  'dropLocation': {
                                    'type': 'Point',
                                    'coordinates': [
                                      widget.bookingProvider.dropLocation!
                                          .longitude,
                                      widget.bookingProvider.dropLocation!
                                          .latitude
                                    ],
                                    'address': widget
                                        .bookingProvider.dropLocation!.address
                                  },
                                  'fare': widget.calculatedFare,
                                  'distance': widget.bookingProvider.distance,
                                  'duration':
                                      widget.bookingProvider.estimatedTime,
                                  'vehicleType': widget
                                      .bookingProvider.selectedRideType?.id,
                                  'paymentMethod': widget.selectedPaymentMethod
                                      .toLowerCase(),
                                });

                                if (success && mounted) {
                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const SearchingDriverScreen(),
                                    ),
                                    (route) => route.isFirst,
                                  );
                                } else if (mounted) {
                                  // Show error
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          'Failed to book ride: ${widget.bookingProvider.error ?? "Unknown error"}'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFC107),
                          disabledBackgroundColor: AppColors.grey300,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Confirm Pickup',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
