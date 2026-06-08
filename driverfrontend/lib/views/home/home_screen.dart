import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/ride_viewmodel.dart';
import '../../providers/location_provider.dart';
import '../../widgets/map_layers_control.dart';
import '../../widgets/ride_request_popup.dart';
import '../earnings/earnings_screen.dart';
import '../profile/profile_screen.dart';
import '../rides/rides_screen.dart';
import '../notifications/notifications_screen.dart';
import '../auth/login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const MapView(),
    const RidesScreen(),
    const NotificationsScreen(),
    const EarningsScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Home'),
          const BottomNavigationBarItem(
            icon: Icon(Icons.directions_car),
            label: 'Rides',
          ),
          BottomNavigationBarItem(
            icon: Consumer<RideViewModel>(
              builder: (context, rideViewModel, child) {
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.notifications),
                    if (rideViewModel.unreadCount > 0)
                      Positioned(
                        right: -8,
                        top: -8,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          child: Text(
                            rideViewModel.unreadCount > 99
                                ? '99+'
                                : rideViewModel.unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            label: 'Notifications',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Earnings',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class MapView extends StatefulWidget {
  const MapView({super.key});

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  GoogleMapController? _mapController;
  MapLayerType _selectedMapLayer = MapLayerType.normal;
  bool _isTrafficEnabled = false;
  LatLng? _lastKnownPosition;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        context.read<LocationProvider>().getCurrentLocation();
        final authViewModel = context.read<AuthViewModel>();
        if (authViewModel.driver != null) {
          context.read<RideViewModel>().initialize(authViewModel.driver!.id);
          context.read<RideViewModel>().fetchNotifications();
        }
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locationProvider = context.watch<LocationProvider>();
    final currentPosition = locationProvider.currentPosition;

    if (currentPosition != null && _mapController != null) {
      final newLatLng = LatLng(
        currentPosition.latitude,
        currentPosition.longitude,
      );
      if (_lastKnownPosition == null ||
          _lastKnownPosition!.latitude != newLatLng.latitude ||
          _lastKnownPosition!.longitude != newLatLng.longitude) {
        _lastKnownPosition = newLatLng;
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(newLatLng, 16),
        );
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    final locationProvider = context.read<LocationProvider>();

    final coords = await locationProvider.getCurrentLocation();

    if (coords != null) {
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(coords, 16));
    } else if (locationProvider.error != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(locationProvider.error!),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Settings',
              textColor: Colors.white,
              onPressed: () {
                Geolocator.openLocationSettings();
              },
            ),
          ),
        );
        locationProvider.clearError();
      }
    }
  }

  MapType _getMapType() {
    switch (_selectedMapLayer) {
      case MapLayerType.satellite:
        return MapType.satellite;
      case MapLayerType.terrain:
        return MapType.terrain;
      case MapLayerType.hybrid:
        return MapType.hybrid;
      default:
        return MapType.normal;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();
    final rideViewModel = context.watch<RideViewModel>();
    final locationProvider = context.watch<LocationProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Taxi Nanban Driver"),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final navigator = Navigator.of(context);
              await authViewModel.logout();
              navigator.pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: locationProvider.currentPosition != null
                  ? LatLng(
                      locationProvider.currentPosition!.latitude,
                      locationProvider.currentPosition!.longitude,
                    )
                  : const LatLng(
                      11.0168,
                      76.9558,
                    ), // Coimbatore as fallback default
              zoom: 15,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            mapType: _getMapType(),
            trafficEnabled: _isTrafficEnabled,
            onMapCreated: (controller) {
              _mapController = controller;
              final locationProvider = context.read<LocationProvider>();
              if (locationProvider.currentPosition != null) {
                _mapController!.animateCamera(
                  CameraUpdate.newLatLngZoom(
                    LatLng(
                      locationProvider.currentPosition!.latitude,
                      locationProvider.currentPosition!.longitude,
                    ),
                    16,
                  ),
                );
              }
            },
            markers: rideViewModel.nearbyRides.map((ride) {
              return Marker(
                markerId: MarkerId(ride.id),
                position: LatLng(ride.pickupCoords[1], ride.pickupCoords[0]),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueOrange,
                ),
                infoWindow: InfoWindow(title: 'Ride Request'),
              );
            }).toSet(),
          ),
          // Floating Map Layers Control
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            right: 16,
            child: MapLayersControl(
              selectedLayer: _selectedMapLayer,
              isDarkMode: Theme.of(context).brightness == Brightness.dark,
              onLayerSelected: (layer) {
                setState(() {
                  _selectedMapLayer = layer;
                  _isTrafficEnabled = (layer == MapLayerType.traffic);
                });
              },
            ),
          ),
          // Go to current location FAB
          Positioned(
            right: 16,
            bottom: 280,
            child: FloatingActionButton.small(
              heroTag: "location_fab",
              onPressed: _getCurrentLocation,
              backgroundColor: Colors.white,
              child: locationProvider.isFetchingLocation
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location, color: Colors.blue),
            ),
          ),
          // Top Online/Offline Toggle
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 10.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () => rideViewModel.toggleOnlineOffline(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: rideViewModel.isOnline
                            ? Colors.green
                            : Colors.red,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            rideViewModel.isOnline
                                ? Icons.online_prediction
                                : Icons.offline_bolt,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            rideViewModel.isOnline ? 'ONLINE' : 'OFFLINE',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Earnings Summary Card
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black12)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (locationProvider.error != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              locationProvider.error!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: Colors.red,
                              size: 18,
                            ),
                            onPressed: () => locationProvider.clearError(),
                          ),
                        ],
                      ),
                    ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatColumn('Earnings', '₹1,250'),
                      const VerticalDivider(thickness: 1),
                      _buildStatColumn('Rides', '12'),
                      const VerticalDivider(thickness: 1),
                      _buildStatColumn('Rating', '4.8 ★'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Ride Request Popup
          if (rideViewModel.incomingRequest != null) const RideRequestPopup(),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}
