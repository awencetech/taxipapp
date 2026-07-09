import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/dashboard_viewmodel.dart';
import 'viewmodels/driver_viewmodel.dart';
import 'viewmodels/vehicle_viewmodel.dart';
import 'viewmodels/trip_viewmodel.dart';
import 'viewmodels/earning_viewmodel.dart';
import 'viewmodels/theme_viewmodel.dart';
import 'services/profile_service.dart';
import 'services/api_service.dart';
import 'views/auth/login_screen.dart';
import 'views/dashboard/dashboard_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    MultiProvider(
      providers: [
        Provider<ApiService>(create: (_) => ApiService()),
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
}

class VendorApp extends StatelessWidget {
  const VendorApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeVM = Provider.of<ThemeViewModel>(context);
    return MaterialApp(
      title: 'TaxiNanban Vendor',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeVM.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: const AuthCheck(),
    );
  }
}

class AuthCheck extends StatefulWidget {
  const AuthCheck({super.key});

  @override
  State<AuthCheck> createState() => _AuthCheckState();
}

class _AuthCheckState extends State<AuthCheck> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);

    if (_isLoading || authViewModel.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (authViewModel.isLoggedIn) {
      return const DashboardScreen();
    }

    return const LoginScreen();
  }
}
