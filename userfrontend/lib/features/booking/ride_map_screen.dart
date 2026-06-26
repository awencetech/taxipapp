import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/booking_provider.dart';
import '../../core/models/ride_type.dart';
import 'keep_alive_map.dart';

class RideMapScreen extends StatefulWidget {
  const RideMapScreen({super.key});

  @override
  State<RideMapScreen> createState() => _RideMapScreenState();
}

class _RideMapScreenState extends State<RideMapScreen> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Keep Alive Interactive Map
          Consumer<BookingProvider>(
            builder: (context, bookingProvider, child) {
              if (bookingProvider.pickupLocation == null) {
                return const Center(child: Text('Pickup location not set'));
              }

              return KeepAliveMap(
                pickupLocation: bookingProvider.pickupLocation,
                dropLocation: bookingProvider.dropLocation,
                polylinePoints: bookingProvider.polylinePoints,
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
                                    bookingProvider.distanceText.isNotEmpty
                                        ? bookingProvider.distanceText
                                        : "${bookingProvider.distance.toStringAsFixed(1)} km",
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.black,
                                    ),
                                  ),
                                  Text(
                                    bookingProvider.durationText.isNotEmpty
                                        ? bookingProvider.durationText
                                        : "${bookingProvider.estimatedTime} mins",
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
