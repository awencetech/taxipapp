import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../providers/auth_provider.dart';
import '../providers/location_provider.dart';
import '../providers/booking_provider.dart';
import '../widgets/booking_confirmation_sheet.dart';
import '../widgets/map_layers_control.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  GoogleMapController? _mapController;
  final _pickupController = TextEditingController();
  final _dropController = TextEditingController();

  final _pickupFocusNode = FocusNode();
  final _dropFocusNode = FocusNode();

  LatLng? _pickupCoords;
  LatLng? _dropCoords;

  // Track which field is being edited
  String _activeField = 'pickup';

  // Map layer state
  MapLayerType _selectedMapLayer = MapLayerType.normal;
  bool _isTrafficEnabled = false;

  @override
  void initState() {
    super.initState();
    _pickupFocusNode.addListener(() {
      if (_pickupFocusNode.hasFocus) {
        setState(() => _activeField = 'pickup');
      }
    });
    _dropFocusNode.addListener(() {
      if (_dropFocusNode.hasFocus) {
        setState(() => _activeField = 'drop');
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _getCurrentLocation();
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
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(newLatLng, 16),
        );
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    final locationProvider = context.read<LocationProvider>();

    // Clear suggestions and unfocus
    locationProvider.clearSuggestions();
    FocusScope.of(context).unfocus();

    // Get current location
    final coords = await locationProvider.getCurrentLocation();

    if (coords != null) {
      setState(() {
        _pickupCoords = coords;
        _pickupController.text = locationProvider.currentAddress;
      });

      // Animate camera to current location
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(coords, 16),
      );
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

  void _showBookingConfirmationSheet(
    BuildContext context,
    String pickupAddress,
    String dropAddress,
  ) {
    final bookingProvider = context.read<BookingProvider>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      transitionAnimationController: AnimationController(
        vsync: Navigator.of(context),
        duration: const Duration(milliseconds: 300),
      ),
      builder: (context) => BookingConfirmationSheet(
        key: UniqueKey(),
        pickupAddress: pickupAddress,
        dropAddress: dropAddress,
        distanceKm: 5.0,
        onConfirmBooking: () async {
          final scaffoldMessenger = ScaffoldMessenger.of(context);
          Navigator.pop(context);

          final success = await bookingProvider.requestRide({
            'pickupLocation': {
              'address': pickupAddress,
              'coordinates': [
                _pickupCoords!.longitude,
                _pickupCoords!.latitude
              ],
            },
            'dropLocation': {
              'address': dropAddress,
              'coordinates': [_dropCoords!.longitude, _dropCoords!.latitude],
            },
            'fare': bookingProvider.selectedRideType?.estimatedPrice ?? 150,
            'vehicleType': bookingProvider.selectedRideType?.id ?? 'economy',
          });

          if (!success) {
            scaffoldMessenger.showSnackBar(
              SnackBar(
                content: Text(bookingProvider.error ?? 'Request failed'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      ),
    );
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
  void dispose() {
    _pickupController.dispose();
    _dropController.dispose();
    _pickupFocusNode.dispose();
    _dropFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final locationProvider = context.watch<LocationProvider>();
    final bookingProvider = context.watch<BookingProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Taxi Nanban"),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => bookingProvider.findDrivers(),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.red),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, color: Colors.red, size: 40),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    authProvider.user?.name ?? "Welcome User",
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  Text(
                    authProvider.user?.email ?? "",
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
            ListTile(
                leading: const Icon(Icons.history),
                title: const Text("Ride History"),
                onTap: () {
                  Navigator.pop(context); // Close drawer
                  Navigator.pushNamed(context, '/ride-history');
                }),
            ListTile(
                leading: const Icon(Icons.payment),
                title: const Text("Payments"),
                onTap: () {
                  Navigator.pop(context); // Close drawer
                  Navigator.pushNamed(context, '/payments');
                }),
            ListTile(
                leading: const Icon(Icons.settings),
                title: const Text("Settings"),
                onTap: () {
                  Navigator.pop(context); // Close drawer
                  Navigator.pushNamed(context, '/settings');
                }),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text("Logout"),
              onTap: () async {
                final navigator = Navigator.of(context);
                await authProvider.logout();
                navigator.pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              },
            ),
          ],
        ),
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
                      11.0168, 76.9558), // Coimbatore as fallback default
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
          // Floating Map Layers Control
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 0,
            right: 0,
            child: Center(
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
          // Ride Booking UI
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
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (locationProvider.error != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline,
                                color: Colors.red, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                locationProvider.error!,
                                style: const TextStyle(
                                    color: Colors.red, fontSize: 13),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close,
                                  color: Colors.red, size: 18),
                              onPressed: () => locationProvider.clearError(),
                            ),
                          ],
                        ),
                      ),
                    if (bookingProvider.currentRide != null) ...[
                      Text(
                        "Ride Status: ${bookingProvider.currentRide!.status.toUpperCase()}",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.red),
                      ),
                      const SizedBox(height: 10),
                      if (bookingProvider.currentRide!.otp != null)
                        Text("OTP: ${bookingProvider.currentRide!.otp}",
                            style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () => bookingProvider.cancelRide(),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey),
                        child: const Text("Cancel Ride",
                            style: TextStyle(color: Colors.white)),
                      ),
                    ] else ...[
                      // Search Suggestions List
                      if (locationProvider.suggestions.isNotEmpty)
                        Container(
                          constraints: const BoxConstraints(maxHeight: 250),
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: const [
                              BoxShadow(blurRadius: 5, color: Colors.black12)
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: ListView.separated(
                                  shrinkWrap: true,
                                  padding: EdgeInsets.zero,
                                  itemCount:
                                      locationProvider.suggestions.length,
                                  separatorBuilder: (context, index) =>
                                      const Divider(height: 1),
                                  itemBuilder: (context, index) {
                                    final suggestion =
                                        locationProvider.suggestions[index];
                                    return ListTile(
                                      visualDensity: VisualDensity.compact,
                                      leading: const Icon(Icons.location_on,
                                          color: Colors.grey, size: 20),
                                      title: Text(
                                        suggestion['description'],
                                        style: const TextStyle(fontSize: 14),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      onTap: () async {
                                        final description =
                                            suggestion['description'];
                                        final placeId = suggestion['place_id'];

                                        // 1. Immediately clear suggestions and unfocus to close dropdown
                                        locationProvider.clearSuggestions();
                                        FocusScope.of(context).unfocus();

                                        // 2. Update the correct text field immediately for better UX
                                        setState(() {
                                          if (_activeField == 'pickup') {
                                            _pickupController.text =
                                                description;
                                          } else {
                                            _dropController.text = description;
                                          }
                                        });

                                        // 3. Fetch precise coordinates
                                        final coords = await locationProvider
                                            .getPlaceCoords(placeId);

                                        if (coords != null) {
                                          setState(() {
                                            if (_activeField == 'pickup') {
                                              _pickupCoords = coords;
                                            } else {
                                              _dropCoords = coords;
                                            }
                                          });

                                          // 4. Animate map camera to the selected location
                                          _mapController?.animateCamera(
                                            CameraUpdate.newLatLngZoom(
                                                coords, 15),
                                          );
                                        }
                                      },
                                    );
                                  },
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text(
                                      "Powered by Google",
                                      style: TextStyle(
                                          fontSize: 10, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      TextField(
                        controller: _pickupController,
                        focusNode: _pickupFocusNode,
                        onChanged: locationProvider.onSearchChanged,
                        decoration: InputDecoration(
                          hintText: "Pickup Location",
                          prefixIcon: GestureDetector(
                            onTap: _getCurrentLocation,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              child: locationProvider.isFetchingLocation
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.blue,
                                      ),
                                    )
                                  : const Icon(Icons.my_location,
                                      color: Colors.blue),
                            ),
                          ),
                          suffixIcon: locationProvider.isSearching &&
                                  _pickupFocusNode.hasFocus
                              ? IconButton(
                                  icon: const Icon(Icons.close, size: 20),
                                  onPressed: () {
                                    _pickupController.clear();
                                    locationProvider.clearSuggestions();
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _dropController,
                        focusNode: _dropFocusNode,
                        onChanged: locationProvider.onSearchChanged,
                        decoration: InputDecoration(
                          hintText: "Drop Location",
                          prefixIcon:
                              const Icon(Icons.location_on, color: Colors.red),
                          suffixIcon: locationProvider.isSearching &&
                                  _dropFocusNode.hasFocus
                              ? const Padding(
                                  padding: EdgeInsets.all(10),
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : null,
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: bookingProvider.isLoading
                              ? null
                              : () async {
                                  if (_pickupCoords == null &&
                                      locationProvider.currentPosition !=
                                          null) {
                                    _pickupCoords = LatLng(
                                        locationProvider
                                            .currentPosition!.latitude,
                                        locationProvider
                                            .currentPosition!.longitude);
                                  }

                                  if (_pickupCoords == null ||
                                      _dropCoords == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Please select pickup and drop locations')),
                                    );
                                    return;
                                  }

                                  // Show booking confirmation bottom sheet
                                  _showBookingConfirmationSheet(
                                    context,
                                    _pickupController.text.isEmpty
                                        ? 'Current Location'
                                        : _pickupController.text,
                                    _dropController.text,
                                  );
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          child: bookingProvider.isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white)
                              : const Text("Book Ride Now",
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 18)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
