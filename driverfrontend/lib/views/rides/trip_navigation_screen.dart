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

class TripNavigationScreen extends StatefulWidget {
  final bool isToPickup;

  const TripNavigationScreen({super.key, required this.isToPickup});

  @override
  State<TripNavigationScreen> createState() => _TripNavigationScreenState();
}

class _TripNavigationScreenState extends State<TripNavigationScreen> {
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
    final locationProvider = Provider.of<LocationProvider>(
      context,
      listen: false,
    );
    final rideViewModel = Provider.of<RideViewModel>(context, listen: false);
    final ride = rideViewModel.currentRide;

    if (ride == null || locationProvider.currentPosition == null) return;

    await _fetchRoute();
    _startLocationUpdates();
  }

  Future<void> _fetchRoute() async {
    final locationProvider = Provider.of<LocationProvider>(
      context,
      listen: false,
    );
    final rideViewModel = Provider.of<RideViewModel>(context, listen: false);
    final ride = rideViewModel.currentRide;

    if (ride == null || locationProvider.currentPosition == null) return;

    LatLng origin = LatLng(
      locationProvider.currentPosition!.latitude,
      locationProvider.currentPosition!.longitude,
    );
    LatLng destination;

    if (widget.isToPickup || ride.status == 'arrived') {
      destination = LatLng(ride.pickupCoords[0], ride.pickupCoords[1]);
    } else {
      destination = LatLng(ride.dropCoords[0], ride.dropCoords[1]);
    }

    try {
      final directionsData = await _mapsService.getDirections(
        origin,
        destination,
      );

      setState(() {
        _distance = directionsData['distance'] ?? '';
        _duration = directionsData['duration'] ?? '';
      });

      final List<LatLng> polylinePoints = [];
      if (directionsData['polyline'] != null &&
          directionsData['polyline'].isNotEmpty) {
        final points = PolylinePoints().decodePolyline(
          directionsData['polyline'],
        );
        for (var point in points) {
          polylinePoints.add(LatLng(point.latitude, point.longitude));
        }
      }

      setState(() {
        _polylines.clear();
        _polylines.add(
          Polyline(
            polylineId: const PolylineId('route'),
            color: Colors.blue,
            width: 6,
            points: polylinePoints,
          ),
        );

        _markers.clear();
        _markers.add(
          Marker(
            markerId: const MarkerId('current'),
            position: origin,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueBlue,
            ),
            infoWindow: const InfoWindow(title: 'Your Location'),
          ),
        );

        if (widget.isToPickup || ride.status == 'arrived') {
          _markers.add(
            Marker(
              markerId: const MarkerId('pickup'),
              position: LatLng(ride.pickupCoords[0], ride.pickupCoords[1]),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueGreen,
              ),
              infoWindow: InfoWindow(
                title: 'Pickup',
                snippet: ride.pickupAddress,
              ),
            ),
          );
        } else {
          _markers.add(
            Marker(
              markerId: const MarkerId('drop'),
              position: LatLng(ride.dropCoords[0], ride.dropCoords[1]),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueRed,
              ),
              infoWindow: InfoWindow(title: 'Drop', snippet: ride.dropAddress),
            ),
          );
        }
      });

      _zoomToFit();
    } catch (e) {
      debugPrint('Error fetching route: $e');
    }
  }

  void _startLocationUpdates() {
    final locationProvider = Provider.of<LocationProvider>(
      context,
      listen: false,
    );
    _locationSubscription = locationProvider.currentPosition != null
        ? null
        : Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 10,
            ),
          ).listen((position) {
            setState(() {
              _markers.removeWhere(
                (marker) => marker.markerId == const MarkerId('current'),
              );
              _markers.add(
                Marker(
                  markerId: const MarkerId('current'),
                  position: LatLng(position.latitude, position.longitude),
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueBlue,
                  ),
                  infoWindow: const InfoWindow(title: 'Your Location'),
                ),
              );
            });
            _fetchRoute(); // Re-fetch route on position update
          });
  }

  Future<void> _zoomToFit() async {
    if (_mapController == null || _markers.isEmpty) return;

    final bounds = _calculateBounds();
    await _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 100),
    );
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
    const phoneNumber = 'tel:+911234567890';
    if (await canLaunchUrl(Uri.parse(phoneNumber))) {
      await launchUrl(Uri.parse(phoneNumber));
    }
  }

  void _openMessage() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Chat feature coming soon!')));
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
              const Icon(Icons.directions_car, size: 100, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'No active ride',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      );
    }

    String titleText;
    String subTitleText;
    String actionButtonText;
    VoidCallback? onActionButtonPressed;
    Color actionButtonColor;

    if (widget.isToPickup) {
      if (ride.status == 'accepted') {
        titleText = 'Navigating to Pickup';
        subTitleText = ride.pickupAddress;
        actionButtonText = 'Arrived at Pickup';
        actionButtonColor = Colors.green;
        onActionButtonPressed = () async {
          await rideViewModel.arrivedAtPickup();
        };
      } else if (ride.status == 'arrived') {
        titleText = 'Arrived at Pickup';
        subTitleText = ride.pickupAddress;
        actionButtonText = 'Start Trip';
        actionButtonColor = Colors.orange;
        onActionButtonPressed = () async {
          await rideViewModel.startTrip();
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    const TripNavigationScreen(isToPickup: false),
              ),
            );
          }
        };
      } else {
        titleText = 'Navigating to Pickup';
        subTitleText = ride.pickupAddress;
        actionButtonText = 'Start Trip';
        actionButtonColor = Colors.grey;
        onActionButtonPressed = null;
      }
    } else {
      titleText = 'Heading to Destination';
      subTitleText = ride.dropAddress;
      actionButtonText = 'Complete Trip';
      actionButtonColor = Colors.orange;
      onActionButtonPressed = () async {
        await rideViewModel.completeTrip(context);
      };
    }

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: LatLng(11.0168, 76.9558), // Coimbatore
              zoom: 15,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            mapType: MapType.normal,
            markers: _markers,
            polylines: _polylines,
            onMapCreated: (controller) {
              _mapController = controller;
              _zoomToFit();
            },
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withValues(alpha: 0.3),
                          spreadRadius: 1,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black87),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 70),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF2D2D2D),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: widget.isToPickup
                          ? Colors.green.withValues(alpha: 0.2)
                          : Colors.red.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      widget.isToPickup ? Icons.navigation : Icons.location_on,
                      color: widget.isToPickup ? Colors.green : Colors.red,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          titleText,
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subTitleText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.access_time,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _duration,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Icon(
                              Icons.location_on,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _distance,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFFF6D00),
                            width: 2,
                          ),
                        ),
                        child: const CircleAvatar(
                          radius: 28,
                          backgroundColor: Color(0xFFF5F5F5),
                          child: Icon(
                            Icons.person,
                            color: Colors.grey,
                            size: 30,
                          ),
                        ),
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
                            Row(
                              children: [
                                const Icon(
                                  Icons.star,
                                  color: Color(0xFFFFD700),
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '4.9 Rating',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      _buildActionCircle(
                        Icons.call,
                        Colors.green,
                        _makePhoneCall,
                      ),
                      const SizedBox(width: 12),
                      _buildActionCircle(
                        Icons.message,
                        Colors.blue,
                        _openMessage,
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: rideViewModel.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                            onPressed: onActionButtonPressed,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: actionButtonColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              actionButtonText,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCircle(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }
}
