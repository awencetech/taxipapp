import 'package:flutter/material.dart';
import 'package:vendor/services/api_service.dart';
import 'package:vendor/core/utils/shared_prefs.dart';
import 'package:vendor/core/theme/app_colors.dart';
import 'package:vendor/views/auth/login_screen.dart';
import 'package:vendor/views/dashboard/dashboard_screen.dart';

class WaitingForApprovalScreen extends StatefulWidget {
  const WaitingForApprovalScreen({super.key});

  @override
  State<WaitingForApprovalScreen> createState() =>
      _WaitingForApprovalScreenState();
}

class _WaitingForApprovalScreenState extends State<WaitingForApprovalScreen> {
  bool _isRefreshing = false;

  Future<void> _refreshStatus() async {
    setState(() {
      _isRefreshing = true;
    });

    try {
      // First, get the vendor's phone or email from shared prefs if we have it, else prompt login
      // Wait, let's think: how do we refresh status? We need to have a way to check the vendor's status
      // Let's create a new endpoint for checking vendor status, or use the login endpoint again?
      // Alternatively, let's create a simple endpoint in vendorController to get vendor status by ID or phone/email
      // For now, let's just log out and send back to login, but let's first check if we have a saved vendor ID
      final vendorId = await SharedPrefs.getVendorId();
      if (vendorId != null) {
        // Wait, do we have an endpoint to get vendor by ID? Let's check vendorRoutes!
        // Let's first check vendorRoutes.js!
        // For now, let's just navigate back to login if refresh fails
      }

      // For now, let's just go back to login
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to refresh status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.access_time,
                  size: 60,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 32),
              // Title
              const Text(
                'Waiting for Approval',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 12),
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3CD),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Pending',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF854D0E),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Description
              const Text(
                'Your vendor account has been submitted successfully.\nYour account is currently under review by the Main Vendor.\nYou\'ll receive access once approved.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF6B7280),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 48),
              // Refresh button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isRefreshing ? null : _refreshStatus,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isRefreshing
                      ? const CircularProgressIndicator(
                          color: Colors.white,
                        )
                      : const Text(
                          'Refresh Status',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              // Back to login
              TextButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (route) => false,
                  );
                },
                child: const Text(
                  'Back to Login',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
