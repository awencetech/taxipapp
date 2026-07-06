import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/booking_provider.dart';
import '../../core/providers/location_provider.dart';
import '../../core/models/ride_type.dart';
import 'pickup_confirmation_screen.dart';
import 'keep_alive_map.dart';

class RideBookingScreen extends StatefulWidget {
  const RideBookingScreen({super.key});

  @override
  State<RideBookingScreen> createState() => _RideBookingScreenState();
}

class _RideBookingScreenState extends State<RideBookingScreen> {
  GoogleMapController? _mapController;
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
    Provider.of<BookingProvider>(context, listen: false)
        .addListener(_onBookingProviderChanged);
  }

  @override
  void dispose() {
    Provider.of<BookingProvider>(context, listen: false)
        .removeListener(_onBookingProviderChanged);
    super.dispose();
  }

  void _onBookingProviderChanged() {
    final bookingProvider =
        Provider.of<BookingProvider>(context, listen: false);
    if (bookingProvider.error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              "Directions API Error: ${bookingProvider.error}. Retrying..."),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
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
      final coupon = _coupons.firstWhere((c) => c['code'] == _appliedCoupon,
          orElse: () => {});
      if (coupon.isNotEmpty) {
        final discount = coupon['discount'] as double? ?? 0;
        fare = fare - discount;
        if (fare < 0) fare = 0;
      }
    }

    return fare;
  }

  Widget _buildTripSummary(BookingProvider bookingProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
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
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on, color: Colors.green, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pickup',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.grey600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      bookingProvider.pickupLocation?.name ?? 'Pickup Location',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            margin: const EdgeInsets.only(left: 9),
            width: 2,
            height: 16,
            color: AppColors.grey300,
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_pin, color: Colors.red, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Drop',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.grey600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      bookingProvider.dropLocation?.name ?? 'Drop Location',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
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
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Distance',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.grey600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        bookingProvider.distanceText.isNotEmpty
                            ? bookingProvider.distanceText
                            : '${bookingProvider.distance.toStringAsFixed(1)} km',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Est. Time',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.grey600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        bookingProvider.durationText.isNotEmpty
                            ? bookingProvider.durationText
                            : '${bookingProvider.estimatedTime} mins',
                        style: const TextStyle(
                          fontSize: 18,
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Consumer<BookingProvider>(
            builder: (context, bookingProvider, child) {
              return KeepAliveMap(
                pickupLocation: bookingProvider.pickupLocation,
                dropLocation: bookingProvider.dropLocation,
                polylinePoints: bookingProvider.polylinePoints,
                onMapCreated: (controller) {
                  _mapController = controller;
                },
              );
            },
          ),
          Consumer<BookingProvider>(
            builder: (context, bookingProvider, child) {
              if (bookingProvider.isLoading) {
                return Container(
                  color: Colors.black.withValues(alpha: 0.15),
                  child: const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          Positioned(
            top: 16 + MediaQuery.of(context).padding.top,
            left: 16,
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
          Positioned(
            top: 16 + MediaQuery.of(context).padding.top,
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
                  final locationProvider = context.read<LocationProvider>();
                  final pos = await locationProvider.getCurrentLocation();
                  if (pos != null && _mapController != null) {
                    _mapController!.animateCamera(
                      CameraUpdate.newLatLngZoom(pos, 16),
                    );
                  }
                },
              ),
            ),
          ),
          DraggableScrollableSheet(
            initialChildSize: 0.38,
            minChildSize: 0.32,
            maxChildSize: 0.90,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 15,
                      offset: Offset(0, -3),
                    ),
                  ],
                ),
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 5,
                        margin: const EdgeInsets.only(top: 12, bottom: 12),
                        decoration: BoxDecoration(
                          color: AppColors.grey300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    Consumer<BookingProvider>(
                      builder: (context, bookingProvider, child) {
                        return _buildTripSummary(bookingProvider);
                      },
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Choose a ride',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.black,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Consumer<BookingProvider>(
                      builder: (context, bookingProvider, child) {
                        final rideTypes = RideType.getDummyRides(
                            bookingProvider.distance);
                        return Column(
                          children: rideTypes.asMap().entries.map((entry) {
                            final rideType = entry.value;
                            final isSelected =
                                bookingProvider.selectedRideType?.id ==
                                    rideType.id;
                            final fare = _calculateFare(
                                rideType, bookingProvider.distance);

                            return GestureDetector(
                              onTap: bookingProvider.isLoading
                                  ? null
                                  : () {
                                      bookingProvider
                                          .selectRideType(rideType);
                                    },
                              child: Opacity(
                                opacity: bookingProvider.isLoading
                                    ? 0.5
                                    : 1.0,
                                child: Container(
                                  margin:
                                      const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFFFFF3E0)
                                        : Colors.white,
                                    borderRadius:
                                        BorderRadius.circular(16),
                                    border: isSelected
                                        ? Border.all(
                                            color: const Color(
                                                0xFFFF9800),
                                            width: 2)
                                        : Border.all(
                                            color: AppColors.grey300,
                                            width: 1),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          child: Image.network(
                                            rideType.imageUrl,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Container(
                                                color: Colors.grey[200],
                                                child: Icon(
                                                  rideType.icon,
                                                  color: rideType.iconColor,
                                                  size: 32,
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
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
                                                  style:
                                                      const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight:
                                                        FontWeight.w600,
                                                    color:
                                                        AppColors.black,
                                                  ),
                                                ),
                                                Text(
                                                  '₹${fare.toStringAsFixed(0)}',
                                                  style:
                                                      const TextStyle(
                                                    fontSize: 18,
                                                    fontWeight:
                                                        FontWeight.w700,
                                                    color: AppColors
                                                        .secondary,
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
                                                  style:
                                                      const TextStyle(
                                                    fontSize: 13,
                                                    color: AppColors
                                                        .grey600,
                                                  ),
                                                ),
                                                Text(
                                                  '${rideType.estimatedTime} mins away',
                                                  style:
                                                      const TextStyle(
                                                    fontSize: 13,
                                                    color: AppColors
                                                        .grey600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (isSelected) ...[
                                        const SizedBox(width: 8),
                                        const Icon(
                                          Icons.check_circle,
                                          color: Color(0xFFFF9800),
                                          size: 24,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _showPaymentModal(),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 12),
                              decoration: BoxDecoration(
                                color: AppColors.grey100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.payment,
                                      size: 18,
                                      color: AppColors.primary),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      _selectedPaymentMethod,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.black,
                                      ),
                                    ),
                                  ),
                                  const Icon(Icons.arrow_drop_down,
                                      size: 20),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _showCouponModal(),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 12),
                              decoration: BoxDecoration(
                                color: AppColors.grey100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.local_offer,
                                      size: 18,
                                      color: AppColors.primary),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      _appliedCoupon ?? 'Apply Coupon',
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: _appliedCoupon != null
                                            ? AppColors.primary
                                            : AppColors.grey600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Consumer<BookingProvider>(
                      builder: (context, bookingProvider, child) {
                        return SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: bookingProvider
                                            .selectedRideType ==
                                        null ||
                                    bookingProvider.isLoading
                                ? null
                                : () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            PickupConfirmationScreen(
                                          bookingProvider:
                                              bookingProvider,
                                          selectedPaymentMethod:
                                              _selectedPaymentMethod,
                                          appliedCoupon: _appliedCoupon,
                                          calculatedFare: _calculateFare(
                                              bookingProvider
                                                      .selectedRideType!,
                                              bookingProvider.distance),
                                        ),
                                      ),
                                    );
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFFC107),
                              disabledBackgroundColor:
                                  AppColors.grey300,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: bookingProvider.isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.black)
                                : Text(
                                    bookingProvider.selectedRideType ==
                                            null
                                        ? 'SELECT A RIDE'
                                        : 'BOOK ${bookingProvider.selectedRideType?.name.toUpperCase()}',
                                    style: const TextStyle(
                                      fontSize: 16,
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
                    color: isSelected ? const Color(0xFFFFF3E0) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: isSelected
                        ? Border.all(
                            color: const Color(0xFFFF9800),
                            width: 2,
                          )
                        : Border.all(
                            color: AppColors.grey300,
                            width: 1),
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
