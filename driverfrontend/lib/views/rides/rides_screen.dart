import 'package:flutter/material.dart';
import '../home/home_screen.dart';

class RidesScreen extends StatefulWidget {
  const RidesScreen({super.key});

  @override
  State<RidesScreen> createState() => _RidesScreenState();
}

class TripRecord {
  final String name;
  final String time;
  final DateTime dateTime;
  final String pickup;
  final String drop;
  final double fare;
  final double rating;
  final double distance;
  final String duration;
  final Color avatarColor;

  TripRecord({
    required this.name,
    required this.time,
    required this.dateTime,
    required this.pickup,
    required this.drop,
    required this.fare,
    required this.rating,
    required this.distance,
    required this.duration,
    required this.avatarColor,
  });
}

class _RidesScreenState extends State<RidesScreen> {
  String _selectedTab = 'Today';
  String _sortBy = 'Newest'; // 'Newest', 'Fare (High-Low)', 'Fare (Low-High)', 'Distance'

  final List<TripRecord> _allTrips = [
    TripRecord(
      name: "Priya Sharma",
      time: "Today, 2:30 PM",
      dateTime: DateTime.now().subtract(const Duration(hours: 2)),
      pickup: "MG Road Metro Station",
      drop: "Koramangala 5th Block",
      fare: 285.0,
      rating: 5.0,
      distance: 8.5,
      duration: "22 min",
      avatarColor: Colors.amber,
    ),
    TripRecord(
      name: "Amit Patel",
      time: "Today, 12:15 PM",
      dateTime: DateTime.now().subtract(const Duration(hours: 4)),
      pickup: "Whitefield Main Road",
      drop: "Electronic City Phase 1",
      fare: 420.0,
      rating: 4.0,
      distance: 14.2,
      duration: "35 min",
      avatarColor: Colors.orange,
    ),
    TripRecord(
      name: "Sneha Reddy",
      time: "Yesterday, 6:00 PM",
      dateTime: DateTime.now().subtract(const Duration(days: 1)),
      pickup: "Indiranagar 100 Feet Road",
      drop: "Bangalore Airport",
      fare: 650.0,
      rating: 5.0,
      distance: 32.4,
      duration: "55 min",
      avatarColor: Colors.blue,
    ),
    TripRecord(
      name: "Rahul Verma",
      time: "2 days ago, 10:00 AM",
      dateTime: DateTime.now().subtract(const Duration(days: 2)),
      pickup: "HSR Layout Sector 2",
      drop: "Jayanagar 4th Block",
      fare: 150.0,
      rating: 4.5,
      distance: 5.2,
      duration: "15 min",
      avatarColor: Colors.green,
    ),
  ];

  List<TripRecord> get _filteredTrips {
    List<TripRecord> trips = _allTrips.where((trip) {
      if (_selectedTab == 'Today') {
        return trip.dateTime.day == DateTime.now().day && 
               trip.dateTime.month == DateTime.now().month &&
               trip.dateTime.year == DateTime.now().year;
      } else if (_selectedTab == 'This Week') {
        return trip.dateTime.isAfter(DateTime.now().subtract(const Duration(days: 7)));
      } else {
        return trip.dateTime.isAfter(DateTime.now().subtract(const Duration(days: 30)));
      }
    }).toList();

    // Apply Sorting
    if (_sortBy == 'Newest') {
      trips.sort((a, b) => b.dateTime.compareTo(a.dateTime));
    } else if (_sortBy == 'Fare (High-Low)') {
      trips.sort((a, b) => b.fare.compareTo(a.fare));
    } else if (_sortBy == 'Fare (Low-High)') {
      trips.sort((a, b) => a.fare.compareTo(b.fare));
    } else if (_sortBy == 'Distance') {
      trips.sort((a, b) => b.distance.compareTo(a.distance));
    }

    return trips;
  }

  void _showFilterSheet() {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Sort & Filter',
                    style: TextStyle(
                      fontSize: 24, 
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: theme.colorScheme.onSurface),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'SORT BY',
                style: TextStyle(
                  fontSize: 12, 
                  fontWeight: FontWeight.bold, 
                  color: Colors.grey,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 16),
              _buildFilterOption(setSheetState, 'Newest', Icons.access_time),
              _buildFilterOption(setSheetState, 'Fare (High-Low)', Icons.trending_up),
              _buildFilterOption(setSheetState, 'Fare (Low-High)', Icons.trending_down),
              _buildFilterOption(setSheetState, 'Distance', Icons.map_outlined),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF8A00),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Apply Filters', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterOption(Function setSheetState, String value, IconData icon) {
    final theme = Theme.of(context);
    bool isSelected = _sortBy == value;
    return InkWell(
      onTap: () {
        setSheetState(() => _sortBy = value);
        setState(() => _sortBy = value);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? const Color(0xFFFF8A00) : Colors.grey, size: 20),
            const SizedBox(width: 16),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? const Color(0xFFFF8A00) : theme.colorScheme.onSurface,
              ),
            ),
            const Spacer(),
            if (isSelected)
              const Icon(Icons.check_circle, color: Color(0xFFFF8A00), size: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          // Top Header with Gradient
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 60, left: 24, right: 24, bottom: 40),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2D2D2D), Color(0xFFE65100)],
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                    onPressed: () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      } else {
                        HomeScreen.of(context)?.setSelectedIndex(0);
                      }
                    },
                  ),
                ),
                const Text(
                  'Trip History',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.tune, color: Colors.white, size: 20),
                    onPressed: _showFilterSheet,
                  ),
                ),
              ],
            ),
          ),

          // Custom Tab Switcher
          Container(
            margin: const EdgeInsets.all(24),
            height: 50,
            decoration: BoxDecoration(
              color: isDark ? theme.cardColor : const Color(0xFFEEEEEE),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Row(
              children: [
                _buildTabItem(context, 'Today'),
                _buildTabItem(context, 'This Week'),
                _buildTabItem(context, 'This Month'),
              ],
            ),
          ),

          Expanded(
            child: _filteredTrips.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No trips found',
                          style: TextStyle(color: Colors.grey[600], fontSize: 18),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: _filteredTrips.length + 1,
                    itemBuilder: (context, index) {
                      if (index == _filteredTrips.length) {
                        return const SizedBox(height: 100);
                      }
                      final trip = _filteredTrips[index];
                      return _buildTripCard(
                        name: trip.name,
                        time: trip.time,
                        pickup: trip.pickup,
                        drop: trip.drop,
                        fare: "₹${trip.fare.toInt()}",
                        rating: trip.rating.toString(),
                        distance: "${trip.distance} km",
                        duration: trip.duration,
                        avatarColor: trip.avatarColor,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem(BuildContext context, String label) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    bool isSelected = _selectedTab == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = label),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected 
                ? (isDark ? theme.colorScheme.primary : Colors.white) 
                : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected 
                  ? (isDark ? Colors.white : Colors.black) 
                  : (isDark ? Colors.grey[400] : Colors.grey[600]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTripCard({
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
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
                      style: TextStyle(
                        fontWeight: FontWeight.bold, 
                        fontSize: 17,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      time,
                      style: TextStyle(color: theme.hintColor, fontSize: 13),
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
                      color: Color(0xFF2EBD59), // Matched green
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 14),
                      Text(
                        " $rating",
                        style: TextStyle(
                          fontSize: 13, 
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Route Details
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
                      color: theme.dividerColor,
                      border: Border.all(color: theme.dividerColor, width: 0.5),
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
                        color: theme.hintColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      pickup,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      "DROP-OFF",
                      style: TextStyle(
                        color: theme.hintColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      drop,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Stats Row
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTripStat(Icons.directions, distance, "Distance"),
                _buildTripStat(Icons.access_time, duration, "Duration"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripStat(IconData icon, String value, String label) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, color: theme.hintColor, size: 16),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            Text(
              label,
              style: TextStyle(color: theme.hintColor, fontSize: 10),
            ),
          ],
        ),
      ],
    );
  }


}


