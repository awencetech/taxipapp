import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import '../../core/providers/location_provider.dart';
import '../../core/providers/booking_provider.dart';
import '../../core/providers/address_provider.dart';
import '../../core/providers/notification_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/models/ride_model.dart';
import 'location_selection_screen.dart';
import 'ride_history_screen.dart';
import 'ride_details_screen.dart';
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
  final bool _hasClearedRecentDestinations = false;
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Circle> _circles = {};
  MapType _currentMapType = MapType.normal;

  // Vehicle options data
  final List<Map<String, dynamic>> vehicleOptions = const [
    {
      'name': 'Mini',
      'startingPrice': '₹80',
      'imageUrl':
          'https://images.unsplash.com/photo-1549317661-bd32c8ce0db2?w=400&auto=format&fit=crop&q=80',
      'color': Color(0xFF4A90E2),
      'eta': '2 mins',
    },
    {
      'name': 'Sedan',
      'startingPrice': '₹120',
      'imageUrl':
          'https://images.unsplash.com/photo-1580273916550-e323be2ae537?w=400&auto=format&fit=crop&q=80',
      'color': Color(0xFFFF9500),
      'eta': '3 mins',
    },
    {
      'name': 'SUV',
      'startingPrice': '₹180',
      'imageUrl':
          'https://images.unsplash.com/photo-1519641471654-76ce0107ad1b?w=400&auto=format&fit=crop&q=80',
      'color': Color(0xFF50E3C2),
      'eta': '5 mins',
    },
    {
      'name': 'Auto',
      'startingPrice': '₹50',
      'imageUrl':
          'https://images.unsplash.com/photo-1604712042546-7a9b125b0b76?w=400&auto=format&fit=crop&q=80',
      'color': Color(0xFF4CD964),
      'eta': '1 min',
    },
    {
      'name': 'Bike',
      'startingPrice': '₹40',
      'imageUrl':
          'https://images.unsplash.com/photo-1558981403-c5f9899a28bc?w=400&auto=format&fit=crop&q=80',
      'color': Color(0xFFFF2D55),
      'eta': '1 min',
    },
  ];

  late LocationProvider _locationProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<BookingProvider>(context, listen: false).fetchRideHistory();
        Provider.of<NotificationProvider>(context, listen: false)
            .fetchNotifications();
        _locationProvider =
            Provider.of<LocationProvider>(context, listen: false);
        _locationProvider.addListener(_onLocationChanged);
      }
    });
  }

  void _onLocationChanged() {
    if (mounted) {
      _updateMarkersAndCircles();
    }
  }

  @override
  void dispose() {
    _locationProvider.removeListener(_onLocationChanged);
    super.dispose();
  }

  Future<void> _goToCurrentLocation() async {
    final locationProvider =
        Provider.of<LocationProvider>(context, listen: false);
    final position = await locationProvider.getCurrentLocation();
    if (position != null) {
      await _animateToPosition(position);
    }
  }

  Future<void> _animateToPosition(LatLng position) async {
    if (_mapController != null) {
      await _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: position,
            zoom: 17,
            tilt: 45,
            bearing: 0,
          ),
        ),
      );
    }
  }

  void _updateMarkersAndCircles() {
    final locationProvider =
        Provider.of<LocationProvider>(context, listen: false);

    if (locationProvider.currentPosition != null) {
      final position = LatLng(
        locationProvider.currentPosition!.latitude,
        locationProvider.currentPosition!.longitude,
      );

      // Update user marker
      if (mounted) {
        setState(() {
          _markers = {
            Marker(
              markerId: const MarkerId('user_location'),
              position: position,
              infoWindow: const InfoWindow(title: 'You are here'),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueBlue),
            ),
          };

          // Update accuracy circle
          _circles = {
            Circle(
              circleId: const CircleId('accuracy'),
              center: position,
              radius: locationProvider.currentPosition!.accuracy,
              fillColor: Colors.blue.withValues(alpha: 0.1),
              strokeColor: Colors.blue.withValues(alpha: 0.5),
              strokeWidth: 1,
            ),
          };
        });
      }

      // Auto-follow if enabled
      if (locationProvider.autoFollow) {
        _animateToPosition(position);
      }
    } else {
      // If no position, set empty sets
      if (mounted) {
        setState(() {
          _markers = {};
          _circles = {};
        });
      }
    }
  }

  void _onCameraMove(CameraPosition position) {
    // Disable auto-follow when user manually moves the map
    final locationProvider =
        Provider.of<LocationProvider>(context, listen: false);
    if (locationProvider.autoFollow) {
      locationProvider.setAutoFollow(false);
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
          Stack(
            children: [
              // Fixed Map Section
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header
                        Consumer<NotificationProvider>(
                          builder: (context, notificationProvider, child) {
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFFFF6B00),
                                            Color(0xFFFF8A00)
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Color(0x33FF6B00),
                                            blurRadius: 8,
                                            offset: Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.local_taxi,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    RichText(
                                      text: const TextSpan(
                                        children: [
                                          TextSpan(
                                            text: 'TAXI',
                                            style: TextStyle(
                                              fontSize: 28,
                                              fontWeight: FontWeight.w900,
                                              color: Color(0xFF111827),
                                              letterSpacing: -0.5,
                                            ),
                                          ),
                                          TextSpan(
                                            text: ' ',
                                          ),
                                          TextSpan(
                                            text: 'NANBAN',
                                            style: TextStyle(
                                              fontSize: 28,
                                              fontWeight: FontWeight.w900,
                                              color: Color(0xFFFF6B00),
                                              letterSpacing: -0.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
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
                                      if (notificationProvider.unreadCount > 0)
                                        Positioned(
                                          right: 0,
                                          top: 0,
                                          child: Container(
                                            width: 20,
                                            height: 20,
                                            decoration: const BoxDecoration(
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
                        const SizedBox(height: 16),
                        // Map
                        Container(
                          height: 300,
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
                            child: Consumer<LocationProvider>(
                              builder: (context, locationProvider, child) {
                                return Stack(
                                  children: [
                                    GoogleMap(
                                      key: const PageStorageKey('homeMap'),
                                      initialCameraPosition:
                                          const CameraPosition(
                                        target: LatLng(11.0168, 76.9558),
                                        zoom: 15,
                                      ),
                                      mapType: _currentMapType,
                                      myLocationEnabled: false,
                                      myLocationButtonEnabled: false,
                                      zoomControlsEnabled: false,
                                      scrollGesturesEnabled: true,
                                      zoomGesturesEnabled: true,
                                      rotateGesturesEnabled: true,
                                      tiltGesturesEnabled: true,
                                      indoorViewEnabled: true,
                                      trafficEnabled: true,
                                      mapToolbarEnabled: false,
                                      markers: _markers,
                                      circles: _circles,
                                      onMapCreated: (controller) {
                                        _mapController = controller;
                                        // Initial marker update
                                        _updateMarkersAndCircles();
                                        // Try to get current location
                                        _goToCurrentLocation();
                                      },
                                      onCameraMove: _onCameraMove,
                                    ),
                                    // Loading indicator
                                    if (locationProvider.isFetchingLocation)
                                      Container(
                                        color:
                                            Colors.black.withValues(alpha: 0.5),
                                        child: const Center(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              CircularProgressIndicator(
                                                color: Colors.white,
                                              ),
                                              SizedBox(height: 12),
                                              Text(
                                                'Fetching current location...',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    // Error state
                                    if (locationProvider.error != null)
                                      Container(
                                        color:
                                            Colors.black.withValues(alpha: 0.7),
                                        padding: const EdgeInsets.all(16),
                                        child: Center(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                locationProvider.error!,
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              const SizedBox(height: 12),
                                              ElevatedButton(
                                                onPressed: () {
                                                  if (locationProvider
                                                      .permanentlyDenied) {
                                                    locationProvider
                                                        .openAppSettings();
                                                  } else {
                                                    locationProvider
                                                        .clearError();
                                                    _goToCurrentLocation();
                                                  }
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      const Color(0xFFFF6B00),
                                                ),
                                                child: Text(
                                                  locationProvider
                                                          .permanentlyDenied
                                                      ? 'Open Settings'
                                                      : 'Retry',
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    // Zoom controls (left side)
                                    Positioned(
                                      bottom: 16,
                                      left: 16,
                                      child: Column(
                                        children: [
                                          // Zoom in button
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 8),
                                            child: GestureDetector(
                                              onTap: () async {
                                                if (_mapController != null) {
                                                  final currentZoom =
                                                      (await _mapController!
                                                              .getZoomLevel()) +
                                                          1;
                                                  _mapController!.animateCamera(
                                                    CameraUpdate.zoomTo(
                                                        currentZoom),
                                                  );
                                                }
                                              },
                                              child: Container(
                                                width: 48,
                                                height: 48,
                                                decoration: const BoxDecoration(
                                                  color: Colors.white,
                                                  shape: BoxShape.circle,
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black12,
                                                      blurRadius: 8,
                                                      offset: Offset(0, 2),
                                                    ),
                                                  ],
                                                ),
                                                child: const Icon(
                                                  Icons.add,
                                                  color: AppColors.secondary,
                                                ),
                                              ),
                                            ),
                                          ),
                                          // Zoom out button
                                          GestureDetector(
                                            onTap: () async {
                                              if (_mapController != null) {
                                                final currentZoom =
                                                    (await _mapController!
                                                            .getZoomLevel()) -
                                                        1;
                                                _mapController!.animateCamera(
                                                  CameraUpdate.zoomTo(
                                                      currentZoom),
                                                );
                                              }
                                            },
                                            child: Container(
                                              width: 48,
                                              height: 48,
                                              decoration: const BoxDecoration(
                                                color: Colors.white,
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black12,
                                                    blurRadius: 8,
                                                    offset: Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: const Icon(
                                                Icons.remove,
                                                color: AppColors.secondary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Map type button (right side)
                                    Positioned(
                                      bottom: 16,
                                      right: 16,
                                      child: Column(
                                        children: [
                                          // Live Location Button
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 8),
                                            child: GestureDetector(
                                              onTap: locationProvider
                                                      .isFetchingLocation
                                                  ? null
                                                  : _goToCurrentLocation,
                                              child: Container(
                                                width: 48,
                                                height: 48,
                                                decoration: const BoxDecoration(
                                                  color: Color(0xFFFF6B00),
                                                  shape: BoxShape.circle,
                                                  boxShadow: [
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
                                          // Map type button
                                          GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                switch (_currentMapType) {
                                                  case MapType.normal:
                                                    _currentMapType =
                                                        MapType.satellite;
                                                    break;
                                                  case MapType.satellite:
                                                    _currentMapType =
                                                        MapType.hybrid;
                                                    break;
                                                  case MapType.hybrid:
                                                    _currentMapType =
                                                        MapType.terrain;
                                                    break;
                                                  case MapType.terrain:
                                                  case MapType.none:
                                                    _currentMapType =
                                                        MapType.normal;
                                                    break;
                                                }
                                              });
                                            },
                                            child: Container(
                                              width: 48,
                                              height: 48,
                                              decoration: const BoxDecoration(
                                                color: Colors.white,
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black12,
                                                    blurRadius: 8,
                                                    offset: Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: Icon(
                                                _currentMapType ==
                                                        MapType.normal
                                                    ? Icons.map
                                                    : _currentMapType ==
                                                            MapType.satellite
                                                        ? Icons.satellite
                                                        : _currentMapType ==
                                                                MapType.hybrid
                                                            ? Icons.layers
                                                            : Icons.terrain,
                                                color: AppColors.secondary,
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
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Scrollable Bottom Content
              Positioned(
                top: 420, // header + map height + increased gap
                left: 0,
                right: 0,
                bottom: 0,
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: Padding(
                      padding: const EdgeInsets.only(
                          left: 20, right: 20, top: 16, bottom: 100),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
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
                                        Container(
                                          width: double.infinity,
                                          height: 70,
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            child: Image.network(
                                              vehicle['imageUrl'],
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                return Container(
                                                  color: Colors.grey[300],
                                                  child: const Icon(
                                                    Icons.directions_car,
                                                    size: 40,
                                                    color: Colors.grey,
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
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
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: AppColors.grey600,
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
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          '🚖 No recent rides yet',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.black,
                                          ),
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          'Book your first ride with Taxi Nanban.',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              color: AppColors.grey600),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }

                              final List<RideModel> recentRides = [];
                              try {
                                // Add all pending rides first
                                if (bookingProvider.pendingRides.isNotEmpty) {
                                  recentRides
                                      .addAll(bookingProvider.pendingRides);
                                }
                                // Then add completed rides from history
                                if (bookingProvider.rideHistory.isNotEmpty) {
                                  recentRides.addAll(
                                    bookingProvider.rideHistory.where((ride) {
                                      final status = ride.status.toLowerCase();
                                      return ['completed'].contains(status);
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

                              final latestRides = recentRides.take(3).toList();

                              if (latestRides.isEmpty) {
                                return Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: AppColors.grey100,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          '🚖 No recent rides yet',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.black,
                                          ),
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          'Book your first ride with Taxi Nanban.',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              color: AppColors.grey600),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }
                              return Column(
                                children: latestRides.map((ride) {
                                  // Format date
                                  String dateStr = '';
                                  if (ride.createdAt != null) {
                                    final now = DateTime.now();
                                    final diff =
                                        now.difference(ride.createdAt!);
                                    if (diff.inDays == 0) {
                                      dateStr = 'Today';
                                    } else if (diff.inDays == 1) {
                                      dateStr = 'Yesterday';
                                    } else if (diff.inDays < 7) {
                                      dateStr = DateFormat('EEE')
                                          .format(ride.createdAt!);
                                    } else {
                                      dateStr = DateFormat('MMM dd')
                                          .format(ride.createdAt!);
                                    }
                                  }

                                  return GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              RideDetailsScreen(ride: ride),
                                        ),
                                      );
                                    },
                                    child: Container(
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
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Pickup row
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.location_on,
                                                color: Color(0xFF2ECC71),
                                                size: 20,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  ride.pickupAddress,
                                                  style: const TextStyle(
                                                    fontSize: 15,
                                                    color: AppColors.black,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          // Drop row
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.location_pin,
                                                color: Color(0xFFFF6B00),
                                                size: 20,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  ride.dropAddress,
                                                  style: const TextStyle(
                                                    fontSize: 15,
                                                    color: AppColors.black,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          // Date and fare row
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                dateStr,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  color: AppColors.grey600,
                                                ),
                                              ),
                                              Text(
                                                '₹${ride.fare.toStringAsFixed(0)}',
                                                style: const TextStyle(
                                                  fontSize: 17,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.secondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
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
                                    fontWeight: FontWeight.w900,
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
                ),
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
