import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/booking_provider.dart';
import 'core/providers/location_provider.dart';
import 'core/providers/admin_provider.dart';
import 'core/providers/address_provider.dart';
import 'core/providers/payment_provider.dart';
import 'core/providers/notification_provider.dart';
import 'core/providers/ticket_provider.dart';
import 'core/providers/search_provider.dart';
import 'splash_screen.dart';
import 'core/theme/app_theme.dart';
import 'features/booking/location_selection_screen.dart';
import 'features/booking/ride_map_screen.dart';
import 'features/booking/driver_match_screen.dart';
import 'features/booking/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyCANjdwwqHJTgWoinu2lrW6Bgeubd_533g",
      authDomain: "taxiapp-88e0f.firebaseapp.com",
      projectId: "taxiapp-88e0f",
      storageBucket: "taxiapp-88e0f.firebasestorage.app",
      messagingSenderId: "652222620401",
      appId: "1:652222620401:android:5dc47dab34c59f4539ff50",
    ),
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => BookingProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
        ChangeNotifierProvider(create: (_) => AddressProvider()),
        ChangeNotifierProvider(create: (_) => PaymentProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => TicketProvider()),
        ChangeNotifierProvider(create: (_) => SearchProvider()),
      ],
      child: const TaxiNanbanApp(),
    ),
  );
}

class TaxiNanbanApp extends StatelessWidget {
  const TaxiNanbanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Taxi Nanban',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
      routes: {
        '/home': (context) => const HomeScreen(),
        '/location-selection': (context) => const LocationSelectionScreen(),
        '/ride-map': (context) => const RideMapScreen(),
        '/driver-match': (context) => const DriverMatchScreen(),
      },
    );
  }
}
