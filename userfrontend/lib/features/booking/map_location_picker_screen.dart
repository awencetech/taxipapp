import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/search_provider.dart';
import '../../core/providers/location_provider.dart';
import '../../core/models/place_details_model.dart';

class MapLocationPickerScreen extends StatefulWidget {
  const MapLocationPickerScreen({super.key});

  @override
  State<MapLocationPickerScreen> createState() =>
      _MapLocationPickerScreenState();
}

class _MapLocationPickerScreenState extends State<MapLocationPickerScreen> {
  GoogleMapController? _mapController;
  final TextEditingController _searchController = TextEditingController();
  LatLng _selectedLocation = const LatLng(11.0168, 76.9558);
  String _selectedAddress = 'Searching address...';
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    final locationProvider = context.read<LocationProvider>();
    final currentPosition = await locationProvider.getCurrentLocation();
    if (currentPosition != null) {
      setState(() {
        _selectedLocation = currentPosition;
      });
      await _getAddressFromLatLng(currentPosition);
      if (_mapController != null) {
        _mapController!
            .animateCamera(CameraUpdate.newLatLngZoom(currentPosition, 16));
      }
    } else {
      await _getAddressFromLatLng(_selectedLocation);
    }
  }

  Future<void> _getAddressFromLatLng(LatLng position) async {
    final locationProvider = context.read<LocationProvider>();
    final address = await locationProvider.getAddressFromLatLng(
      position.latitude,
      position.longitude,
    );
    if (mounted) {
      setState(() {
        _selectedAddress = address;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _selectedLocation,
              zoom: 16,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
            },
            onCameraMove: (position) {
              setState(() {
                _selectedLocation = position.target;
              });
            },
            onCameraIdle: () {
              _getAddressFromLatLng(_selectedLocation);
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: true,
          ),
          // Center Pin
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.location_pin,
                  size: 50,
                  color: Colors.red,
                ),
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
          // Top Section
          SafeArea(
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back,
                                color: AppColors.black),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Select Drop Location',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.black,
                              ),
                            ),
                          ),
                          const SizedBox(width: 48),
                        ],
                      ),
                      const Divider(height: 1),
                      // Search Field
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (query) {
                            context
                                .read<SearchProvider>()
                                .onSearchChanged(query);
                            setState(() {
                              _isSearching = query.isNotEmpty;
                            });
                          },
                          decoration: InputDecoration(
                            hintText: 'Search address',
                            hintStyle:
                                const TextStyle(color: AppColors.grey400),
                            prefixIcon: const Icon(Icons.search,
                                color: AppColors.primary),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {
                                        _isSearching = false;
                                      });
                                      context
                                          .read<SearchProvider>()
                                          .clearSearch();
                                    },
                                  )
                                : null,
                            filled: true,
                            fillColor: AppColors.grey100,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Search Results
                if (_isSearching)
                  Consumer<SearchProvider>(
                    builder: (context, searchProvider, child) {
                      if (searchProvider.status == SearchStatus.loading) {
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Padding(
                            padding: EdgeInsets.all(24),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                        );
                      }
                      if (searchProvider.predictions.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: searchProvider.predictions.length,
                          separatorBuilder: (context, index) =>
                              const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final prediction =
                                searchProvider.predictions[index];
                            return ListTile(
                              leading: const Icon(Icons.location_on,
                                  color: AppColors.grey400),
                              title: Text(
                                prediction.mainText,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              subtitle: Text(
                                prediction.secondaryText,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.grey600,
                                ),
                              ),
                              onTap: () async {
                                final details = await context
                                    .read<SearchProvider>()
                                    .selectPlace(prediction);
                                final newLatLng = LatLng(
                                  details.latitude,
                                  details.longitude,
                                );
                                setState(() {
                                  _selectedLocation = newLatLng;
                                  _selectedAddress = details.address;
                                  _isSearching = false;
                                });
                                _searchController.text = details.name;
                                if (_mapController != null) {
                                  _mapController!.animateCamera(
                                    CameraUpdate.newLatLngZoom(newLatLng, 16),
                                  );
                                }
                              },
                            );
                          },
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
          // Current Location Button
          Positioned(
            bottom: 280,
            right: 16,
            child: FloatingActionButton(
              onPressed: () async {
                final locationProvider = context.read<LocationProvider>();
                final currentPosition =
                    await locationProvider.getCurrentLocation();
                if (currentPosition != null && _mapController != null) {
                  setState(() {
                    _selectedLocation = currentPosition;
                  });
                  await _getAddressFromLatLng(currentPosition);
                  _mapController!.animateCamera(
                      CameraUpdate.newLatLngZoom(currentPosition, 16));
                }
              },
              backgroundColor: Colors.white,
              child: const Icon(Icons.my_location, color: AppColors.primary),
            ),
          ),
          // Bottom Address Card and Set Address Button
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 15,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Address Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.grey100,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Selected Address',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.grey600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.location_pin,
                                    color: AppColors.primary, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _selectedAddress,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.black,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Set Address Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () {
                            // For the name, use the first comma-separated part, or the whole address
                            String placeName = _selectedAddress;
                            if (_selectedAddress.contains(',')) {
                              final firstPart = _selectedAddress.split(',').first.trim();
                              // Only use first part if it's not just a number
                              if (double.tryParse(firstPart) == null && firstPart.isNotEmpty) {
                                placeName = firstPart;
                              }
                            }
                            final placeDetails = PlaceDetails(
                              placeId: 'map_selection',
                              name: placeName,
                              address: _selectedAddress,
                              latitude: _selectedLocation.latitude,
                              longitude: _selectedLocation.longitude,
                            );
                            Navigator.pop(context, placeDetails);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF9500),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Set Address',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _searchController.dispose();
    super.dispose();
  }
}
