import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/providers/location_provider.dart';
import '../../core/providers/booking_provider.dart';
import '../../core/providers/address_provider.dart';
import '../../core/theme/app_colors.dart';
import 'search_destination_screen.dart';
import 'ride_history_screen.dart';
import 'wallet_screen.dart';
import 'support_screen.dart';
import 'profile_screen.dart';
import 'saved_addresses_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  GoogleMapController? _mapController;
  int _selectedIndex = 0;
  bool _isDraggingBottomSheet = false; // Track bottom sheet drag state
  bool _hasClearedRecentDestinations = false;

  // Ride options data
  final List<Map<String, dynamic>> rideOptions = const [
    {
      'name': 'Mini',
      'price': '₹89',
      'icon': Icons.directions_car,
      'color': Color(0xFF4A90E2),
    },
    {
      'name': 'Sedan',
      'price': '₹129',
      'icon': Icons.local_taxi,
      'color': Color(0xFFFF9500),
    },
    {
      'name': 'SUV',
      'price': '₹189',
      'icon': Icons.directions_car_filled,
      'color': Color(0xFF50E3C2),
    },
    {
      'name': 'Premium',
      'price': '₹299',
      'icon': Icons.car_rental,
      'color': Color(0xFFFFD300),
    },
    {
      'name': 'Auto',
      'price': '₹49',
      'icon': Icons.car_repair,
      'color': Color(0xFF4CD964),
    },
    {
      'name': 'Bike',
      'price': '₹29',
      'icon': Icons.two_wheeler,
      'color': Color(0xFFFF2D55),
    },
  ];

  // Saved Places
  final List<Map<String, dynamic>> savedPlaces = const [
    {
      'name': 'Home',
      'address': '123 Main Street, Chennai',
      'icon': Icons.home,
      'color': Color(0xFF4A90E2),
    },
    {
      'name': 'Work',
      'address': 'Tech Park, OMR, Chennai',
      'icon': Icons.work,
      'color': Color(0xFF9B59B6),
    },
    {
      'name': 'Favorites',
      'address': 'Marina Beach, Chennai',
      'icon': Icons.favorite,
      'color': Color(0xFFFF6B6B),
    },
  ];

  // Recent Destinations
  final List<Map<String, dynamic>> recentDestinations = const [
    {
      'name': 'T Nagar Shopping Complex',
      'address': 'T. Nagar, Chennai',
      'distance': '2.5 km',
      'duration': '10 min',
      'isFavorite': true,
    },
    {
      'name': 'Chennai Airport Terminal',
      'address': 'Meenambakkam, Chennai',
      'distance': '15 km',
      'duration': '35 min',
      'isFavorite': false,
    },
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _getCurrentLocation();
        Provider.of<BookingProvider>(context, listen: false).fetchRideHistory();
      }
    });
  }

  LatLng? _lastKnownPosition;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locationProvider = context.watch<LocationProvider>();
    final currentPosition = locationProvider.currentPosition;

    if (currentPosition != null && _mapController != null) {
      final newLatLng =
          LatLng(currentPosition.latitude, currentPosition.longitude);
      if (_lastKnownPosition == null ||
          _lastKnownPosition!.latitude != newLatLng.latitude ||
          _lastKnownPosition!.longitude != newLatLng.longitude) {
        _lastKnownPosition = newLatLng;
        _mapController!
            .animateCamera(CameraUpdate.newLatLngZoom(newLatLng, 16));
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    final locationProvider = context.read<LocationProvider>();
    final coords = await locationProvider.getCurrentLocation();
    if (coords != null) {
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(coords, 16));
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bookingProvider = context.watch<BookingProvider>();

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          // Home Screen (tab 0)
          Stack(
            children: [
              NotificationListener<DraggableScrollableNotification>(
                onNotification: (notification) {
                  setState(() {
                    _isDraggingBottomSheet = notification.extent > 0.55;
                  });
                  return true;
                },
                child: GoogleMap(
                  initialCameraPosition: const CameraPosition(
                    target: LatLng(11.0168, 76.9558),
                    zoom: 15,
                  ),
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomGesturesEnabled: !_isDraggingBottomSheet,
                  scrollGesturesEnabled: !_isDraggingBottomSheet,
                  rotateGesturesEnabled: !_isDraggingBottomSheet,
                  tiltGesturesEnabled: !_isDraggingBottomSheet,
                  onMapCreated: (controller) {
                    _mapController = controller;
                  },
                  markers: bookingProvider.nearbyDrivers.map((driver) {
                    return Marker(
                      markerId: MarkerId(driver.id),
                      position: LatLng(
                          driver.currentLocation[1], driver.currentLocation[0]),
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueOrange),
                      infoWindow: InfoWindow(title: driver.user.name),
                    );
                  }).toSet(),
                ),
              ),
              // Header
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: const BoxDecoration(
                                color: AppColors.secondary,
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: Text(
                                  'J',
                                  style: TextStyle(
                                    color: AppColors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Good Afternoon',
                                  style: TextStyle(
                                    color: AppColors.grey600,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  'John Doe',
                                  style: TextStyle(
                                    color: AppColors.black,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.notifications_none,
                            color: AppColors.secondary,
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Center Location Button
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.secondary.withValues(alpha: 0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.location_pin,
                    color: AppColors.white,
                    size: 36,
                  ),
                ),
              ),
              // Bottom Sheet (scrollable)
              DraggableScrollableSheet(
                initialChildSize: 0.6,
                minChildSize: 0.55,
                maxChildSize: 0.92,
                builder: (context, scrollController) {
                  return Container(
                    decoration: const BoxDecoration(
                      color: AppColors.white,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(32)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 20,
                          offset: Offset(0, -4),
                        ),
                      ],
                    ),
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 20),
                      children: [
                        // Drag handle
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: AppColors.grey300,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        // Search bar
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const SearchDestinationScreen(),
                              ),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.grey100,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 16),
                            child: const Row(
                              children: [
                                Icon(Icons.search, color: AppColors.primary),
                                SizedBox(width: 12),
                                Text(
                                  'Where are you going?',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: AppColors.grey600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Ride Options
                        ...rideOptions.map((ride) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.grey100,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                // Vehicle Image
                                Container(
                                  width: 70,
                                  height: 70,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      'https://picsum.photos/seed/${ride['name']}/200/200',
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return Container(
                                          decoration: BoxDecoration(
                                            color: ride['color'],
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Icon(
                                            ride['icon'],
                                            color: AppColors.white,
                                            size: 36,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // Details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        ride['name'],
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.black,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'For groups & luggage',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: AppColors.grey600,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(Icons.people,
                                              size: 16,
                                              color: AppColors.grey400),
                                          const SizedBox(width: 4),
                                          Text(
                                            '6 passengers',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppColors.grey400,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Icon(Icons.timer,
                                              size: 16,
                                              color: AppColors.grey400),
                                          const SizedBox(width: 4),
                                          Text(
                                            '13 min',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppColors.grey400,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                // Price
                                Text(
                                  ride['price'],
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.black,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        const SizedBox(height: 24),
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
                                'Add',
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
                            if (addressProvider.addresses.isEmpty) {
                              return Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: AppColors.grey100,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Center(
                                  child: Text(
                                    'No saved addresses yet. Tap "Add" to add one!',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: AppColors.grey600),
                                  ),
                                ),
                              );
                            }
                            return Column(
                              children:
                                  addressProvider.addresses.map((address) {
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
                                              address.label,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              address.address,
                                              style: const TextStyle(
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
                        const SizedBox(height: 24),
                        // Recent Destinations
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Recent Destinations',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (!_hasClearedRecentDestinations)
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _hasClearedRecentDestinations = true;
                                  });
                                },
                                child: const Text(
                                  'Clear',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: AppColors.grey600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                          ],
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
                                    'No recent destinations yet. Start booking rides!',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: AppColors.grey600),
                                  ),
                                ),
                              );
                            }

                            // Get completed rides as recent destinations
                            final completedRides = bookingProvider.rideHistory
                                .where((ride) => ['completed', 'cancelled']
                                    .contains(ride.status.toLowerCase()))
                                .toList()
                              ..sort((a, b) =>
                                  b.createdAt != null && a.createdAt != null
                                      ? b.createdAt!.compareTo(a.createdAt!)
                                      : 0);
                            // Take last 3
                            final recentRides = completedRides.take(3).toList();

                            if (recentRides.isEmpty) {
                              return Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: AppColors.grey100,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Center(
                                  child: Text(
                                    'No recent destinations yet. Start booking rides!',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: AppColors.grey600),
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
                                              ride.dropAddress,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              ride.distance != null
                                                  ? '${ride.distance!.toStringAsFixed(1)} km • 10 min'
                                                  : 'N/A',
                                              style: const TextStyle(
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
                      ],
                    ),
                  );
                },
              ),
            ],
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
            BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Home'),
            BottomNavigationBarItem(
                icon: Icon(Icons.history_outlined),
                activeIcon: Icon(Icons.history),
                label: 'Activity'),
            BottomNavigationBarItem(
                icon: Icon(Icons.account_balance_wallet_outlined),
                activeIcon: Icon(Icons.account_balance_wallet),
                label: 'Wallet'),
            BottomNavigationBarItem(
                icon: Icon(Icons.headset_mic_outlined),
                activeIcon: Icon(Icons.headset_mic),
                label: 'Support'),
            BottomNavigationBarItem(
                icon: Icon(Icons.person_outlined),
                activeIcon: Icon(Icons.person),
                label: 'Profile'),
          ],
        ),
      ),
    );
  }
}
