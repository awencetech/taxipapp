import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/trip_viewmodel.dart';
import '../../models/vendor_models.dart';

class TripsScreen extends StatelessWidget {
  const TripsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tripVM = context.watch<TripViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trips'),
      ),
      body: RefreshIndicator(
        onRefresh: () => tripVM.fetchTrips(),
        child: _buildTripsList(tripVM),
      ),
    );
  }

  Widget _buildTripsList(TripViewModel tripVM) {
    if (tripVM.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (tripVM.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                tripVM.errorMessage!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => tripVM.fetchTrips(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (tripVM.trips.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.local_taxi_outlined, size: 80, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No trips yet',
                style: TextStyle(fontSize: 18),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tripVM.trips.length,
      itemBuilder: (context, index) {
        final trip = tripVM.trips[index];
        return _buildTripCard(context, trip);
      },
    );
  }

  Widget _buildTripCard(BuildContext context, Trip trip) {
    Color statusColor;
    switch (trip.status) {
      case 'completed':
        statusColor = Colors.green;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        break;
      case 'ongoing':
        statusColor = Colors.blue;
        break;
      default:
        statusColor = Colors.orange;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Chip(
                  label: Text(
                    trip.status,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                  backgroundColor: statusColor,
                ),
                Text(
                  '₹${trip.fare.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.green),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    trip.pickupAddress ?? 'Unknown Pickup',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    trip.dropAddress ?? 'Unknown Drop',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.route, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  '${trip.distance.toStringAsFixed(1)} km',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
