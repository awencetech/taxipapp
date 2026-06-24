import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/booking_provider.dart';
import '../../core/models/ride_type.dart';

class RideMapScreen extends StatefulWidget {
  const RideMapScreen({super.key});

  @override
  State<RideMapScreen> createState() => _RideMapScreenState();
}

class _RideMapScreenState extends State<RideMapScreen> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateMap();
    });
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  void _updateMap() {
    final bookingProvider = context.read<BookingProvider>();
    final markers = <Marker>{};
    final polylines = <Polyline>{};

    if (bookingProvider.pickupLocation != null) {
      markers.add(Marker(
        markerId: const MarkerId('pickup'),
        position: LatLng(
          bookingProvider.pickupLocation!.latitude,
          bookingProvider.pickupLocation!.longitude,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ));
    }

    if (bookingProvider.dropLocation != null) {
      markers.add(Marker(
        markerId: const MarkerId('drop'),
        position: LatLng(
          bookingProvider.dropLocation!.latitude,
          bookingProvider.dropLocation!.longitude,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
      ));
    }

    if (bookingProvider.polylinePoints.isNotEmpty) {
      polylines.add(Polyline(
        polylineId: const PolylineId('route'),
        points: bookingProvider.polylinePoints.map((point) {
          return LatLng(point['latitude'], point['longitude']);
        }).toList(),
        color: Colors.blue,
        width: 5,
      ));
    }

    setState(() {
      _markers.addAll(markers);
      _polylines.addAll(polylines);
    });

    // Auto-zoom to fit both markers
    if (_mapController != null &&
        bookingProvider.pickupLocation != null &&
        bookingProvider.dropLocation != null) {
      final bounds = LatLngBounds(
        southwest: LatLng(
          bookingProvider.pickupLocation!.latitude <
                  bookingProvider.dropLocation!.latitude
              ? bookingProvider.pickupLocation!.latitude
              : bookingProvider.dropLocation!.latitude,
          bookingProvider.pickupLocation!.longitude <
                  bookingProvider.dropLocation!.longitude
              ? bookingProvider.pickupLocation!.longitude
              : bookingProvider.dropLocation!.longitude,
        ),
        northeast: LatLng(
          bookingProvider.pickupLocation!.latitude >
                  bookingProvider.dropLocation!.latitude
              ? bookingProvider.pickupLocation!.latitude
              : bookingProvider.dropLocation!.latitude,
          bookingProvider.pickupLocation!.longitude >
                  bookingProvider.dropLocation!.longitude
              ? bookingProvider.pickupLocation!.longitude
              : bookingProvider.dropLocation!.longitude,
        ),
      );

      _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Google Map
          Consumer<BookingProvider>(
            builder: (context, bookingProvider, child) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _updateMap(); // Call update map whenever provider changes
              });
              
              if (bookingProvider.pickupLocation == null) {
                return const Center(child: Text('Pickup location not set'));
              }

              return GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(
                    bookingProvider.pickupLocation!.latitude,
                    bookingProvider.pickupLocation!.longitude,
                  ),
                  zoom: 14,
                ),
                onMapCreated: (controller) {
                  _mapController = controller;
                  _updateMap();
                },
                markers: _markers,
                polylines: _polylines,
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
              );
            },
          ),
          // Top Back Button
          Positioned(
            top: 20,
            left: 20,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.black),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
          // Bottom Sheet: Vehicle Selection
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 15,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: SafeArea(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Distance & Time
                      Consumer<BookingProvider>(
                        builder: (context, bookingProvider, child) {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "${bookingProvider.distance.toStringAsFixed(1)} km",
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.black,
                                    ),
                                  ),
                                  Text(
                                    "${bookingProvider.estimatedTime} mins",
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: AppColors.grey600,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF3E0),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  "Fastest Route",
                                  style: TextStyle(
                                    color: Color(0xFFFF9500),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      // Available Vehicles
                      const Text(
                        "Available Rides",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.black,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Consumer<BookingProvider>(
                        builder: (context, bookingProvider, child) {
                          // Get available ride types
                          final rideTypes =
                              RideType.getDummyRides(bookingProvider.distance);

                          return SizedBox(
                            height: 200,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: rideTypes.length,
                              itemBuilder: (context, index) {
                                final ride = rideTypes[index];
                                final isSelected =
                                    bookingProvider.selectedRideType?.id ==
                                        ride.id;

                                return GestureDetector(
                                  onTap: () {
                                    bookingProvider.selectRideType(ride);
                                  },
                                  child: Container(
                                    width: 160,
                                    margin: const EdgeInsets.only(right: 12),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(0xFFFFF3E0)
                                          : AppColors.grey100,
                                      borderRadius: BorderRadius.circular(20),
                                      border: isSelected
                                          ? Border.all(
                                              color: const Color(0xFFFF9500),
                                              width: 2)
                                          : null,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        // Vehicle Icon
                                        Container(
                                          width: 50,
                                          height: 50,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withValues(alpha: 0.08),
                                                blurRadius: 6,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Icon(ride.icon,
                                              size: 24, color: ride.iconColor),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          ride.name,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.black,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          "${ride.maxPassengers} Seats",
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.grey600,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        const Text(
                                          "5 mins away",
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.grey600,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          "₹${ride.estimatedPrice.toStringAsFixed(0)}",
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.black,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      // Book Ride Button
                      Consumer<BookingProvider>(
                        builder: (context, bookingProvider, child) {
                          return ElevatedButton(
                            onPressed: bookingProvider.selectedRideType == null
                                ? null
                                : () {
                                    Navigator.pushNamed(
                                        context, '/driver-match');
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF9500),
                              disabledBackgroundColor: AppColors.grey300,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              elevation: 0,
                              minimumSize: const Size.fromHeight(56),
                            ),
                            child: bookingProvider.selectedRideType == null
                                ? const Text("Select a ride to book",
                                    style: TextStyle(fontSize: 18))
                                : Text(
                                    "Book ${bookingProvider.selectedRideType!.name} - ₹${bookingProvider.selectedRideType!.estimatedPrice.toStringAsFixed(0)}",
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
