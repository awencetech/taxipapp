import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/booking_provider.dart';
import '../../core/providers/location_provider.dart';
import '../../core/models/place_details_model.dart';
import '../../core/models/ride_type.dart';
import 'pickup_confirmation_screen.dart';

class RideBookingScreen extends StatefulWidget {
  const RideBookingScreen({super.key});

  @override
  State<RideBookingScreen> createState() => _RideBookingScreenState();
}

class _RideBookingScreenState extends State<RideBookingScreen> {
  final Completer<GoogleMapController> _mapController = Completer();
  final Set<Marker> _markers = {};
  final List<LatLng> _polylineCoordinates = [];
  String _selectedPaymentMethod = 'Cash';
  String? _appliedCoupon;
  final List<Map<String, dynamic>> _coupons = [
    {'code': 'WELCOME50', 'discount': 50},
    {'code': 'FIRSTRIDE', 'discount': 100},
    {'code': 'TAXINANBAN20', 'discount': 20},
  ];
  final List<String> _paymentMethods = ['Cash', 'UPI', 'Wallet', 'Card'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _updateMapMarkersAndRoute();
    });
  }

  Future<void> _updateMapMarkersAndRoute() async {
    final bookingProvider = context.read<BookingProvider>();
    if (bookingProvider.pickupLocation == null ||
        bookingProvider.dropLocation == null) {
      return;
    }

    setState(() {
      _markers.clear();
      _markers.add(Marker(
        markerId: const MarkerId('pickup'),
        position: LatLng(
          bookingProvider.pickupLocation!.latitude,
          bookingProvider.pickupLocation!.longitude,
        ),
        infoWindow: InfoWindow(
          title: 'Pickup',
          snippet: bookingProvider.pickupLocation!.name,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ));
      _markers.add(Marker(
        markerId: const MarkerId('drop'),
        position: LatLng(
          bookingProvider.dropLocation!.latitude,
          bookingProvider.dropLocation!.longitude,
        ),
        infoWindow: InfoWindow(
          title: 'Drop',
          snippet: bookingProvider.dropLocation!.name,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ));

      _polylineCoordinates.clear();
      _polylineCoordinates.add(LatLng(
        bookingProvider.pickupLocation!.latitude,
        bookingProvider.pickupLocation!.longitude,
      ));
      _polylineCoordinates.add(LatLng(
        bookingProvider.dropLocation!.latitude,
        bookingProvider.dropLocation!.longitude,
      ));
    });

    if (_mapController.isCompleted) {
      final controller = await _mapController.future;
      final bounds = LatLngBounds(
        southwest: LatLng(
          bookingProvider.pickupLocation!.latitude <
                  bookingProvider.dropLocation!.latitude
              ? bookingProvider.pickupLocation!.latitude
              : bookingProvider.dropLocation!.latitude,
          bookingProvider.pickupLocation!.longitude <
                  bookingProvider.dropLocation!.longitude
              ? bookingProvider.pickupLocation!.longitude
              : bookingProvider.dropLocation!.longitude,
        ),
        northeast: LatLng(
          bookingProvider.pickupLocation!.latitude >
                  bookingProvider.dropLocation!.latitude
              ? bookingProvider.pickupLocation!.latitude
              : bookingProvider.dropLocation!.latitude,
          bookingProvider.pickupLocation!.longitude >
                  bookingProvider.dropLocation!.longitude
              ? bookingProvider.pickupLocation!.longitude
              : bookingProvider.dropLocation!.longitude,
        ),
      );
      controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
    }
  }

  double _calculateFare(RideType rideType, double distance) {
    double baseFare = 0;
    double perKmRate = 0;

    switch (rideType.name.toLowerCase()) {
      case 'bike':
        baseFare = 30;
        perKmRate = 8;
        break;
      case 'auto':
        baseFare = 50;
        perKmRate = 12;
        break;
      case 'cab economy':
      case 'mini':
        baseFare = 70;
        perKmRate = 15;
        break;
      case 'cab premium':
      case 'sedan':
        baseFare = 100;
        perKmRate = 18;
        break;
      case 'cab xl':
      case 'suv':
        baseFare = 150;
        perKmRate = 25;
        break;
      default:
        baseFare = 50;
        perKmRate = 10;
    }

    double fare = baseFare + (distance * perKmRate);

    if (_appliedCoupon != null) {
      final coupon = _coupons
          .firstWhere((c) => c['code'] == _appliedCoupon, orElse: () => {});
      if (coupon.isNotEmpty) {
        final discount = coupon['discount'] as double? ?? 0;
        fare = fare - discount;
        if (fare < 0) fare = 0;
      }
    }

    return fare;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // Google Map
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target:
                    context.read<LocationProvider>().currentPosition != null
                        ? LatLng(
                            context.read<LocationProvider>().currentPosition!.latitude,
                            context.read<LocationProvider>().currentPosition!.longitude,
                          )
                        : const LatLng(11.0168, 76.9558),
                zoom: 16,
              ),
              markers: _markers,
              polylines: _polylineCoordinates.length > 1
                  ? {
                      Polyline(
                        polylineId: const PolylineId('route'),
                        points: _polylineCoordinates,
                        color: Colors.blue,
                        width: 5,
                      )
                    }
                  : {},
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomGesturesEnabled: true,
              scrollGesturesEnabled: true,
              rotateGesturesEnabled: false,
              tiltGesturesEnabled: false,
              onMapCreated: (controller) {
                _mapController.complete(controller);
                _updateMapMarkersAndRoute();
              },
            ),

            // Back button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ),
            ),

            // Recenter button
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.my_location),
                  onPressed: () async {
                    final locationProvider =
                        context.read<LocationProvider>();
                    final pos = await locationProvider.getCurrentLocation();
                    if (pos != null && _mapController.isCompleted) {
                      final controller = await _mapController.future;
                      controller.animateCamera(
                        CameraUpdate.newLatLngZoom(pos, 16),
                      );
                    }
                  },
                ),
              ),
            ),

            // Pickup and Drop address cards
            Positioned(
              top: 80,
              left: 16,
              right: 16,
              child: Consumer<BookingProvider>(
                builder: (context, bookingProvider, child) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (bookingProvider.pickupLocation != null)
                        _buildAddressCard(
                            bookingProvider.pickupLocation!, true),
                      const SizedBox(height: 8),
                      if (bookingProvider.dropLocation != null)
                        _buildAddressCard(
                            bookingProvider.dropLocation!, false),
                    ],
                  );
                },
              ),
            ),

            // Bottom sheet
            DraggableScrollableSheet(
              initialChildSize: 0.5,
              minChildSize: 0.4,
              maxChildSize: 0.85,
              builder: (context, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 20,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(20),
                    children: [
                      // Drag indicator
                      Center(
                        child: Container(
                          width: 40,
                          height: 5,
                          decoration: BoxDecoration(
                            color: AppColors.grey300,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Trip Summary Section
                      Consumer<BookingProvider>(
                        builder: (context, bookingProvider, child) {
                          return Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.grey100,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Trip Summary',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.black,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // Pickup
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.location_on,
                                        color: Colors.green, size: 24),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Pickup',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.grey600,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            bookingProvider.pickupLocation
                                                    ?.name ??
                                                'Pickup Location',
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
                                // Drop
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.location_pin,
                                        color: Colors.red, size: 24),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Drop',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.grey600,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            bookingProvider.dropLocation
                                                    ?.name ??
                                                'Drop Location',
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
                                const SizedBox(height: 16),
                                // Distance and Time
                                Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Distance',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.grey600,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${bookingProvider.distance.toStringAsFixed(1)} km',
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
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Est. Time',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.grey600,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${bookingProvider.estimatedTime} mins',
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
                          );
                        },
                      ),
                      const SizedBox(height: 20),

                      // Choose a Ride Title
                      const Text(
                        'Choose a ride',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.black,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Vehicle List
                      Consumer<BookingProvider>(
                        builder: (context, bookingProvider, child) {
                          final rideTypes = RideType.getDummyRides(
                              bookingProvider.distance);
                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: rideTypes.length,
                            itemBuilder: (context, index) {
                              final rideType = rideTypes[index];
                              final isSelected = bookingProvider
                                      .selectedRideType?.id ==
                                  rideType.id;
                              final fare = _calculateFare(
                                  rideType, bookingProvider.distance);
                              return GestureDetector(
                                onTap: () {
                                  bookingProvider.selectRideType(rideType);
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFFFFF3E0)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: isSelected
                                        ? Border.all(
                                            color: const Color(0xFFFF9800),
                                            width: 2,
                                          )
                                        : Border.all(
                                            color: AppColors.grey300,
                                            width: 1,
                                          ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.05),
                                        blurRadius: 10,
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
                                          color: AppColors.grey100,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          rideType.icon,
                                          size: 28,
                                          color: rideType.iconColor,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      // Details
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  rideType.name,
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.w600,
                                                    color: AppColors.black,
                                                  ),
                                                ),
                                                Text(
                                                  '₹${fare.toStringAsFixed(0)}',
                                                  style: const TextStyle(
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.w700,
                                                    color: AppColors.secondary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  '👤 ${rideType.maxPassengers}',
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    color: AppColors.grey600,
                                                  ),
                                                ),
                                                Text(
                                                  '${rideType.estimatedTime} mins away',
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
                                          color: Color(0xFFFF9800),
                                          size: 28,
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 20),

                      // Payment Method and Coupon
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _showPaymentModal(),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12, horizontal: 16),
                                decoration: BoxDecoration(
                                  color: AppColors.grey100,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.payment,
                                      size: 20,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _selectedPaymentMethod,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.black,
                                      ),
                                    ),
                                    const Spacer(),
                                    const Icon(Icons.arrow_drop_down),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _showCouponModal(),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12, horizontal: 16),
                                decoration: BoxDecoration(
                                  color: AppColors.grey100,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.local_offer,
                                      size: 20,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _appliedCoupon != null
                                          ? _appliedCoupon!
                                          : 'Apply Coupon',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: _appliedCoupon != null
                                            ? AppColors.primary
                                            : AppColors.grey600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Book Ride Button
                      Consumer<BookingProvider>(
                        builder: (context, bookingProvider, child) {
                          return SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: bookingProvider.selectedRideType ==
                                      null
                                  ? null
                                  : () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              PickupConfirmationScreen(
                                            bookingProvider: bookingProvider,
                                            selectedPaymentMethod:
                                                _selectedPaymentMethod,
                                            appliedCoupon: _appliedCoupon,
                                            calculatedFare: _calculateFare(
                                                bookingProvider.selectedRideType!,
                                                bookingProvider.distance),
                                          ),
                                        ),
                                      );
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFFC107),
                                disabledBackgroundColor: AppColors.grey300,
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Text(
                                bookingProvider.selectedRideType == null
                                    ? 'SELECT A RIDE'
                                    : 'BOOK ${bookingProvider.selectedRideType?.name.toUpperCase()}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressCard(PlaceDetails place, bool isPickup) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isPickup ? Icons.location_on : Icons.location_pin,
            color: isPickup ? Colors.green : Colors.red,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPickup ? 'Pickup' : 'Drop',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.grey600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  place.name,
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
    );
  }

  void _showPaymentModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Payment Method',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: 24),
            ..._paymentMethods.map((method) => GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedPaymentMethod = method;
                    });
                    Navigator.pop(context);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _selectedPaymentMethod == method
                          ? const Color(0xFFFFF3E0)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: _selectedPaymentMethod == method
                          ? Border.all(
                              color: const Color(0xFFFF9800),
                              width: 2,
                            )
                          : Border.all(
                              color: AppColors.grey300,
                              width: 1,
                            ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          method == 'Cash'
                              ? Icons.money
                              : method == 'UPI'
                                  ? Icons.phone_android
                                  : method == 'Wallet'
                                      ? Icons.account_balance_wallet
                                      : Icons.credit_card,
                          color: AppColors.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          method,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.black,
                          ),
                        ),
                        const Spacer(),
                        if (_selectedPaymentMethod == method)
                          const Icon(
                            Icons.check_circle,
                            color: Color(0xFFFF9800),
                            size: 24,
                          ),
                      ],
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  void _showCouponModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Apply Coupon',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: 24),
            ..._coupons.map((coupon) {
              final isSelected = _appliedCoupon == coupon['code'];
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _appliedCoupon =
                        isSelected ? null : coupon['code'] as String?;
                  });
                  Navigator.pop(context);
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFFFF3E0)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: isSelected
                        ? Border.all(
                            color: const Color(0xFFFF9800),
                            width: 2,
                          )
                        : Border.all(
                            color: AppColors.grey300,
                            width: 1,
                          ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.local_offer,
                        color: Color(0xFFFF9800),
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        coupon['code'] as String,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.black,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '₹${coupon['discount']} OFF',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
