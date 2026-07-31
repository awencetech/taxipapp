import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../viewmodels/auth_viewmodel.dart';
import 'login_screen.dart';
import '../dashboard/dashboard_screen.dart';
import 'registration_declined_screen.dart';

class WaitingForApprovalScreen extends StatefulWidget {
  const WaitingForApprovalScreen({super.key});

  @override
  State<WaitingForApprovalScreen> createState() =>
      _WaitingForApprovalScreenState();
}

class _WaitingForApprovalScreenState extends State<WaitingForApprovalScreen> {
  bool _isRefreshing = false;

  Future<void> _refreshStatus() async {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);

    setState(() {
      _isRefreshing = true;
    });

    try {
      final status = await authViewModel.refreshApprovalStatus();

      if (mounted) {
        if (status == AuthStatus.success) {
          // Approved, navigate to dashboard
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const DashboardScreen()),
            (route) => false,
          );
        } else if (status == AuthStatus.declined) {
          // Declined, navigate to declined screen
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => const RegistrationDeclinedScreen(),
            ),
            (route) => false,
          );
        } else {
          // Still pending, stay on this screen and show snackbar
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Still waiting for approval'),
              backgroundColor: Colors.orange,
            ),
          );
        }
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
      backgroundColor: Colors.white,
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
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.access_time,
                  size: 60,
                  color: AppTheme.primaryColor,
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
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isRefreshing
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Refresh Status',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              // Back to login
              TextButton(
                    onPressed: () async {
                      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
                      await authViewModel.logout();
                      if (mounted) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                          (route) => false,
                        );
                      }
                    },
                    child: Text(
                      'Back to Login',
                      style: TextStyle(fontSize: 14, color: AppTheme.primaryColor),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
