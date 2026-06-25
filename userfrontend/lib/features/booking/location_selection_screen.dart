import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/search_provider.dart';
import '../../core/providers/location_provider.dart';
import '../../core/providers/booking_provider.dart';
import '../../core/providers/address_provider.dart';
import '../../core/models/place_prediction_model.dart';
import '../../core/models/place_details_model.dart';
import '../../core/models/ride_type.dart';
import 'map_location_picker_screen.dart';
import 'searching_driver_screen.dart';
import 'ride_booking_screen.dart';

enum LocationField { pickup, drop }

class LocationSelectionScreen extends StatefulWidget {
  final String? selectedVehicle;

  const LocationSelectionScreen({super.key, this.selectedVehicle});

  @override
  State<LocationSelectionScreen> createState() =>
      _LocationSelectionScreenState();
}

class _LocationSelectionScreenState extends State<LocationSelectionScreen> {
  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _dropController = TextEditingController();
  LocationField _activeField = LocationField.drop;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _initializePickupFromLocation();
    _pickupController.addListener(_onPickupTextChanged);
    _dropController.addListener(_onDropTextChanged);

    // Pre-select the ride type if selectedVehicle is provided
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.selectedVehicle != null && mounted) {
        final bookingProvider = context.read<BookingProvider>();
        final rides = RideType.getDummyRides(0);
        try {
          final selectedRide = rides.firstWhere(
            (ride) =>
                ride.name.toLowerCase() ==
                widget.selectedVehicle!.toLowerCase(),
          );
          bookingProvider.selectRideType(selectedRide);
        } catch (e) {
          // If ride not found, do nothing
        }
      }
    });
  }

  void _initializePickupFromLocation() {
    final locationProvider = context.read<LocationProvider>();
    if (locationProvider.currentAddress.isNotEmpty) {
      _pickupController.text = locationProvider.currentAddress;
    }
  }

  void _onPickupTextChanged() {
    if (_activeField == LocationField.pickup) {
      setState(() {
        _isSearching = _pickupController.text.isNotEmpty;
      });
      context.read<SearchProvider>().onSearchChanged(_pickupController.text);
    }
  }

  void _onDropTextChanged() {
    if (_activeField == LocationField.drop) {
      setState(() {
        _isSearching = _dropController.text.isNotEmpty;
      });
      context.read<SearchProvider>().onSearchChanged(_dropController.text);
    }
  }

  Future<void> _onPredictionSelected(PlacePrediction prediction) async {
    try {
      final details =
          await context.read<SearchProvider>().selectPlace(prediction);
      if (mounted) {
        final bookingProvider = context.read<BookingProvider>();
        if (_activeField == LocationField.pickup) {
          bookingProvider.setPickupLocation(details);
          _pickupController.text =
              _isNumericOnly(details.name) ? details.address : details.name;
        } else {
          bookingProvider.setDropLocation(details);
          _dropController.text =
              _isNumericOnly(details.name) ? details.address : details.name;
        }
        setState(() {
          _isSearching = false;
        });

        // If both are selected, calculate route and navigate
        if (bookingProvider.pickupLocation != null &&
            bookingProvider.dropLocation != null) {
          await bookingProvider.calculateRoute();
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const RideBookingScreen(),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _pickupController.dispose();
    _dropController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back,
                            color: AppColors.black),
                        onPressed: () {
                          context.read<BookingProvider>().resetBooking();
                          Navigator.pop(context);
                        },
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        "Where to?",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AppColors.black,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Pickup & Drop Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.grey100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Icons Column
                        Column(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: const BoxDecoration(
                                color: Color(0xFF4CD964),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.circle,
                                  size: 10, color: Colors.white),
                            ),
                            Container(
                              width: 2,
                              height: 30,
                              color: AppColors.grey300,
                            ),
                            Container(
                              width: 24,
                              height: 24,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFF9500),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.location_pin,
                                  size: 14, color: Colors.white),
                            ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        // Text Fields Column
                        Expanded(
                          child: Column(
                            children: [
                              TextField(
                                controller: _pickupController,
                                onTap: () {
                                  setState(() =>
                                      _activeField = LocationField.pickup);
                                },
                                style: const TextStyle(
                                    color: AppColors.black,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500),
                                decoration: InputDecoration(
                                  hintText: "Current Location",
                                  hintStyle: const TextStyle(
                                      color: AppColors.grey400, fontSize: 16),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                  suffixIcon: _pickupController.text.isNotEmpty
                                      ? IconButton(
                                          icon:
                                              const Icon(Icons.clear, size: 20),
                                          onPressed: () {
                                            _pickupController.clear();
                                            setState(
                                                () => _isSearching = false);
                                          },
                                        )
                                      : null,
                                ),
                              ),
                              const Divider(height: 24, thickness: 1),
                              TextField(
                                controller: _dropController,
                                onTap: () {
                                  setState(
                                      () => _activeField = LocationField.drop);
                                },
                                autofocus: true,
                                style: const TextStyle(
                                    color: AppColors.black,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500),
                                decoration: InputDecoration(
                                  hintText: "Enter destination",
                                  hintStyle: const TextStyle(
                                      color: AppColors.grey400, fontSize: 16),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                  suffixIcon: _dropController.text.isNotEmpty
                                      ? IconButton(
                                          icon:
                                              const Icon(Icons.clear, size: 20),
                                          onPressed: () {
                                            _dropController.clear();
                                            setState(
                                                () => _isSearching = false);
                                          },
                                        )
                                      : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const MapLocationPickerScreen(),
                              ),
                            );
                            if (result != null &&
                                result is PlaceDetails &&
                                mounted) {
                              context
                                  .read<BookingProvider>()
                                  .setDropLocation(result);
                              final displayName = _isNumericOnly(result.name)
                                  ? result.address
                                  : result.name;
                              _dropController.text = displayName;
                              if (context
                                      .read<BookingProvider>()
                                      .pickupLocation !=
                                  null) {
                                await context
                                    .read<BookingProvider>()
                                    .calculateRoute();
                                if (mounted) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const RideBookingScreen(),
                                    ),
                                  );
                                }
                              }
                            }
                          },
                          icon: const Icon(Icons.map, size: 18),
                          label: const Text(
                            "Select from Map",
                            style: TextStyle(fontSize: 14),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            side: const BorderSide(color: AppColors.grey300),
                            foregroundColor: AppColors.black,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text(
                            "Add Stops",
                            style: TextStyle(fontSize: 14),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            side: const BorderSide(color: AppColors.grey300),
                            foregroundColor: AppColors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Content Area: Search Results or Saved Locations or Ride Details
            Expanded(
              child: Consumer<BookingProvider>(
                builder: (context, bookingProvider, child) {
                  // If both locations selected, navigate to RideBookingScreen
                  if (bookingProvider.pickupLocation != null &&
                      bookingProvider.dropLocation != null &&
                      !_isSearching) {
                    // Use PostFrameCallback to avoid building during build
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RideBookingScreen(),
                          ),
                        );
                      }
                    });
                  }
                  // Otherwise show search results or recent locations
                  return _isSearching
                      ? _buildSearchResults()
                      : _buildRecentLocations();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper function to get display location name
  String getDisplayLocation(PlaceDetails? location) {
    if (location == null) return "";
    // Try name first, check if it's not numeric only and not empty
    if (location.name.isNotEmpty && !_isNumericOnly(location.name)) {
      return location.name;
    }
    // Then try full address
    if (location.address.isNotEmpty) {
      return location.address;
    }
    // Fallback
    return "Selected Location";
  }

  // Helper function to check if string is only numbers
  bool _isNumericOnly(String s) {
    if (s.isEmpty) return true;
    return double.tryParse(s) != null;
  }

  Widget _buildRideDetails(BookingProvider bookingProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Trip Details Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Trip Details",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: 16),
                // Pickup Location
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        color: Color(0xFF4CD964),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.circle,
                          size: 8, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Pickup",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.grey600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            getDisplayLocation(bookingProvider.pickupLocation),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Divider
                Container(
                  margin: const EdgeInsets.only(left: 9),
                  width: 2,
                  height: 24,
                  color: AppColors.grey300,
                ),
                const SizedBox(height: 12),
                // Drop Location
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF9500),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.location_pin,
                          size: 10, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Drop",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.grey600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            getDisplayLocation(bookingProvider.dropLocation),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Distance & Time Row
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.grey100,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Distance",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.grey600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "${bookingProvider.distance.toStringAsFixed(1)} km",
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.grey100,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Est. Time",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.grey600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "${bookingProvider.estimatedTime} mins",
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Available Vehicles
          const Text(
            "Available Vehicles",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 16),
          // Vehicle List
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: RideType.getDummyRides(bookingProvider.distance).length,
            itemBuilder: (context, index) {
              final ride =
                  RideType.getDummyRides(bookingProvider.distance)[index];
              final isSelected =
                  bookingProvider.selectedRideType?.id == ride.id;

              return GestureDetector(
                onTap: () {
                  bookingProvider.selectRideType(ride);
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFFFF3E0) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: isSelected
                        ? Border.all(color: const Color(0xFFFF9500), width: 2)
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Vehicle Icon
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(ride.icon, size: 28, color: ride.iconColor),
                      ),
                      const SizedBox(width: 16),
                      // Vehicle Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  ride.name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.black,
                                  ),
                                ),
                                Text(
                                  "₹${ride.estimatedPrice.toStringAsFixed(0)}",
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.secondary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "${ride.maxPassengers} Passengers",
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppColors.grey600,
                                  ),
                                ),
                                Text(
                                  "${index + 1} mins away",
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppColors.grey600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        const Icon(
                          Icons.check_circle,
                          color: Color(0xFFFF9500),
                          size: 28,
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          // Book Ride Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: bookingProvider.selectedRideType == null
                  ? null
                  : () async {
                      final bookingProvider = context.read<BookingProvider>();
                      await bookingProvider.requestRide({
                        'pickupLocation': {
                          'type': 'Point',
                          'coordinates': [
                            bookingProvider.pickupLocation?.longitude ?? 0.0,
                            bookingProvider.pickupLocation?.latitude ?? 0.0
                          ],
                          'address': bookingProvider.pickupLocation?.address
                        },
                        'dropLocation': {
                          'type': 'Point',
                          'coordinates': [
                            bookingProvider.dropLocation?.longitude ?? 0.0,
                            bookingProvider.dropLocation?.latitude ?? 0.0
                          ],
                          'address': bookingProvider.dropLocation?.address
                        },
                        'fare':
                            bookingProvider.selectedRideType?.estimatedPrice,
                        'distance': bookingProvider.distance,
                        'duration': bookingProvider.estimatedTime,
                        'vehicleType': bookingProvider.selectedRideType?.name,
                        'paymentMethod': 'cash',
                      });
                      // Navigate to Searching Driver screen
                      if (mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SearchingDriverScreen(),
                          ),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF9500),
                disabledBackgroundColor: AppColors.grey300,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 0,
                minimumSize: const Size.fromHeight(56),
              ),
              child: bookingProvider.selectedRideType == null
                  ? const Text("Select a vehicle to book",
                      style: TextStyle(fontSize: 18))
                  : Text(
                      "Book Ride",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    return Consumer<SearchProvider>(
      builder: (context, searchProvider, child) {
        if (searchProvider.status == SearchStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (searchProvider.status == SearchStatus.error) {
          return Center(child: Text(searchProvider.errorMessage));
        }
        if (searchProvider.predictions.isEmpty) {
          return const Center(child: Text("No results found"));
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: searchProvider.predictions.length,
          itemBuilder: (context, index) {
            final prediction = searchProvider.predictions[index];
            return GestureDetector(
              onTap: () => _onPredictionSelected(prediction),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.grey100,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.location_pin,
                          color: AppColors.secondary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            prediction.mainText,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            prediction.secondaryText,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.grey600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRecentLocations() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recent Locations from AddressProvider
          Consumer<AddressProvider>(
            builder: (context, addressProvider, child) {
              if (addressProvider.addresses.isEmpty) {
                return const SizedBox.shrink();
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Recent Places",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...addressProvider.addresses.map((address) {
                    IconData icon;
                    switch (address.type) {
                      case 'home':
                        icon = Icons.home;
                        break;
                      case 'work':
                        icon = Icons.work;
                        break;
                      default:
                        icon = Icons.location_pin;
                    }
                    return GestureDetector(
                      onTap: () async {
                        // We need PlaceDetails for this address, for now we'll use dummy coordinates
                        // In a real app, you'd call Geocoding API here
                        final displayLabel = _isNumericOnly(address.label)
                            ? address.address
                            : address.label;
                        final placeDetails = PlaceDetails(
                          placeId: address.id,
                          name: displayLabel,
                          address: address.address,
                          latitude: 11.0168,
                          longitude: 76.9558,
                        );

                        if (_activeField == LocationField.pickup) {
                          context
                              .read<BookingProvider>()
                              .setPickupLocation(placeDetails);
                          _pickupController.text = displayLabel;
                        } else {
                          context
                              .read<BookingProvider>()
                              .setDropLocation(placeDetails);
                          _dropController.text = displayLabel;
                          // Calculate route and navigate
                          await context
                              .read<BookingProvider>()
                              .calculateRoute();
                          if (mounted) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const RideBookingScreen(),
                              ),
                            );
                          }
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppColors.grey100,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(icon,
                                  color: AppColors.secondary, size: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    address.label,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    address.address,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: AppColors.grey600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.favorite_border, size: 20),
                              onPressed: () {},
                              color: AppColors.grey400,
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
