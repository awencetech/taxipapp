import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/booking_provider.dart';
import 'ride_history_screen.dart';

class SearchingDriverScreen extends StatefulWidget {
  const SearchingDriverScreen({super.key});

  @override
  State<SearchingDriverScreen> createState() => _SearchingDriverScreenState();
}

class _SearchingDriverScreenState extends State<SearchingDriverScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  int _nearbyDrivers = 5;
  Timer? _searchTimer;

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
    
    // Simulate search for driver
    _searchTimer = Timer(const Duration(seconds: 10), () {
      if (mounted) {
        // In real app, you'd wait for real driver match
        // For demo, let's navigate to ride history after 10 seconds
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const RideHistoryScreen(),
          ),
          (route) => route.isFirst,
        );
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bookingProvider = context.watch<BookingProvider>();
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Finding your ride...",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.black,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      _cancelRide();
                    },
                    child: const Text(
                      "Cancel Ride",
                      style: TextStyle(
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animated Searching Indicator
                    AnimatedBuilder(
                      animation: _animation,
                      builder: (context, child) {
                        return Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary.withValues(alpha: 0.1),
                          ),
                          child: Center(
                            child: Container(
                              width: 200 * (0.5 + _animation.value * 0.5),
                              height: 200 * (0.5 + _animation.value * 0.5),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.primary.withValues(alpha: 0.2),
                              ),
                              child: Center(
                                child: Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.primary,
                                  ),
                                  child: const Icon(
                                    Icons.directions_car,
                                    color: Colors.white,
                                    size: 50,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Searching Text
                    const Text(
                      "Searching for nearby drivers...",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.black,
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Nearby Drivers
                    Text(
                      "$_nearbyDrivers drivers nearby",
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.grey600,
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Ride Details
                    if (bookingProvider.selectedRideType != null)
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.grey100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    bookingProvider.selectedRideType?.icon,
                                    size: 24,
                                    color: bookingProvider.selectedRideType?.iconColor,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        bookingProvider.selectedRideType?.name ?? "",
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.black,
                                        ),
                                      ),
                                      Text(
                                        "₹${bookingProvider.selectedRideType?.estimatedPrice.toStringAsFixed(0)}",
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.secondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 32, thickness: 1),
                            // Pickup & Drop
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Column(
                                  children: [
                                    Container(
                                      width: 16,
                                      height: 16,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF4CD964),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.circle,
                                          size: 8, color: Colors.white),
                                    ),
                                    Container(
                                      width: 2,
                                      height: 24,
                                      color: AppColors.grey300,
                                    ),
                                    Container(
                                      width: 16,
                                      height: 16,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFFF9500),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.location_pin,
                                          size: 10, color: Colors.white),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Pickup",
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.grey600,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        bookingProvider.pickupLocation?.address ?? "",
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.black,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        "Drop",
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.grey600,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        bookingProvider.dropLocation?.address ?? "",
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.black,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
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
          ],
        ),
      ),
    );
  }

  void _cancelRide() {
    context.read<BookingProvider>().resetBooking();
    Navigator.popUntil(context, (route) => route.isFirst);
  }
}