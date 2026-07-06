import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/theme_viewmodel.dart';
import '../../viewmodels/trip_viewmodel.dart';
import '../../models/vendor_models.dart';
import '../dashboard/dashboard_screen.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  String _selectedTab = 'All Bookings';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {});
    });
    // Fetch trips when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TripViewModel>().fetchTrips();
    });
  }

  List<Trip> _filteredTrips(List<Trip> trips) {
    final query = _searchController.text.toLowerCase();
    return trips.where((trip) {
      // Check tab
      bool matchesTab = false;
      switch (_selectedTab) {
        case 'All Bookings':
          matchesTab = true;
          break;
        case 'Live Trips':
          matchesTab = ['searching', 'accepted', 'arrived', 'trip_started', 'ongoing']
              .contains(trip.status.toLowerCase());
          break;
        case 'Scheduled':
          matchesTab = trip.status.toLowerCase() == 'scheduled';
          break;
        case 'Completed':
          matchesTab = trip.status.toLowerCase() == 'completed';
          break;
        case 'Cancelled':
          matchesTab = ['cancelled', 'canceled'].contains(trip.status.toLowerCase());
          break;
      }
      
      // Check search
      bool matchesSearch = query.isEmpty;
      if (!matchesSearch) {
        final passengerName = trip.user?.name?.toLowerCase() ?? '';
        final bookingId = trip.id.toLowerCase();
        final pickup = trip.pickupAddress?.toLowerCase() ?? '';
        final dropoff = trip.dropAddress?.toLowerCase() ?? '';
        
        matchesSearch = passengerName.contains(query) ||
            bookingId.contains(query) ||
            pickup.contains(query) ||
            dropoff.contains(query);
      }
      
      return matchesTab && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final themeVM = context.watch<ThemeViewModel>();
    final tripVM = context.watch<TripViewModel>();
    final isDark = themeVM.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF0F4FF),
      body: SafeArea(
        bottom: false,
        child: tripVM.isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Section
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.only(top: 20, left: 20, right: 20, bottom: 24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            isDark ? const Color(0xFF0D1B2A) : const Color(0xFF1D2951),
                            isDark ? const Color(0xFF1B263B) : const Color(0xFF2D4A6D),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(32),
                          bottomRight: Radius.circular(32),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          IconButton(
                            onPressed: () {
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(builder: (context) => const DashboardScreen()),
                                (route) => false,
                              );
                            },
                            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Booking Management',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Track and manage all ride bookings',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Stats Cards
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          _buildStatCard(
                            title: 'Completed Bookings',
                            value: tripVM.trips
                                .where((t) => t.status.toLowerCase() == 'completed')
                                .length
                                .toString(),
                            icon: Icons.calendar_today,
                            color: const Color(0xFF22C55E),
                            bgColor: const Color(0xFFE8F5E9),
                            isDark: isDark,
                          ),
                          const SizedBox(height: 12),
                          _buildStatCard(
                            title: 'Ongoing Trips',
                            value: tripVM.trips
                                .where((t) => ['searching', 'accepted', 'arrived', 'trip_started', 'ongoing']
                                    .contains(t.status.toLowerCase()))
                                .length
                                .toString(),
                            icon: Icons.calendar_today,
                            color: const Color(0xFF3B82F6),
                            bgColor: const Color(0xFFE3F2FD),
                            isDark: isDark,
                          ),
                          const SizedBox(height: 12),
                          _buildStatCard(
                            title: 'Scheduled Trips',
                            value: tripVM.trips
                                .where((t) => t.status.toLowerCase() == 'scheduled')
                                .length
                                .toString(),
                            icon: Icons.calendar_today,
                            color: const Color(0xFFF59E0B),
                            bgColor: const Color(0xFFFFF3E0),
                            isDark: isDark,
                          ),
                          const SizedBox(height: 12),
                          _buildStatCard(
                            title: 'Cancelled Bookings',
                            value: tripVM.trips
                                .where((t) => ['cancelled', 'canceled'].contains(t.status.toLowerCase()))
                                .length
                                .toString(),
                            icon: Icons.calendar_today,
                            color: const Color(0xFFEF4444),
                            bgColor: const Color(0xFFFFEBEE),
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Search & Filter
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.search, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                style: TextStyle(
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Search bookings...',
                                  hintStyle: TextStyle(
                                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Refresh Button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: OutlinedButton.icon(
                        onPressed: () {
                          tripVM.fetchTrips();
                        },
                        icon: const Icon(Icons.refresh, color: Color(0xFF6B7280)),
                        label: const Text(
                          'Refresh',
                          style: TextStyle(
                            color: Color(0xFF6B7280),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          side: BorderSide(color: Colors.grey[300]!),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Tabs
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: ['All Bookings', 'Live Trips', 'Scheduled', 'Completed', 'Cancelled']
                              .map((tab) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedTab = tab;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: _selectedTab == tab
                                        ? const Color(0xFFFF7A00)
                                        : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: Text(
                                    tab,
                                    style: TextStyle(
                                      color: _selectedTab == tab
                                          ? Colors.white
                                          : (isDark ? Colors.grey[400] : Colors.grey[600]),
                                      fontWeight:
                                          _selectedTab == tab ? FontWeight.bold : FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Bookings List
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _filteredTrips(tripVM.trips).isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32.0),
                                child: Text(
                                  'No bookings found',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                                  ),
                                ),
                              ),
                            )
                          : Column(
                              children: _filteredTrips(tripVM.trips).map((trip) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _buildBookingCard(trip, isDark),
                                );
                              }).toList(),
                            ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required bool isDark,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.transparent : Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.grey[300] : Colors.grey[600],
            ),
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? color.withValues(alpha: 0.2) : bgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                value,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(Trip trip, bool isDark) {
    // Determine status color and display text
    Color statusColor;
    String statusText;
    switch (trip.status.toLowerCase()) {
      case 'completed':
        statusColor = const Color(0xFF22C55E);
        statusText = 'Completed';
        break;
      case 'searching':
      case 'accepted':
      case 'arrived':
      case 'trip_started':
      case 'ongoing':
        statusColor = const Color(0xFF3B82F6);
        statusText = 'Ongoing';
        break;
      case 'scheduled':
        statusColor = const Color(0xFFF59E0B);
        statusText = 'Scheduled';
        break;
      case 'cancelled':
      case 'canceled':
        statusColor = const Color(0xFFEF4444);
        statusText = 'Cancelled';
        break;
      default:
        statusColor = const Color(0xFF6B7280);
        statusText = trip.status;
    }

    // Format time
    String timeText = '';
    final time = trip.createdAt;
    timeText = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

    // Format fare and distance
    String fareText = trip.fare > 0 ? '₹${trip.fare.toStringAsFixed(0)}' : '₹0';
    String distanceText = '${trip.distance.toStringAsFixed(1)} km';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.transparent : Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFECD2),
                      shape: BoxShape.circle,
                    ),
                    child: trip.user?.profilePic != null
                        ? ClipOval(
                            child: Image.network(
                              trip.user!.profilePic!,
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.person,
                                  color: Color(0xFFFF7A00),
                                  size: 28,
                                );
                              },
                            ),
                          )
                        : const Icon(
                            Icons.person,
                            color: Color(0xFFFF7A00),
                            size: 28,
                          ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trip.user?.name ?? 'Unknown Passenger',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      Text(
                        'Booking ID: ${trip.id.substring(0, 8)}',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 12,
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Pickup & Dropoff
          Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.location_pin, color: Color(0xFF22C55E), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Pickup',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(left: 28, top: 4),
                child: Text(
                  trip.pickupAddress ?? 'N/A',
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  const Icon(Icons.location_pin, color: Color(0xFFEF4444), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Dropoff',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(left: 28, top: 4),
                child: Text(
                  trip.dropAddress ?? 'N/A',
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Trip Details
          Row(
            children: [
              Icon(Icons.access_time, color: isDark ? Colors.grey[400] : Colors.grey[600], size: 18),
              const SizedBox(width: 8),
              Text(
                timeText,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.grey[300] : Colors.grey[700],
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              const Icon(Icons.attach_money, color: Color(0xFFFF7A00), size: 18),
              const SizedBox(width: 8),
              Text(
                '$fareText • $distanceText',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFF7A00),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Divider
          Container(
            height: 1,
            color: isDark ? Colors.grey[800] : Colors.grey[200],
          ),

          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
