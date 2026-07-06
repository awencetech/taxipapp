import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import '../../viewmodels/driver_viewmodel.dart';
import '../../viewmodels/theme_viewmodel.dart';
import '../../models/vendor_models.dart';
import '../../services/api_service.dart';
import '../../core/constants/app_constants.dart';

class TrackCabScreen extends StatefulWidget {
  final VoidCallback? onBackPressed;
  const TrackCabScreen({super.key, this.onBackPressed});

  @override
  State<TrackCabScreen> createState() => _TrackCabScreenState();
}

class _TrackCabScreenState extends State<TrackCabScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All Drivers';
  final List<String> _filters = [
    'All Drivers',
    'Online',
    'On Trip',
    'Available',
    'Offline',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DriverViewModel>().fetchDrivers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Driver> _filterDrivers(List<Driver> drivers) {
    var filtered = drivers;
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered = filtered
          .where(
            (driver) =>
                driver.name.toLowerCase().contains(query) ||
                driver.id.toLowerCase().contains(query) ||
                (driver.driverId?.toLowerCase().contains(query) ?? false) ||
                (driver.vehicleNumber?.toLowerCase().contains(query) ?? false),
          )
          .toList();
    }
    switch (_selectedFilter) {
      case 'Online':
        filtered = filtered.where((d) => d.isOnline == true).toList();
        break;
      case 'On Trip':
        filtered = filtered.where((d) => d.isBusy == true).toList();
        break;
      case 'Available':
        filtered = filtered
            .where((d) => d.isOnline == true && d.isBusy == false)
            .toList();
        break;
      case 'Offline':
        filtered = filtered.where((d) => d.isOnline == false).toList();
        break;
    }
    return filtered;
  }

  Color _getStatusColor(Driver driver) {
    if (driver.isBusy == true) return const Color(0xFF3B82F6);
    if (driver.isOnline == true) return const Color(0xFF22C55E);
    return const Color(0xFF64748B);
  }

  String _getStatusText(Driver driver) {
    if (driver.isBusy == true) return 'On Trip';
    if (driver.isOnline == true) return 'Available';
    return 'Offline';
  }

  void _showLiveLocationSheet(BuildContext context, Driver driver) {
    final themeVM = context.read<ThemeViewModel>();
    final isDark = themeVM.isDarkMode;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _LiveLocationSheet(driver: driver, isDark: isDark),
    );
  }

  @override
  Widget build(BuildContext context) {
    final driverVM = context.watch<DriverViewModel>();
    final themeVM = context.watch<ThemeViewModel>();
    final isDark = themeVM.isDarkMode;
    final filteredDrivers = _filterDrivers(driverVM.drivers);

    if (driverVM.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (driverVM.errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 80, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                driverVM.errorMessage!,
                style: const TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => driverVM.fetchDrivers(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F172A)
          : const Color(0xFFF0F4FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: widget.onBackPressed,
        ),
      ),
      extendBodyBehindAppBar: true,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(
                top: 24,
                left: 20,
                right: 20,
                bottom: 24,
              ),
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
                  const Text(
                    'Track Cabs',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Monitor your fleet in real-time',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      _StatCard(
                        label: 'Total Drivers',
                        value: '${driverVM.drivers.length}',
                      ),
                      _StatCard(
                        label: 'Online',
                        value:
                            '${driverVM.drivers.where((d) => d.isOnline == true).length}',
                      ),
                      _StatCard(
                        label: 'On Trip',
                        value:
                            '${driverVM.drivers.where((d) => d.isBusy == true).length}',
                      ),
                      _StatCard(
                        label: 'Offline',
                        value:
                            '${driverVM.drivers.where((d) => d.isOnline == false).length}',
                      ),
                      _StatCard(
                        label: 'Available',
                        value:
                            '${driverVM.drivers.where((d) => d.isOnline == true && d.isBusy == false).length}',
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? Colors.transparent
                              : Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF1F2937),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search drivers...',
                        hintStyle: TextStyle(color: Colors.grey[500]),
                        border: InputBorder.none,
                        icon: Icon(Icons.search, color: Colors.grey[500]),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _filters.map((filter) {
                        final isSelected = _selectedFilter == filter;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(filter),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                _selectedFilter = selected
                                    ? filter
                                    : 'All Drivers';
                              });
                            },
                            selectedColor: const Color(0xFF1D2951),
                            checkmarkColor: Colors.white,
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF1F2937),
                            ),
                            backgroundColor: isDark
                                ? Colors.grey[700]
                                : Colors.white,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: filteredDrivers.isEmpty
                    ? Center(
                        child: Text(
                          'No drivers found',
                          style: TextStyle(
                            fontSize: 16,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 20),
                        itemCount: filteredDrivers.length,
                        itemBuilder: (context, index) {
                          final driver = filteredDrivers[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: GestureDetector(
                              onTap: () {
                                _showLiveLocationSheet(context, driver);
                              },
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF1E1E1E)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: isDark
                                          ? Colors.transparent
                                          : Colors.black.withValues(
                                              alpha: 0.05,
                                            ),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Stack(
                                          clipBehavior: Clip.none,
                                          children: [
                                            CircleAvatar(
                                              radius: 35,
                                              backgroundImage:
                                                  driver.profilePicture !=
                                                          null &&
                                                      driver
                                                          .profilePicture!
                                                          .isNotEmpty
                                                  ? NetworkImage(
                                                      driver.profilePicture!,
                                                    )
                                                  : const NetworkImage(
                                                      'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150',
                                                    ),
                                            ),
                                            Positioned(
                                              bottom: -2,
                                              right: -2,
                                              child: Container(
                                                width: 18,
                                                height: 18,
                                                decoration: BoxDecoration(
                                                  color: _getStatusColor(
                                                    driver,
                                                  ),
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: isDark
                                                        ? const Color(
                                                            0xFF1E1E1E,
                                                          )
                                                        : Colors.white,
                                                    width: 3,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                driver.name,
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: isDark
                                                      ? Colors.white
                                                      : const Color(0xFF1F2937),
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Driver ID: ${driver.driverId ?? 'N/A'}',
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  color: Color(0xFFFF7A00),
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _getStatusColor(
                                              driver,
                                            ).withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Text(
                                            _getStatusText(driver),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: _getStatusColor(driver),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.phone,
                                                size: 16,
                                                color: Colors.grey[500],
                                              ),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  driver.phone,
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: isDark
                                                        ? Colors.grey[300]
                                                        : const Color(
                                                            0xFF1F2937,
                                                          ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Expanded(
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.directions_car,
                                                size: 16,
                                                color: Colors.grey[500],
                                              ),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  driver.vehicleNumber ?? 'N/A',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: isDark
                                                        ? Colors.grey[300]
                                                        : Colors.grey[700],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.local_taxi,
                                                size: 16,
                                                color: Colors.grey[500],
                                              ),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  driver.vehicleType ?? 'N/A',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: isDark
                                                        ? Colors.grey[300]
                                                        : Colors.grey[700],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (driver.speed != null)
                                          Expanded(
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.speed,
                                                  size: 16,
                                                  color: Colors.grey[500],
                                                ),
                                                const SizedBox(width: 6),
                                                Expanded(
                                                  child: Text(
                                                    '${driver.speed!.toStringAsFixed(1)} km/h',
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      color: isDark
                                                          ? Colors.grey[300]
                                                          : Colors.grey[700],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                    if (driver.lastUpdated != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 12),
                                        child: Align(
                                          alignment: Alignment.centerRight,
                                          child: Text(
                                            'Last updated: ${DateFormat('MMM d, h:mm a').format(driver.lastUpdated!)}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[500],
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveLocationSheet extends StatefulWidget {
  final Driver driver;
  final bool isDark;

  const _LiveLocationSheet({
    required this.driver,
    required this.isDark,
  });

  @override
  State<_LiveLocationSheet> createState() => _LiveLocationSheetState();
}

class _LiveLocationSheetState extends State<_LiveLocationSheet> {
  final ApiService _apiService = ApiService();

  bool _isLoading = true;
  String? _errorMessage;
  Driver? _currentDriver;
  Ride? _activeRide;
  Timer? _updateTimer;

  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  bool _followDriver = true;
  bool _showTraffic = false;
  bool _showSatellite = false;
  String? _currentAddress;

  @override
  void initState() {
    super.initState();
    _currentDriver = widget.driver;
    _loadDriverDetails();
    _updateTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _loadDriverDetails();
    });
    _updateMarker();
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _loadDriverDetails() async {
    try {
      final response = await _apiService.get(
        AppConstants.vendorDriverByIdUrl.replaceFirst(':id', widget.driver.id),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        setState(() {
          _currentDriver = Driver.fromJson(data['driver']);
          _activeRide = data['activeRide'] != null
              ? Ride.fromJson(data['activeRide'])
              : null;
          _isLoading = false;
          _errorMessage = null;
          _updateMarker();
        });

        if (_currentDriver?.currentLatitude != null &&
            _currentDriver?.currentLongitude != null) {
          await _getAddress(
            _currentDriver!.currentLatitude!,
            _currentDriver!.currentLongitude!,
          );
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _getAddress(double latitude, double longitude) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        setState(() {
          _currentAddress =
              '${place.street}, ${place.locality}, ${place.administrativeArea}';
        });
      }
    } catch (e) {
      // If geocoding fails, just keep existing address or show nothing
    }
  }

  void _updateMarker() {
    final lat = _currentDriver?.currentLatitude ?? 13.0827;
    final lng = _currentDriver?.currentLongitude ?? 80.2707;
    final LatLng driverLocation = LatLng(lat, lng);

    Color markerColor;
    if (_currentDriver?.isBusy == true) {
      markerColor = Colors.blue;
    } else if (_currentDriver?.isOnline == true) {
      markerColor = Colors.green;
    } else {
      markerColor = Colors.grey;
    }

    setState(() {
      _markers = {
        Marker(
          markerId: MarkerId(_currentDriver?.id ?? 'driver'),
          position: driverLocation,
          infoWindow: InfoWindow(
            title: _currentDriver?.name ?? 'Driver',
            snippet: _currentAddress,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(_colorToHue(markerColor)),
        ),
      };

      if (_followDriver) {
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(driverLocation, 16),
        );
      }
    });
  }

  double _colorToHue(Color color) {
    if (color == Colors.green) {
      return BitmapDescriptor.hueGreen;
    } else if (color == Colors.blue) {
      return BitmapDescriptor.hueBlue;
    } else if (color == Colors.red) {
      return BitmapDescriptor.hueRed;
    } else {
      return BitmapDescriptor.hueRose;
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    final lat = _currentDriver?.currentLatitude ?? 13.0827;
    final lng = _currentDriver?.currentLongitude ?? 80.2707;
    controller.animateCamera(CameraUpdate.newLatLngZoom(LatLng(lat, lng), 16));
  }

  void _onCameraMove(CameraPosition position) {
    setState(() {
      _followDriver = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final lat = _currentDriver?.currentLatitude ?? 13.0827;
    final lng = _currentDriver?.currentLongitude ?? 80.2707;
    final driverLocation = LatLng(lat, lng);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: widget.isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 48,
            height: 5,
            decoration: BoxDecoration(
              color: widget.isDark ? Colors.grey[700] : Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundImage:
                      _currentDriver?.profilePicture != null &&
                          _currentDriver!.profilePicture!.isNotEmpty
                      ? NetworkImage(_currentDriver!.profilePicture!)
                      : const NetworkImage(
                          'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150',
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentDriver?.name ?? 'Driver',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: widget.isDark
                              ? Colors.white
                              : const Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Driver ID: ${_currentDriver?.driverId ?? 'N/A'}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFFFF7A00),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_currentDriver?.vehicleType ?? 'Car'} • ${_currentDriver?.vehicleNumber ?? 'N/A'}',
                        style: TextStyle(
                          fontSize: 14,
                          color: widget.isDark
                              ? Colors.grey[400]
                              : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getDriverStatusColor().withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _getDriverStatusText(),
                    style: TextStyle(
                      fontSize: 12,
                      color: _getDriverStatusColor(),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          Expanded(
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Stack(
                children: [
                  GoogleMap(
                    onMapCreated: _onMapCreated,
                    onCameraMove: _onCameraMove,
                    initialCameraPosition: CameraPosition(
                      target: driverLocation,
                      zoom: 16,
                    ),
                    markers: _markers,
                    polylines: _polylines,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    trafficEnabled: _showTraffic,
                    mapType: _showSatellite
                        ? MapType.satellite
                        : MapType.normal,
                    buildingsEnabled: true,
                    rotateGesturesEnabled: true,
                    tiltGesturesEnabled: true,
                  ),
                  Positioned(
                    right: 16,
                    top: 16,
                    child: Column(
                      children: [
                        _MapButton(
                          icon: Icons.my_location,
                          onPressed: () {
                            setState(() {
                              _followDriver = true;
                            });
                            _updateMarker();
                          },
                        ),
                        const SizedBox(height: 8),
                        _MapButton(
                          icon: Icons.zoom_in,
                          onPressed: () {
                            _mapController?.animateCamera(
                              CameraUpdate.zoomIn(),
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        _MapButton(
                          icon: Icons.zoom_out,
                          onPressed: () {
                            _mapController?.animateCamera(
                              CameraUpdate.zoomOut(),
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        _MapButton(
                          icon: Icons.traffic,
                          onPressed: () {
                            setState(() {
                              _showTraffic = !_showTraffic;
                            });
                          },
                          isActive: _showTraffic,
                        ),
                        const SizedBox(height: 8),
                        _MapButton(
                          icon: Icons.satellite_alt,
                          onPressed: () {
                            setState(() {
                              _showSatellite = !_showSatellite;
                            });
                          },
                          isActive: _showSatellite,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          Container(
            padding: const EdgeInsets.all(20),
            color: widget.isDark ? const Color(0xFF1E293B) : Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (_errorMessage != null)
                  Center(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 16),
                    ),
                  )
                else ...[
                  if (_currentAddress != null)
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: Colors.blue,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _currentAddress!,
                            style: TextStyle(
                              fontSize: 14,
                              color: widget.isDark
                                  ? Colors.white
                                  : const Color(0xFF1F2937),
                            ),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      _DetailItem(
                        label: 'Speed',
                        value:
                            '${_currentDriver?.speed?.toStringAsFixed(1) ?? '0.0'} km/h',
                      ),
                      _DetailItem(
                        label: 'Last Updated',
                        value: _currentDriver?.lastUpdated != null
                            ? DateFormat(
                                'h:mm a',
                              ).format(_currentDriver!.lastUpdated!)
                            : 'N/A',
                      ),
                      _DetailItem(
                        label: 'Phone',
                        value: _currentDriver?.phone ?? 'N/A',
                      ),
                    ],
                  ),
                  if (_activeRide != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.blue.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Active Trip',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 4),
                                child: Icon(
                                  Icons.person,
                                  size: 20,
                                  color: Colors.blue,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _activeRide?.user?.name ?? 'Passenger',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: widget.isDark
                                        ? Colors.white
                                        : const Color(0xFF1F2937),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 4),
                                child: Icon(
                                  Icons.pin_drop,
                                  size: 20,
                                  color: Colors.green,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _activeRide?.pickupAddress ??
                                      'Pickup Location',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: widget.isDark
                                        ? Colors.white
                                        : const Color(0xFF1F2937),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 4),
                                child: Icon(
                                  Icons.pin_drop,
                                  size: 20,
                                  color: Colors.red,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _activeRide?.dropAddress ?? 'Drop Location',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: widget.isDark
                                        ? Colors.white
                                        : const Color(0xFF1F2937),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _DetailItem(
                                label: 'Fare',
                                value: '₹${_activeRide?.fare ?? 0}',
                              ),
                              _DetailItem(
                                label: 'Status',
                                value: _activeRide!.status,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getDriverStatusColor() {
    if (_currentDriver?.isBusy == true) {
      return const Color(0xFF3B82F6);
    } else if (_currentDriver?.isOnline == true) {
      return const Color(0xFF22C55E);
    } else {
      return const Color(0xFF64748B);
    }
  }

  String _getDriverStatusText() {
    if (_currentDriver?.isBusy == true) {
      return 'On Trip';
    } else if (_currentDriver?.isOnline == true) {
      return 'Available';
    } else {
      return 'Offline';
    }
  }
}

class _MapButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final bool isActive;

  const _MapButton({
    required this.icon,
    required this.onPressed,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: IconButton(
        icon: Icon(icon),
        color: isActive ? Colors.blue : Colors.black87,
        onPressed: onPressed,
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  final String label;
  final String value;

  const _DetailItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;

  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
