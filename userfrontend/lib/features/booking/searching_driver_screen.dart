import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/booking_provider.dart';
import '../../core/providers/location_provider.dart';
import 'driver_match_screen.dart';

class SearchingDriverScreen extends StatefulWidget {
  const SearchingDriverScreen({super.key});

  @override
  State<SearchingDriverScreen> createState() => _SearchingDriverScreenState();
}

class _SearchingDriverScreenState extends State<SearchingDriverScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  Timer? _searchTimer;
  final Completer<GoogleMapController> _mapController = Completer();
  bool _hasFittedRoute = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchTimer?.cancel();
    super.dispose();
  }

  Future<void> _fitCameraToRoute() async {
    final bookingProvider = context.read<BookingProvider>();
    final locationProvider = context.read<LocationProvider>();

    if (_hasFittedRoute) return;

    List<LatLng> points = [];

    // Add pickup location
    if (bookingProvider.pickupLocation != null) {
      points.add(LatLng(
        bookingProvider.pickupLocation!.latitude,
        bookingProvider.pickupLocation!.longitude,
      ));
    }

    // Add drop location
    if (bookingProvider.dropLocation != null) {
      points.add(LatLng(
        bookingProvider.dropLocation!.latitude,
        bookingProvider.dropLocation!.longitude,
      ));
    }

    // Add driver location if available
    if (bookingProvider.currentRide?.driverLatitude != null &&
        bookingProvider.currentRide?.driverLongitude != null) {
      points.add(LatLng(
        bookingProvider.currentRide!.driverLatitude!,
        bookingProvider.currentRide!.driverLongitude!,
      ));
    }

    // Add polyline points
    if (bookingProvider.polylinePoints.isNotEmpty) {
      points.addAll(bookingProvider.polylinePoints);
    }

    // Fallback to current location if no points
    if (points.isEmpty && locationProvider.currentPosition != null) {
      points.add(LatLng(
        locationProvider.currentPosition!.latitude,
        locationProvider.currentPosition!.longitude,
      ));
    }

    if (points.isNotEmpty) {
      final GoogleMapController controller = await _mapController.future;
      LatLngBounds bounds = _boundsFromLatLngList(points);
      controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
      _hasFittedRoute = true;
    }
  }

  LatLngBounds _boundsFromLatLngList(List<LatLng> list) {
    double? x0, x1, y0, y1;
    for (LatLng latLng in list) {
      if (x0 == null) {
        x0 = x1 = latLng.latitude;
        y0 = y1 = latLng.longitude;
      } else {
        if (latLng.latitude > x1!) x1 = latLng.latitude;
        if (latLng.latitude < x0) x0 = latLng.latitude;
        if (latLng.longitude > y1!) y1 = latLng.longitude;
        if (latLng.longitude < y0!) y0 = latLng.longitude;
      }
    }
    return LatLngBounds(
      northeast: LatLng(x1!, y1!),
      southwest: LatLng(x0!, y0!),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bookingProvider = context.watch<BookingProvider>();
    final locationProvider = context.watch<LocationProvider>();
    final currentRide = bookingProvider.currentRide;
    final isRideAccepted = currentRide != null &&
        (currentRide.status == 'accepted' ||
            currentRide.status == 'driver_arriving');

    // Build markers
    Set<Marker> markers = {};

    // Pickup marker
    if (bookingProvider.pickupLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('pickup'),
          position: LatLng(
            bookingProvider.pickupLocation!.latitude,
            bookingProvider.pickupLocation!.longitude,
          ),
          infoWindow: const InfoWindow(title: 'Pickup'),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
      );
    }

    // Drop marker
    if (bookingProvider.dropLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('drop'),
          position: LatLng(
            bookingProvider.dropLocation!.latitude,
            bookingProvider.dropLocation!.longitude,
          ),
          infoWindow: const InfoWindow(title: 'Drop'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    }

    // Driver marker
    if (isRideAccepted &&
        currentRide.driverLatitude != null &&
        currentRide.driverLongitude != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('driver'),
          position: LatLng(
            currentRide.driverLatitude!,
            currentRide.driverLongitude!,
          ),
          infoWindow: InfoWindow(title: currentRide.driverName ?? 'Driver'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
    }

    // Build polyline
    Set<Polyline> polylines = {};
    if (bookingProvider.polylinePoints.isNotEmpty) {
      polylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          color: AppColors.primary,
          width: 6,
          points: bookingProvider.polylinePoints,
          geodesic: true,
          jointType: JointType.round,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
        ),
      );
    }

    // Fit camera to route once when ride is accepted
    if (isRideAccepted && !_hasFittedRoute) {
      Future.microtask(() => _fitCameraToRoute());
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // Google Map
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: locationProvider.currentPosition != null
                    ? LatLng(
                        locationProvider.currentPosition!.latitude,
                        locationProvider.currentPosition!.longitude,
                      )
                    : const LatLng(11.0168, 76.9558),
                zoom: 16,
              ),
              onMapCreated: (GoogleMapController controller) {
                _mapController.complete(controller);
              },
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomGesturesEnabled: true,
              scrollGesturesEnabled: true,
              rotateGesturesEnabled: false,
              tiltGesturesEnabled: false,
              markers: markers,
              polylines: polylines,
            ),

            // Back button
            Padding(
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
                  onPressed: () => _cancelRide(),
                ),
              ),
            ),

            // Searching animated circle on map when not accepted
            if (!isRideAccepted)
              Positioned.fill(
                child: Center(
                  child: AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: const Offset(0, -100),
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.green.withValues(
                                alpha: 0.2 * (1 - _animation.value)),
                          ),
                          child: Center(
                            child: Container(
                              width: 200 * (0.5 + _animation.value * 0.5),
                              height: 200 * (0.5 + _animation.value * 0.5),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.green.withValues(
                                    alpha: 0.3 * (1 - _animation.value)),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.location_on,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

            // Bottom sheet
            DraggableScrollableSheet(
              initialChildSize: 0.55,
              minChildSize: 0.55,
              maxChildSize: 0.9,
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
                      const SizedBox(height: 24),

                      // If ride is accepted, show driver info
                      if (isRideAccepted)
                        _buildDriverInfoCard(currentRide)
                      else
                        // Else show searching UI
                        _buildSearchingUI(bookingProvider),

                      const SizedBox(height: 24),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchingUI(BookingProvider bookingProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Few captains nearby, try other services',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.black,
          ),
        ),
        const SizedBox(height: 24),

        // Trip details card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.grey100,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pickup
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on, color: Colors.green, size: 24),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Pickup',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.grey600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          bookingProvider.pickupLocation?.name ??
                              'Pickup Location',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Divider
              Container(
                margin: const EdgeInsets.only(left: 9),
                width: 2,
                height: 24,
                color: AppColors.grey300,
              ),
              const SizedBox(height: 12),
              // Drop
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_pin, color: Colors.red, size: 24),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Drop',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.grey600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          bookingProvider.dropLocation?.name ?? 'Drop Location',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Vehicle and fare
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.grey100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      bookingProvider.selectedRideType?.icon ??
                          Icons.directions_car,
                      size: 28,
                      color: bookingProvider.selectedRideType?.iconColor ??
                          AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bookingProvider.selectedRideType?.name ?? 'Ride',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₹${bookingProvider.currentRide?.fare.toStringAsFixed(0) ?? '0'}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      'Trip Details',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Status
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.search, color: AppColors.primary, size: 24),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Searching Driver...',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.black,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Looking for nearby captains',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.grey600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Add services to get ride faster
        const Text(
          'Add services to get ride faster',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildDriverInfoCard(dynamic currentRide) {
    Color _getColorFromName(String colorName) {
      switch (colorName.toLowerCase()) {
        case "silver":
          return const Color(0xFFC0C0C0);
        case "black":
          return Colors.black;
        case "white":
          return Colors.white;
        case "red":
          return Colors.red;
        case "blue":
          return Colors.blue;
        default:
          return AppColors.grey300;
      }
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Driver Found!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppColors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currentRide.driverName ?? 'Unknown Driver',
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.grey600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 60,
                  height: 60,
                  color: AppColors.grey300,
                  child: const Icon(
                    Icons.person,
                    size: 40,
                    color: AppColors.grey400,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Driver info
          Row(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: const BoxDecoration(
                  color: AppColors.grey100,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person,
                    size: 40, color: AppColors.grey400),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentRide.driverName ?? 'Unknown Driver',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star,
                            size: 16, color: Color(0xFFFF9500)),
                        const SizedBox(width: 4),
                        Text(
                          '${(currentRide.driverRating != null ? currentRide.driverRating.toStringAsFixed(1) : "5.0")} • 500 rides',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.grey600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(height: 1),
          const SizedBox(height: 24),

          // Vehicle info
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.grey100,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.directions_car,
                    color: AppColors.secondary, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentRide.driverVehicleType ?? 'Car',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 24,
                          height: 16,
                          decoration: BoxDecoration(
                            color: _getColorFromName("Silver"),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: AppColors.grey300),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Silver',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.grey600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Text(
                currentRide.driverVehicleNumber ?? 'TN 01 AB 1234',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // OTP
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Text(
                  'Ride OTP',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4CAF50),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  currentRide.otp ?? '1234',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4CAF50),
                    letterSpacing: 4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _cancelRide() {
    context.read<BookingProvider>().resetBooking();
    Navigator.popUntil(context, (route) => route.isFirst);
  }
}
