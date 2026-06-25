import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/providers/location_provider.dart';
import '../../core/providers/booking_provider.dart';
import '../../core/providers/address_provider.dart';
import '../../core/providers/notification_provider.dart';
import '../../core/theme/app_colors.dart';
import 'location_selection_screen.dart';
import 'ride_history_screen.dart';
import 'wallet_screen.dart';
import 'support_screen.dart';
import 'profile_screen.dart';
import 'saved_addresses_screen.dart';
import 'notifications_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _hasClearedRecentDestinations = false;
  GoogleMapController? _mapController;

  // Vehicle options data
  final List<Map<String, dynamic>> vehicleOptions = const [
    {
      'name': 'Mini',
      'startingPrice': '₹80',
      'icon': Icons.directions_car,
      'color': Color(0xFF4A90E2),
      'eta': '2 mins',
    },
    {
      'name': 'Sedan',
      'startingPrice': '₹120',
      'icon': Icons.directions_car_filled,
      'color': Color(0xFFFF9500),
      'eta': '3 mins',
    },
    {
      'name': 'SUV',
      'startingPrice': '₹180',
      'icon': Icons.airport_shuttle,
      'color': Color(0xFF50E3C2),
      'eta': '5 mins',
    },
    {
      'name': 'Auto',
      'startingPrice': '₹50',
      'icon': Icons.local_taxi,
      'color': Color(0xFF4CD964),
      'eta': '1 min',
    },
    {
      'name': 'Bike',
      'startingPrice': '₹40',
      'icon': Icons.motorcycle,
      'color': Color(0xFFFF2D55),
      'eta': '1 min',
    },
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<BookingProvider>(context, listen: false).fetchRideHistory();
        Provider.of<NotificationProvider>(context, listen: false)
            .fetchNotifications();
      }
    });
  }

  Future<void> _goToCurrentLocation() async {
    final locationProvider = context.read<LocationProvider>();
    final position = await locationProvider.getCurrentLocation();
    if (position != null && _mapController != null) {
      _mapController!.animateCamera(CameraUpdate.newLatLngZoom(position, 16));
    }
  }

  Widget _buildVehicleTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildBrandItem(String emoji, String text) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          emoji,
          style: const TextStyle(fontSize: 24),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            color: AppColors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          // Home Screen (tab 0)
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Container with max width 1200px
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Consumer<NotificationProvider>(
                            builder: (context, notificationProvider, child) {
                              return Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'TAXI NANBAN',
                                    style: TextStyle(
                                      fontSize: 30,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.black,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const NotificationsListScreen(),
                                        ),
                                      );
                                    },
                                    child: Stack(
                                      children: [
                                        Container(
                                          width: 48,
                                          height: 48,
                                          decoration: BoxDecoration(
                                            color: AppColors.white,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            boxShadow: const [
                                              BoxShadow(
                                                color: Colors.black12,
                                                blurRadius: 8,
                                                offset: Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: const Icon(
                                            Icons.notifications,
                                            color: AppColors.secondary,
                                            size: 24,
                                          ),
                                        ),
                                        if (notificationProvider.unreadCount >
                                            0)
                                          Positioned(
                                            right: 0,
                                            top: 0,
                                            child: Container(
                                              width: 20,
                                              height: 20,
                                              decoration: BoxDecoration(
                                                color: Colors.red,
                                                shape: BoxShape.circle,
                                              ),
                                              child: Center(
                                                child: Text(
                                                  notificationProvider
                                                              .unreadCount >
                                                          9
                                                      ? '9+'
                                                      : '${notificationProvider.unreadCount}',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 24),
                          // Map Section
                          Container(
                            height: 320,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 16,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Stack(
                                children: [
                                  GoogleMap(
                                    initialCameraPosition: const CameraPosition(
                                      target: LatLng(11.0168, 76.9558),
                                      zoom: 15,
                                    ),
                                    myLocationEnabled: true,
                                    myLocationButtonEnabled: false,
                                    zoomControlsEnabled: false,
                                    scrollGesturesEnabled: true,
                                    zoomGesturesEnabled: true,
                                    rotateGesturesEnabled: false,
                                    tiltGesturesEnabled: false,
                                    onMapCreated: (controller) {
                                      _mapController = controller;
                                      _goToCurrentLocation();
                                    },
                                  ),
                                  Positioned(
                                    bottom: 16,
                                    right: 16,
                                    child: GestureDetector(
                                      onTap: _goToCurrentLocation,
                                      child: Container(
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFF6B00),
                                          shape: BoxShape.circle,
                                          boxShadow: const [
                                            BoxShadow(
                                              color: Colors.black12,
                                              blurRadius: 8,
                                              offset: Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.my_location,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Where To? Search Field
                          Consumer<LocationProvider>(
                            builder: (context, locationProvider, child) {
                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const LocationSelectionScreen(),
                                    ),
                                  );
                                },
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 16),
                                  decoration: BoxDecoration(
                                    color: AppColors.grey100,
                                    borderRadius: BorderRadius.circular(16),
                                    border:
                                        Border.all(color: AppColors.grey300),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.search,
                                        color: AppColors.primary,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          locationProvider
                                                  .currentAddress.isNotEmpty
                                              ? locationProvider.currentAddress
                                              : 'Where to?',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: locationProvider
                                                    .currentAddress.isNotEmpty
                                                ? AppColors.black
                                                : AppColors.grey600,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 24),
                          // Vehicle Selection
                          const Text(
                            'Choose a Vehicle',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.black,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Horizontal vehicle cards
                          SizedBox(
                            height: 160,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: vehicleOptions.length,
                              itemBuilder: (context, index) {
                                final vehicle = vehicleOptions[index];
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            LocationSelectionScreen(
                                          selectedVehicle: vehicle['name'],
                                        ),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    width: 160,
                                    margin: EdgeInsets.only(
                                      right: index == vehicleOptions.length - 1
                                          ? 0
                                          : 16,
                                    ),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: AppColors.grey100,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              width: 44,
                                              height: 44,
                                              decoration: BoxDecoration(
                                                color: vehicle['color'],
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Icon(
                                                vehicle['icon'],
                                                color: AppColors.white,
                                                size: 24,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          vehicle['name'],
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.black,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Starting ${vehicle['startingPrice']}',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: AppColors.grey600,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${vehicle['eta']} away',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.secondary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 32),
                          // Recent Rides
                          const Text(
                            'Recent Rides',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.black,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Consumer<BookingProvider>(
                            builder: (context, bookingProvider, child) {
                              if (_hasClearedRecentDestinations) {
                                return Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: AppColors.grey100,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      'No recent rides yet. Start booking!',
                                      textAlign: TextAlign.center,
                                      style:
                                          TextStyle(color: AppColors.grey600),
                                    ),
                                  ),
                                );
                              }

                              final List completedRides = [];
                              try {
                                if (bookingProvider.rideHistory.isNotEmpty) {
                                  completedRides.addAll(
                                    bookingProvider.rideHistory.where((ride) {
                                      final status = ride.status.toLowerCase();
                                      return ['completed', 'cancelled']
                                          .contains(status);
                                    }).toList()
                                      ..sort((a, b) {
                                        if (a.createdAt == null ||
                                            b.createdAt == null) {
                                          return 0;
                                        }
                                        return b.createdAt!
                                            .compareTo(a.createdAt!);
                                      }),
                                  );
                                }
                              } catch (e) {
                                // Handle any errors
                              }

                              final recentRides =
                                  completedRides.take(3).toList();

                              if (recentRides.isEmpty) {
                                return Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: AppColors.grey100,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      'No recent rides yet. Start booking!',
                                      textAlign: TextAlign.center,
                                      style:
                                          TextStyle(color: AppColors.grey600),
                                    ),
                                  ),
                                );
                              }
                              return Column(
                                children: recentRides.map((ride) {
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
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
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 52,
                                          height: 52,
                                          decoration: const BoxDecoration(
                                            color: AppColors.grey100,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.location_pin,
                                              color: AppColors.secondary,
                                              size: 28),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                ride.dropAddress ??
                                                    'Unknown destination',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                ride.distance != null
                                                    ? '${ride.distance!.toStringAsFixed(1)} km • ${ride.status ?? 'Unknown'}'
                                                    : 'N/A',
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
                                  );
                                }).toList(),
                              );
                            },
                          ),
                          const SizedBox(height: 32),
                          // Saved Places
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Saved Places',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const SavedAddressesScreen(),
                                    ),
                                  );
                                },
                                child: const Text(
                                  'Add Place',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: AppColors.secondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Consumer<AddressProvider>(
                            builder: (context, addressProvider, child) {
                              final List addresses = [];
                              try {
                                if (addressProvider.addresses.isNotEmpty) {
                                  addresses.addAll(addressProvider.addresses);
                                }
                              } catch (e) {
                                // Handle any errors
                              }

                              if (addresses.isEmpty) {
                                return Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: AppColors.grey100,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      'No saved places yet. Tap "Add Place"!',
                                      textAlign: TextAlign.center,
                                      style:
                                          TextStyle(color: AppColors.grey600),
                                    ),
                                  ),
                                );
                              }
                              return Column(
                                children: addresses.map((address) {
                                  IconData icon;
                                  Color color;
                                  switch (address.type) {
                                    case 'home':
                                      icon = Icons.home;
                                      color = AppColors.secondary;
                                      break;
                                    case 'work':
                                      icon = Icons.work;
                                      color = const Color(0xFF4A90E2);
                                      break;
                                    default:
                                      icon = Icons.location_on;
                                      color = const Color(0xFF9B59B6);
                                      break;
                                  }
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: AppColors.grey100,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 52,
                                          height: 52,
                                          decoration: BoxDecoration(
                                            color: color,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            icon,
                                            color: AppColors.white,
                                            size: 28,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                address.label ?? 'No label',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                address.address ?? 'No address',
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
                                  );
                                }).toList(),
                              );
                            },
                          ),
                          const SizedBox(height: 32),
                          // Promotional Banner
                          Container(
                            height: 240,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFF6B00), Color(0xFFFF8A00)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 16,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 20),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.local_taxi,
                                  color: Colors.white,
                                  size: 50,
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'FIRST RIDE FREE!',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Use Coupon: TAXINANBANFREE',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _buildVehicleTag('Auto'),
                                    const SizedBox(width: 12),
                                    _buildVehicleTag('Bike'),
                                    const SizedBox(width: 12),
                                    _buildVehicleTag('Mini'),
                                    const SizedBox(width: 12),
                                    _buildVehicleTag('Sedan'),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Brand Information
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: AppColors.grey100,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  '#goTaxiNanban',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _buildBrandItem('🇮🇳', 'Made for India'),
                                const SizedBox(height: 12),
                                _buildBrandItem('❤️', 'Crafted in Tamil Nadu'),
                                const SizedBox(height: 12),
                                _buildBrandItem(
                                    '🚖', 'Safe and Reliable Rides'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Activity Screen (tab 1)
          const RideHistoryScreen(),
          // Wallet Screen (tab 2)
          const WalletScreen(),
          // Support Screen (tab 3)
          const SupportScreen(),
          // Profile Screen (tab 4)
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          backgroundColor: AppColors.card,
          selectedItemColor: AppColors.secondary,
          unselectedItemColor: AppColors.mutedForeground,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(
                icon: Icon(Icons.history), label: 'Activity'),
            BottomNavigationBarItem(
                icon: Icon(Icons.account_balance_wallet), label: 'Wallet'),
            BottomNavigationBarItem(
                icon: Icon(Icons.support_agent), label: 'Support'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}
