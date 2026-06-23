import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/booking_provider.dart';
import '../../core/models/ride_model.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
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
            // Only completed and cancelled rides
            final historyRides = provider.rideHistory
                .where((ride) => ['completed', 'cancelled']
                    .contains(ride.status.toLowerCase()))
                .toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, size: 30),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'History',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: provider.isLoading && historyRides.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : provider.error != null && historyRides.isEmpty
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
                          : historyRides.isEmpty
                              ? const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.history_outlined,
                                          size: 64, color: Colors.grey),
                                      SizedBox(height: 16),
                                      Text(
                                        'No ride history found!',
                                        style: TextStyle(
                                            fontSize: 18, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  itemCount: historyRides.length,
                                  itemBuilder: (context, index) {
                                    final ride = historyRides[index];
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
    // Get status color
    Color statusColor;
    String statusText;
    if (ride.status.toLowerCase() == 'completed') {
      statusColor = Colors.green;
      statusText = 'Completed';
    } else {
      statusColor = Colors.red;
      statusText = 'Cancelled';
    }

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
                decoration: BoxDecoration(
                  color: statusColor,
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
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
              const Spacer(),
              Text(
                '₹${ride.fare.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
