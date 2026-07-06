import 'package:flutter/material.dart';

enum VehicleType { bike, auto, economy, premium, xl }

class RideType {
  final String id;
  final String name;
  final VehicleType type;
  final String description;
  final int basePrice;
  final int pricePerKm;
  final int estimatedPrice;
  final int estimatedTime; // in minutes
  final int maxPassengers;
  final IconData icon;
  final Color iconColor;
  final String imageUrl;

  const RideType({
    required this.id,
    required this.name,
    required this.type,
    required this.description,
    required this.basePrice,
    required this.pricePerKm,
    required this.estimatedPrice,
    required this.estimatedTime,
    required this.maxPassengers,
    required this.icon,
    required this.iconColor,
    required this.imageUrl,
  });

  static List<RideType> getDummyRides(double distanceKm) {
    return [
      RideType(
        id: 'bike',
        name: 'Bike',
        type: VehicleType.bike,
        description: 'Fast & affordable',
        basePrice: 10,
        pricePerKm: 8,
        estimatedPrice: _calculatePrice(10, 8, distanceKm),
        estimatedTime: (distanceKm * 2).round(),
        maxPassengers: 1,
        icon: Icons.two_wheeler,
        iconColor: const Color(0xFFFF6B00),
        imageUrl: 'https://images.unsplash.com/photo-1558981403-c5f9899a28bc?w=400&auto=format&fit=crop&q=80',
      ),
      RideType(
        id: 'auto',
        name: 'Auto',
        type: VehicleType.auto,
        description: 'Affordable & safe',
        basePrice: 20,
        pricePerKm: 12,
        estimatedPrice: _calculatePrice(20, 12, distanceKm),
        estimatedTime: (distanceKm * 2.5).round(),
        maxPassengers: 3,
        icon: Icons.electric_rickshaw,
        iconColor: const Color(0xFF2E7D32),
        imageUrl: 'https://images.unsplash.com/photo-1604712042546-7a9b125b0b76?w=400&auto=format&fit=crop&q=80',
      ),
      RideType(
        id: 'economy',
        name: 'Cab Economy',
        type: VehicleType.economy,
        description: 'Comfortable rides',
        basePrice: 40,
        pricePerKm: 14,
        estimatedPrice: _calculatePrice(40, 14, distanceKm),
        estimatedTime: (distanceKm * 2.2).round(),
        maxPassengers: 4,
        icon: Icons.directions_car,
        iconColor: const Color(0xFF1565C0),
        imageUrl: 'https://images.unsplash.com/photo-1549317661-bd32c8ce0db2?w=400&auto=format&fit=crop&q=80',
      ),
      RideType(
        id: 'premium',
        name: 'Cab Premium',
        type: VehicleType.premium,
        description: 'Premium experience',
        basePrice: 60,
        pricePerKm: 18,
        estimatedPrice: _calculatePrice(60, 18, distanceKm),
        estimatedTime: (distanceKm * 2.4).round(),
        maxPassengers: 4,
        icon: Icons.local_taxi,
        iconColor: const Color(0xFF6A1B9A),
        imageUrl: 'https://images.unsplash.com/photo-1580273916550-e323be2ae537?w=400&auto=format&fit=crop&q=80',
      ),
      RideType(
        id: 'xl',
        name: 'Cab XL',
        type: VehicleType.xl,
        description: 'For groups & luggage',
        basePrice: 80,
        pricePerKm: 22,
        estimatedPrice: _calculatePrice(80, 22, distanceKm),
        estimatedTime: (distanceKm * 2.6).round(),
        maxPassengers: 6,
        icon: Icons.airport_shuttle,
        iconColor: const Color(0xFFC62828),
        imageUrl: 'https://images.unsplash.com/photo-1519641471654-76ce0107ad1b?w=400&auto=format&fit=crop&q=80',
      ),
    ];
  }

  static int _calculatePrice(int base, int perKm, double distance) {
    return (base + (perKm * distance)).round();
  }
}

class PaymentMethod {
  final String id;
  final String name;
  final IconData icon;
  final Color color;

  const PaymentMethod({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });

  static const List<PaymentMethod> methods = [
    PaymentMethod(
      id: 'cash',
      name: 'Cash',
      icon: Icons.money,
      color: Color(0xFF43A047),
    ),
    PaymentMethod(
      id: 'wallet',
      name: 'Wallet',
      icon: Icons.account_balance_wallet,
      color: Color(0xFFFFA000),
    ),
    PaymentMethod(
      id: 'card',
      name: 'Card',
      icon: Icons.credit_card,
      color: Color(0xFF1E88E5),
    ),
  ];
}
