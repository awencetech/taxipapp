import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../viewmodels/ride_viewmodel.dart';
import '../../models/driver_models.dart';

class RidesScreen extends StatefulWidget {
  const RidesScreen({super.key});

  @override
  State<RidesScreen> createState() => _RidesScreenState();
}

class _RidesScreenState extends State<RidesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RideViewModel>().fetchRideHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Ride History',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFFFF6D00),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await context.read<RideViewModel>().fetchRideHistory();
        },
        child: Consumer<RideViewModel>(
          builder: (context, rideViewModel, child) {
            if (rideViewModel.isLoading && rideViewModel.rideHistory.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (rideViewModel.error != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(rideViewModel.error!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => rideViewModel.fetchRideHistory(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6D00),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            if (rideViewModel.rideHistory.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.history, size: 80, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text(
                      'No ride history found.',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: rideViewModel.rideHistory.length,
              itemBuilder: (context, index) {
                final ride = rideViewModel.rideHistory[index];
                return _buildRideCard(ride);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildRideCard(RideRequestModel ride) {
    String? dateStr;
    String? timeStr;
    if (ride.createdAt != null) {
      final createdAt = ride.createdAt!;
      dateStr = DateFormat('MMM dd, yyyy').format(createdAt);
      timeStr = DateFormat('hh:mm a').format(createdAt);
    }

    // Get status color and icon
    Color statusColor;
    IconData statusIcon;
    String statusText = ride.status.toUpperCase();

    switch (ride.status.toLowerCase()) {
      case 'completed':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      case 'accepted':
        statusColor = Colors.blue;
        statusIcon = Icons.directions_car;
        break;
      case 'started':
        statusColor = Colors.orange;
        statusIcon = Icons.navigation;
        break;
      case 'arrived':
        statusColor = Colors.teal;
        statusIcon = Icons.location_on;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  ride.passengerName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Column(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                  Container(width: 2, height: 40, color: Colors.grey[300]),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'PICKUP',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          ride.pickupAddress,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'DROP',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          ride.dropAddress,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (dateStr != null)
                      Text(
                        dateStr,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    if (timeStr != null)
                      Text(
                        timeStr,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                  ],
                ),
              ),
              Text(
                '₹${ride.fare.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFF6D00),
                ),
              ),
            ],
          ),
          if (ride.cancellationReason != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.grey, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      ride.cancellationReason!,
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
