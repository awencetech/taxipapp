import 'package:flutter/material.dart';
import '../../core/models/ride_type.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/api_service.dart';

class BookingConfirmationScreen extends StatefulWidget {
  final String pickupAddress;
  final String dropAddress;
  final String distance;
  final String duration;
  final double distanceKm;
  final int durationMinutes;
  final RideType selectedRide;
  final Map<String, dynamic> pickupLocation;
  final Map<String, dynamic> dropLocation;
  final Function(Map<String, dynamic>)? onBookingConfirmed;

  const BookingConfirmationScreen({
    super.key,
    required this.pickupAddress,
    required this.dropAddress,
    required this.distance,
    required this.duration,
    required this.distanceKm,
    required this.durationMinutes,
    required this.selectedRide,
    required this.pickupLocation,
    required this.dropLocation,
    this.onBookingConfirmed,
  });

  @override
  State<BookingConfirmationScreen> createState() =>
      _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState extends State<BookingConfirmationScreen> {
  int _selectedPaymentMethod = 0; // 0 = Cash, 1 = UPI
  final ApiService _apiService = ApiService();
  bool _isBooking = false;

  final List<Map<String, dynamic>> paymentMethods = [
    {
      'name': 'Cash',
      'value': 'cash',
      'icon': Icons.money,
      'color': AppColors.secondary,
    },
    {
      'name': 'UPI',
      'value': 'upi',
      'icon': Icons.account_balance_wallet,
      'color': const Color(0xFF00C853),
    },
  ];

  Future<void> _confirmBooking() async {
    setState(() {
      _isBooking = true;
    });

    try {
      await _apiService.bookRide({
        'pickupLocation': {
          'address': widget.pickupAddress,
          'coordinates': [
            widget.pickupLocation['longitude'],
            widget.pickupLocation['latitude'],
          ],
        },
        'dropLocation': {
          'address': widget.dropAddress,
          'coordinates': [
            widget.dropLocation['longitude'],
            widget.dropLocation['latitude'],
          ],
        },
        'fare': widget.selectedRide.estimatedPrice,
        'distance': widget.distanceKm,
        'duration': widget.durationMinutes,
        'vehicleType': widget.selectedRide.name.toLowerCase(),
        'paymentMethod': paymentMethods[_selectedPaymentMethod]['value'],
      });

      // Create the destination data
      final destination = {
        'name': (widget.dropAddress.split(',')
                  ..removeWhere((part) => part.trim().isEmpty))
                .firstOrNull
                ?.trim() ??
            widget.dropAddress,
        'address': widget.dropAddress,
        'distance': widget.distance,
        'duration': widget.duration,
        'isFavorite': false,
      };

      // Call the callback if provided
      widget.onBookingConfirmed?.call(destination);

      // Show success dialog
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Booking Confirmed!'),
            content: const Text(
              'Your ride has been booked successfully. A driver will be assigned shortly.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  // Pop confirmation dialog
                  Navigator.pop(context);
                  // Pop booking confirmation screen
                  Navigator.pop(context);
                  // Pop ride booking screen
                  Navigator.pop(context);
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Booking failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isBooking = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(24),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 700),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Confirm Booking',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.black,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 28),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // User Details Card
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: const BoxDecoration(
                          color: AppColors.secondary,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Text(
                            'JD',
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'John Doe',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.black,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'john.doe@example.com',
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
                ),
                const SizedBox(height: 16),

                // Trip Details Card
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16),
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
                      // Pickup and Drop
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Location Dots
                          Column(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: const BoxDecoration(
                                  color: AppColors.secondary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Container(
                                width: 2,
                                height: 40,
                                color: AppColors.grey300,
                                margin: const EdgeInsets.symmetric(vertical: 6),
                              ),
                              Container(
                                width: 12,
                                height: 12,
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 12),
                          // Addresses
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Pickup',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.grey600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  widget.pickupAddress,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.black,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Drop',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.grey600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  widget.dropAddress,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
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
                      const SizedBox(height: 16),
                      // Distance and Time
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Distance',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.grey600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  widget.distance,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text(
                                  'Estimated Time',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.grey600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  widget.duration,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Selected Vehicle
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Selected Ride',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.black,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: widget.selectedRide.iconColor
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                'https://picsum.photos/seed/${widget.selectedRide.id}/200/200',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    widget.selectedRide.icon,
                                    size: 36,
                                    color: widget.selectedRide.iconColor,
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.selectedRide.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.black,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  widget.selectedRide.description,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.grey600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.people,
                                        size: 14, color: AppColors.grey400),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${widget.selectedRide.maxPassengers} passengers',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.grey400,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '₹${widget.selectedRide.estimatedPrice}',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.black,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Payment Methods Card
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Payment Method',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.black,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...List.generate(
                        paymentMethods.length,
                        (index) {
                          final method = paymentMethods[index];
                          final isSelected = _selectedPaymentMethod == index;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedPaymentMethod = index;
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.secondary
                                        .withValues(alpha: 0.08)
                                    : AppColors.grey100,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.secondary
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: method['color']
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      method['icon'],
                                      color: method['color'],
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      method['name'],
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.black,
                                      ),
                                    ),
                                  ),
                                  if (isSelected)
                                    const Icon(
                                      Icons.check_circle,
                                      color: AppColors.secondary,
                                      size: 24,
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Action Buttons
                ElevatedButton(
                  onPressed: () {
                    // Navigate back to edit
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: AppColors.grey200,
                    foregroundColor: AppColors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.edit, size: 18),
                      SizedBox(width: 6),
                      Text(
                        'Edit Booking',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _isBooking ? null : _confirmBooking,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: AppColors.secondary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isBooking
                      ? const CircularProgressIndicator(color: AppColors.white)
                      : const Text(
                          'Confirm Booking',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.white,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
