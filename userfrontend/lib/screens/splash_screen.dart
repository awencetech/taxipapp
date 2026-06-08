import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  _checkAuth() async {
    final authProvider = context.read<AuthProvider>();
    await Future.delayed(const Duration(seconds: 2));
    await authProvider.checkAuthStatus();

    if (mounted) {
      if (authProvider.isLoggedIn) {
        if (authProvider.user?.role == 'admin') {
          Navigator.pushReplacementNamed(context, '/admin');
        } else {
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_taxi, size: 100, color: Colors.red),
            SizedBox(height: 20),
            Text(
              "Taxi Nanban",
              style: TextStyle(
                  fontSize: 32, fontWeight: FontWeight.bold, color: Colors.red),
            ),
            SizedBox(height: 10),
            CircularProgressIndicator(color: Colors.red),
          ],
        ),
      ),
    );
  }
}
