import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/ride_viewmodel.dart';
import '../../models/driver_models.dart';

class RecentActivityScreen extends StatefulWidget {
  const RecentActivityScreen({super.key});

  @override
  State<RecentActivityScreen> createState() => _RecentActivityScreenState();
}

class _RecentActivityScreenState extends State<RecentActivityScreen> {
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).iconTheme.color ?? const Color(0xFF1A1A1A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Recent Activity',
          style: TextStyle(
            color: Theme.of(context).textTheme.titleLarge?.color ?? const Color(0xFF1A1A1A),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Consumer<RideViewModel>(
        builder: (context, rideViewModel, child) {
          if (rideViewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (rideViewModel.error != null && rideViewModel.rideHistory.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${rideViewModel.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => rideViewModel.fetchRideHistory(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (rideViewModel.rideHistory.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No rides yet!',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: rideViewModel.rideHistory.length,
            itemBuilder: (context, index) {
              final ride = rideViewModel.rideHistory[index];
              return _buildActivityCard(ride);
            },
          );
        },
      ),
    );
  }

  Widget _buildActivityCard(RideRequestModel ride) {
    final List<Color> avatarColors = [
      Colors.amber,
      Colors.orange,
      Colors.blue,
      Colors.teal,
      Colors.purple,
      Colors.pink,
    ];

    final colorIndex = ride.id.hashCode % avatarColors.length;
    final avatarColor = avatarColors[colorIndex];

    // Format time
    String time = 'Unknown';
    if (ride.createdAt != null) {
      time = '${ride.createdAt!.day}/${ride.createdAt!.month}/${ride.createdAt!.year}, ${ride.createdAt!.hour}:${ride.createdAt!.minute.toString().padLeft(2, '0')}';
    }

    // Format distance
    String distance = ride.distance > 0 ? '${ride.distance.toStringAsFixed(1)} km' : 'Unknown';
    String duration = ride.estimatedTime > 0 ? '${ride.estimatedTime} min' : 'Unknown';

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: avatarColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.person_outline, color: avatarColor, size: 28),
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
                        fontSize: 17,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    Text(
                      time,
                      style: TextStyle(color: Colors.grey[500], fontSize: 13),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${ride.fare.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Color(0xFF2EBD59),
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 14),
                      Text(
                        " 5",
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  const SizedBox(height: 4),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2EBD59),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 35,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                    ),
                  ),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF8A00),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "PICKUP",
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      ride.pickupAddress,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 18),
                    Text(
                      "DROP",
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      ride.dropAddress,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(height: 1),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                distance,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Text("•", style: TextStyle(color: Colors.grey)),
              ),
              Text(
                duration,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
