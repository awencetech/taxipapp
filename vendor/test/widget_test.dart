// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:vendorfrontend/main.dart';
import 'package:vendorfrontend/viewmodels/auth_viewmodel.dart';
import 'package:vendorfrontend/viewmodels/dashboard_viewmodel.dart';
import 'package:vendorfrontend/viewmodels/driver_viewmodel.dart';
import 'package:vendorfrontend/viewmodels/vehicle_viewmodel.dart';
import 'package:vendorfrontend/viewmodels/trip_viewmodel.dart';
import 'package:vendorfrontend/viewmodels/earning_viewmodel.dart';
import 'package:vendorfrontend/viewmodels/theme_viewmodel.dart';
import 'package:vendorfrontend/services/profile_service.dart';
import 'package:vendorfrontend/services/api_service.dart';

void main() {
  testWidgets('Vendor App starts smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    final apiService = ApiService();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<ApiService>(create: (_) => apiService),
          ChangeNotifierProvider(
            create: (context) => AuthViewModel(
              apiService: Provider.of<ApiService>(context, listen: false),
            ),
          ),
          ChangeNotifierProvider(
            create: (context) => DashboardViewModel(
              apiService: Provider.of<ApiService>(context, listen: false),
            ),
          ),
          ChangeNotifierProvider(
            create: (context) => DriverViewModel(
              apiService: Provider.of<ApiService>(context, listen: false),
            ),
          ),
          ChangeNotifierProvider(
            create: (context) => VehicleViewModel(
              apiService: Provider.of<ApiService>(context, listen: false),
            ),
          ),
          ChangeNotifierProvider(
            create: (context) => TripViewModel(
              apiService: Provider.of<ApiService>(context, listen: false),
            ),
          ),
          ChangeNotifierProvider(
            create: (context) => EarningViewModel(
              apiService: Provider.of<ApiService>(context, listen: false),
            ),
          ),
          ChangeNotifierProvider(create: (_) => ThemeViewModel()),
          ChangeNotifierProvider(create: (_) => ProfileService()),
        ],
        child: const VendorApp(),
      ),
    );

    // Verify that the app starts (either login or dashboard screen)
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
