import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/booking_provider.dart';

class DriverMatchScreen extends StatefulWidget {
  const DriverMatchScreen({super.key});

  @override
  State<DriverMatchScreen> createState() => _DriverMatchScreenState();
}

class _DriverMatchScreenState extends State<DriverMatchScreen>
    with SingleTickerProviderStateMixin {
  bool _isFindingDriver = true;
  bool _isRequestingRide = true;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  String? _errorMessage;

  // Dummy driver data
  final Map<String, dynamic> _dummyDriver = {
    "name": "John Doe",
    "vehicleNumber": "TN 01 AB 1234",
    "vehicleModel": "Toyota Etios",
    "vehicleColor": "Silver",
    "rating": 4.8,
    "totalRides": 500,
  };

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.4)
        .chain(CurveTween(curve: Curves.easeInOut))
        .animate(_pulseController)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _pulseController.reverse();
        } else if (status == AnimationStatus.dismissed) {
          _pulseController.forward();
        }
      });
    _pulseController.forward();

    _requestRide();
  }

  Future<void> _requestRide() async {
    try {
      final bookingProvider = context.read<BookingProvider>();
      await bookingProvider.requestRide({
        'pickupAddress': bookingProvider.pickupLocation?.address,
        'dropAddress': bookingProvider.dropLocation?.address,
        'fare': bookingProvider.selectedRideType?.estimatedPrice,
        'distance': bookingProvider.distance,
        'rideType': bookingProvider.selectedRideType?.name,
      });
      setState(() {
        _isRequestingRide = false;
      });
      _simulateDriverMatch();
    } catch (e) {
      setState(() {
        _isRequestingRide = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _simulateDriverMatch() async {
    // Simulate finding a driver after 3 seconds
    await Future.delayed(const Duration(seconds: 3));

    if (mounted) {
      setState(() {
        _isFindingDriver = false;
      });
      // Refresh ride history
      await context.read<BookingProvider>().fetchRideHistory();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            // Pulse Animation Icon
            _isRequestingRide
                ? Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF9500).withValues(alpha: 0.3),
                          blurRadius: 30,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: const CircularProgressIndicator(
                      color: Color(0xFFFF9500),
                      strokeWidth: 4,
                    ),
                  )
                : _isFindingDriver
                    ? ScaleTransition(
                        scale: _pulseAnimation,
                        child: Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3E0),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF9500)
                                    .withValues(alpha: 0.3),
                                blurRadius: 30,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.local_taxi,
                            size: 80,
                            color: Color(0xFFFF9500),
                          ),
                        ),
                      )
                    : Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF4CAF50)
                                  .withValues(alpha: 0.3),
                              blurRadius: 30,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.check_circle,
                          size: 80,
                          color: Color(0xFF4CAF50),
                        ),
                      ),
            const SizedBox(height: 32),
            // Status Text
            _isRequestingRide
                ? const Text(
                    "Requesting your ride...",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.black,
                    ),
                  )
                : _isFindingDriver
                    ? const Text(
                        "Waiting for driver to accept...",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.black,
                        ),
                      )
                    : const Text(
                        "Driver found!",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.black,
                        ),
                      ),
            const SizedBox(height: 8),
            _isRequestingRide
                ? const Text(
                    "Please wait while we confirm your ride",
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.grey600,
                    ),
                    textAlign: TextAlign.center,
                  )
                : _isFindingDriver
                    ? const Text(
                        "Looking for nearby drivers to accept your request",
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.grey600,
                        ),
                        textAlign: TextAlign.center,
                      )
                    : const Text(
                        "Your driver is on the way",
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.grey600,
                        ),
                        textAlign: TextAlign.center,
                      ),
            const SizedBox(height: 32),
            // Driver Info Card
            if (!_isFindingDriver)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 15,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Driver Avatar & Name
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
                                  _dummyDriver["name"],
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
                                      "${_dummyDriver["rating"].toStringAsFixed(1)} • ${_dummyDriver["totalRides"]} rides",
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
                      // Vehicle Info
                      Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: AppColors.grey100,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.car_repair,
                                color: AppColors.secondary, size: 28),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _dummyDriver["vehicleModel"],
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
                                        color: _getColorFromName(
                                            _dummyDriver["vehicleColor"]),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                            color: AppColors.grey300),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _dummyDriver["vehicleColor"],
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
                          Text(
                            _dummyDriver["vehicleNumber"],
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.secondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // ETA
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Arriving in",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF4CAF50),
                              ),
                            ),
                            Text(
                              "4 mins",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF4CAF50),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const Spacer(),
            // Bottom Button
            if (!_isFindingDriver)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: ElevatedButton(
                  onPressed: () {
                    // Navigate back home
                    context.read<BookingProvider>().resetBooking();
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                    minimumSize: const Size.fromHeight(56),
                  ),
                  child: const Text(
                    "Cancel Ride",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
