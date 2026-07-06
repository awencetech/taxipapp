import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/booking_provider.dart';
import '../../core/models/ride_model.dart';
import 'history_screen.dart';

class RideHistoryScreen extends StatefulWidget {
  const RideHistoryScreen({super.key});

  @override
  State<RideHistoryScreen> createState() => _RideHistoryScreenState();
}

class _RideHistoryScreenState extends State<RideHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookingProvider>().fetchRideHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Consumer<BookingProvider>(
          builder: (context, provider, child) {
            // Use pendingRides for upcoming rides
            final upcomingRides = provider.pendingRides;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Row(
                    children: [
                      const SizedBox(width: 8),
                      const Text(
                        'Rides',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const HistoryScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          'History',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: AppColors.secondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: provider.isLoading && upcomingRides.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : provider.error != null && upcomingRides.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.error_outline,
                                      size: 48, color: Colors.red),
                                  const SizedBox(height: 16),
                                  Text('Error: ${provider.error}',
                                      textAlign: TextAlign.center),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: () =>
                                        provider.fetchRideHistory(),
                                    child: const Text('Retry'),
                                  ),
                                ],
                              ),
                            )
                          : upcomingRides.isEmpty
                              ? const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.directions_car_outlined,
                                          size: 64, color: Colors.grey),
                                      SizedBox(height: 16),
                                      Text(
                                        'No upcoming rides found!',
                                        style: TextStyle(
                                            fontSize: 18, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  itemCount: upcomingRides.length,
                                  itemBuilder: (context, index) {
                                    final ride = upcomingRides[index];
                                    return _buildRideCard(ride);
                                  },
                                ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildRideCard(RideModel ride) {
    // Format date and time
    String dateStr = 'Unknown';
    String timeStr = '';
    if (ride.createdAt != null) {
      final now = DateTime.now();
      final diff = now.difference(ride.createdAt!);
      if (diff.inDays == 0) {
        dateStr = 'Today';
      } else if (diff.inDays == 1) {
        dateStr = 'Yesterday';
      } else if (diff.inDays < 7) {
        dateStr = DateFormat('EEE').format(ride.createdAt!);
      } else {
        dateStr = DateFormat('MMM dd').format(ride.createdAt!);
      }
      timeStr = DateFormat('hh:mm a').format(ride.createdAt!);
    }

    // Format distance
    String distanceStr = ride.distance != null
        ? '${ride.distance!.toStringAsFixed(1)} km'
        : 'N/A';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Color(0xFFFF9500),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  ride.pickupAddress,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                '₹${ride.fare.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.location_pin,
                size: 18,
                color: AppColors.secondary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  ride.dropAddress,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.grey600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.access_time,
                size: 16,
                color: AppColors.grey600,
              ),
              const SizedBox(width: 6),
              Text(
                '$dateStr • $timeStr',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.grey600,
                ),
              ),
              const SizedBox(width: 16),
              const Icon(
                Icons.location_pin,
                size: 16,
                color: AppColors.grey600,
              ),
              const SizedBox(width: 6),
              Text(
                distanceStr,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.grey600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: const BorderSide(color: Colors.red),
                  ),
                  icon: const Icon(
                    Icons.cancel,
                    color: Colors.red,
                  ),
                  onPressed: () async {
                    // Show cancellation reason dialog
                    String? reason = await showDialog<String>(
                      context: context,
                      builder: (context) => const CancelReasonDialog(),
                    );
                    if (reason != null && mounted) {
                      await context
                          .read<BookingProvider>()
                          .cancelRide(ride.id, reason);
                    }
                  },
                  label: const Text(
                    'Cancel Ride',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class CancelReasonDialog extends StatefulWidget {
  const CancelReasonDialog({super.key});

  @override
  State<CancelReasonDialog> createState() => _CancelReasonDialogState();
}

class _CancelReasonDialogState extends State<CancelReasonDialog> {
  final List<String> reasons = [
    'Changed my mind',
    'Found another ride',
    'Pickup time too long',
    'Driver not responding',
    'Other'
  ];
  String? selectedReason;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Cancel Ride'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: reasons.map((reason) {
          return ListTile(
            title: Text(reason),
            leading: Radio<String>(
              value: reason,
              groupValue: selectedReason,
              onChanged: (value) {
                setState(() {
                  selectedReason = value;
                });
              },
            ),
          );
        }).toList(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Back'),
        ),
        ElevatedButton(
          onPressed: selectedReason == null
              ? null
              : () => Navigator.pop(context, selectedReason),
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}
