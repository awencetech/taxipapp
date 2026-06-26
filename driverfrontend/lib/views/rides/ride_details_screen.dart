import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/location_provider.dart';
import '../../viewmodels/ride_viewmodel.dart';
import '../../services/google_maps_service.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

class RideDetailsScreen extends StatefulWidget {
  const RideDetailsScreen({super.key});

  @override
  State<RideDetailsScreen> createState() => _RideDetailsScreenState();
}

class _RideDetailsScreenState extends State<RideDetailsScreen> {
  GoogleMapController? _mapController;
  final GoogleMapsService _mapsService = GoogleMapsService();
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  StreamSubscription<Position>? _locationSubscription;

  String _distance = '';
  String _duration = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMap();
    });
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _locationSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadMap() async {
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    final rideViewModel = Provider.of<RideViewModel>(context, listen: false);
    final ride = rideViewModel.currentRide;

    if (ride == null || locationProvider.currentPosition == null) return;

    await _fetchRoute();
    _startLocationUpdates();
  }

  Future<void> _fetchRoute() async {
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    final rideViewModel = Provider.of<RideViewModel>(context, listen: false);
    final ride = rideViewModel.currentRide;

    if (ride == null || locationProvider.currentPosition == null) return;

    // Driver location
    LatLng origin = LatLng(
      locationProvider.currentPosition!.latitude,
      locationProvider.currentPosition!.longitude,
    );

    // Destination is pickup address if not arrived yet, else drop address
    LatLng destination;
    if (ride.status == 'accepted') {
      destination = LatLng(ride.pickupCoords[0], ride.pickupCoords[1]);
    } else {
      destination = LatLng(ride.dropCoords[0], ride.dropCoords[1]);
    }

    try {
      final directionsData = await _mapsService.getDirections(origin, destination);

      setState(() {
        _distance = directionsData['distance'] ?? '';
        _duration = directionsData['duration'] ?? '';
      });

      final List<LatLng> polylinePoints = [];
      if (directionsData['polyline'] != null && directionsData['polyline'].isNotEmpty) {
        final points = PolylinePoints().decodePolyline(directionsData['polyline']);
        for (var point in points) {
          polylinePoints.add(LatLng(point.latitude, point.longitude));
        }
      }

      setState(() {
        _polylines.clear();
        _polylines.add(
          Polyline(
            polylineId: const PolylineId('route'),
            color: const Color(0xFF2EBD59),
            width: 6,
            points: polylinePoints,
          ),
        );

        _markers.clear();
        // Driver position marker
        _markers.add(
          Marker(
            markerId: const MarkerId('current'),
            position: origin,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
            infoWindow: const InfoWindow(title: 'Your Location'),
          ),
        );

        // Pickup position marker
        _markers.add(
          Marker(
            markerId: const MarkerId('pickup'),
            position: LatLng(ride.pickupCoords[0], ride.pickupCoords[1]),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
            infoWindow: InfoWindow(title: 'Pickup Location', snippet: ride.pickupAddress),
          ),
        );

        // Drop position marker
        _markers.add(
          Marker(
            markerId: const MarkerId('drop'),
            position: LatLng(ride.dropCoords[0], ride.dropCoords[1]),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            infoWindow: InfoWindow(title: 'Drop Location', snippet: ride.dropAddress),
          ),
        );
      });

      _zoomToFit();
    } catch (e) {
      debugPrint('Error fetching route in RideDetailsScreen: $e');
    }
  }

  void _startLocationUpdates() {
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    _locationSubscription = locationProvider.currentPosition != null
        ? null
        : Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 10,
            ),
          ).listen((position) {
            setState(() {
              _markers.removeWhere((marker) => marker.markerId == const MarkerId('current'));
              _markers.add(
                Marker(
                  markerId: const MarkerId('current'),
                  position: LatLng(position.latitude, position.longitude),
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
                  infoWindow: const InfoWindow(title: 'Your Location'),
                ),
              );
            });
            _fetchRoute();
          });
  }

  Future<void> _zoomToFit() async {
    if (_mapController == null || _markers.isEmpty) return;

    final bounds = _calculateBounds();
    await _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
  }

  LatLngBounds _calculateBounds() {
    double minLat = double.infinity;
    double maxLat = -double.infinity;
    double minLng = double.infinity;
    double maxLng = -double.infinity;

    for (var marker in _markers) {
      final position = marker.position;
      if (position.latitude < minLat) minLat = position.latitude;
      if (position.latitude > maxLat) maxLat = position.latitude;
      if (position.longitude < minLng) minLng = position.longitude;
      if (position.longitude > maxLng) maxLng = position.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  void _makePhoneCall() async {
    const phoneNumber = 'tel:+919876543210';
    if (await canLaunchUrl(Uri.parse(phoneNumber))) {
      await launchUrl(Uri.parse(phoneNumber));
    }
  }

  void _openMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chat Feature: Under Development')),
    );
  }

  void _navigateExternal() async {
    final rideViewModel = Provider.of<RideViewModel>(context, listen: false);
    final ride = rideViewModel.currentRide;
    if (ride == null) return;
    
    // Launch Google Maps navigation
    final double lat = ride.status == 'accepted' ? ride.pickupCoords[0] : ride.dropCoords[0];
    final double lng = ride.status == 'accepted' ? ride.pickupCoords[1] : ride.dropCoords[1];
    
    final googleMapsUrl = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
    if (await canLaunchUrl(Uri.parse(googleMapsUrl))) {
      await launchUrl(Uri.parse(googleMapsUrl), mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rideViewModel = Provider.of<RideViewModel>(context);
    final ride = rideViewModel.currentRide;

    if (ride == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.directions_car, size: 80, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'No Active Ride',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Back to Home'),
              ),
            ],
          ),
        ),
      );
    }

    String titleText = 'Navigating to Pickup';
    String actionButtonText = 'Arrived at Pickup';
    Color actionButtonColor = const Color(0xFF2EBD59);
    VoidCallback? onActionButtonPressed;

    if (ride.status == 'accepted') {
      titleText = 'Heading to Pickup';
      actionButtonText = 'Arrived at Pickup';
      actionButtonColor = const Color(0xFF2EBD59);
      onActionButtonPressed = () async {
        await rideViewModel.arrivedAtPickup();
      };
    } else if (ride.status == 'arrived') {
      titleText = 'Arrived at Pickup';
      actionButtonText = 'Start Ride';
      actionButtonColor = Colors.orange;
      onActionButtonPressed = () async {
        await rideViewModel.startTrip();
      };
    } else if (ride.status == 'trip_started' || ride.status == 'started') {
      titleText = 'Trip in Progress';
      actionButtonText = 'Complete Trip';
      actionButtonColor = Colors.redAccent;
      onActionButtonPressed = () async {
        await rideViewModel.completeTrip(context);
      };
    } else {
      titleText = 'Ride Status: ${ride.status}';
      actionButtonText = 'Complete Trip';
      actionButtonColor = Colors.grey;
    }

    return Scaffold(
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: LatLng(11.0168, 76.9558),
              zoom: 14,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            markers: _markers,
            polylines: _polylines,
            onMapCreated: (controller) {
              _mapController = controller;
              _zoomToFit();
            },
          ),

          // Header Overlay
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black87),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          titleText,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          ride.status == 'accepted' ? ride.pickupAddress : ride.dropAddress,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Rider Details and Actions Bottom Sheet
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 20,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag indicator
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Passenger profile and name
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.orange.shade50,
                        child: const Icon(Icons.person, color: Colors.orange, size: 30),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ride.passengerName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Color(0xFF1A1A1A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Passenger",
                              style: TextStyle(color: Colors.grey[500], fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      // Actions buttons
                      _buildIconButton(Icons.call, Colors.green, _makePhoneCall),
                      const SizedBox(width: 8),
                      _buildIconButton(Icons.chat_bubble_outline, Colors.blue, _openMessage),
                      const SizedBox(width: 8),
                      _buildIconButton(Icons.navigation_outlined, Colors.orange, _navigateExternal),
                    ],
                  ),

                  const SizedBox(height: 20),
                  const Divider(height: 1),
                  const SizedBox(height: 16),

                  // Rider Details Grid/List
                  _buildDetailRow("Pickup", ride.pickupAddress, iconColor: Colors.green),
                  const SizedBox(height: 8),
                  _buildDetailRow("Drop", ride.dropAddress, iconColor: Colors.red),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: _buildDetailRow("Fare", "₹${ride.fare.toInt()}", iconColor: Colors.green, isBold: true)),
                      Expanded(child: _buildDetailRow("Distance", "${ride.distance.toStringAsFixed(1)} km")),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: _buildDetailRow("Estimated Time", "${ride.estimatedTime} mins")),
                      Expanded(child: _buildDetailRow("Payment Method", ride.paymentMethod)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRow("Ride Type", ride.vehicleType),

                  const SizedBox(height: 24),

                  // Main Status Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: rideViewModel.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                            onPressed: onActionButtonPressed,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: actionButtonColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                            ),
                            child: Text(
                              actionButtonText.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? iconColor, bool isBold = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "$label: ",
          style: TextStyle(
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: const Color(0xFF1A1A1A),
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}
