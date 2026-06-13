import 'package:flutter/material.dart';

class RecentActivityScreen extends StatelessWidget {
  const RecentActivityScreen({super.key});

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
            fontWeight: FontWeight.bold
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildActivityCard(
            name: "Priya Sharma",
            time: "Today, 2:30 PM",
            pickup: "MG Road Metro Station",
            drop: "Koramangala 5th Block",
            fare: "₹285",
            rating: "5",
            distance: "8.5 km",
            duration: "22 min",
            avatarColor: Colors.amber,
          ),
          _buildActivityCard(
            name: "Amit Patel",
            time: "Today, 12:15 PM",
            pickup: "Whitefield Main Road",
            drop: "Electronic City Phase 1",
            fare: "₹420",
            rating: "4",
            distance: "14.2 km",
            duration: "35 min",
            avatarColor: Colors.orange,
          ),
          _buildActivityCard(
            name: "Sneha Reddy",
            time: "Yesterday, 6:00 PM",
            pickup: "Indiranagar 100 Feet Road",
            drop: "Bangalore Airport",
            fare: "₹650",
            rating: "5",
            distance: "22.8 km",
            duration: "45 min",
            avatarColor: Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard({
    required String name,
    required String time,
    required String pickup,
    required String drop,
    required String fare,
    required String rating,
    required String distance,
    required String duration,
    required Color avatarColor,
  }) {
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
                      name,
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
                    fare,
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
                        " $rating",
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
                      pickup,
                      style: const TextStyle(
                        fontSize: 15, 
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
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
                      drop,
                      style: const TextStyle(
                        fontSize: 15, 
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
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

