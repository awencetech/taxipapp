import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:driverfrontend/views/home/home_screen.dart';
import 'package:driverfrontend/viewmodels/auth_viewmodel.dart';
import 'google_onboarding_screen.dart';
import 'login_screen.dart';

class PendingApprovalScreen extends StatefulWidget {
  const PendingApprovalScreen({super.key});

  @override
  State<PendingApprovalScreen> createState() => _PendingApprovalScreenState();
}

class _PendingApprovalScreenState extends State<PendingApprovalScreen> {
  bool _isRefreshing = false;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    if (!mounted) return;
    setState(() {
      _hasError = false;
      _errorMessage = null;
    });

    final authViewModel = context.read<AuthViewModel>();
    final prefs = await SharedPreferences.getInstance();
    final mobile = prefs.getString('pending_mobile');
    final firebaseUid = prefs.getString('pending_firebase_uid');
    final googleId = prefs.getString('pending_google_id');

    debugPrint('Checking status with: mobile=$mobile, firebaseUid=$firebaseUid, googleId=$googleId');
    debugPrint('Current Driver ID: ${authViewModel.driver?.id}');

    try {
      final statusData = await authViewModel.getDriverStatus(
        mobile: mobile,
        firebaseUid: firebaseUid,
        googleId: googleId,
      );

      debugPrint('statusData = $statusData');

      if (statusData != null && mounted) {
        final approvalStatus = statusData['approvalStatus'];
        final rejectionReason = statusData['rejectionReason'];
        final driver = statusData['driver'];

        debugPrint('Approval Status from Backend: $approvalStatus');
        debugPrint('Backend Response: $statusData');

        if (approvalStatus == 'APPROVED') {
          debugPrint('Navigating to: HomeScreen');
          if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const HomeScreen()),
              (route) => false,
            );
          }
        } else if (approvalStatus == 'REJECTED') {
          debugPrint('Navigating to: RejectedScreen');
          if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (_) => RejectedScreen(rejectionReason: rejectionReason),
              ),
              (route) => false,
            );
          }
        }
        // If PENDING, do nothing (stay on this screen)
      } else if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Unable to check approval status. Please try again.';
        });
      }
    } catch (e) {
      debugPrint('Error checking status: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Error checking status: $e';
        });
      }
    }
  }

  Future<void> _refreshStatus() async {
    setState(() {
      _isRefreshing = true;
    });
    await _checkStatus();
    if (mounted) {
      setState(() {
        _isRefreshing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Back Arrow
              Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios,
                    color: Color(0xFF212529),
                  ),
                  onPressed: () async {
                    // Clear SharedPreferences
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.clear();

                    // Navigate to LoginScreen
                    if (mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (route) => false,
                      );
                    }
                  },
                ),
              ),
              const Spacer(),
              // Clock/Icon
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9800).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.access_time_rounded,
                  size: 70,
                  color: Color(0xFFFF9800),
                ),
              ),
              const SizedBox(height: 32),
              // Title
              const Text(
                'Approval Pending',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF212529),
                ),
              ),
              const SizedBox(height: 20),
              // Subtitle
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Your driver account is currently under review. You can start accepting rides after vendor approval.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF6C757D),
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 48),
              // Refresh Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isRefreshing ? null : _refreshStatus,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6D00),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: _isRefreshing
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Refresh Status',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),
              // Bottom text
              const Text(
                'We\'ll notify you once your account is approved.',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6C757D),
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class RejectedScreen extends StatelessWidget {
  final String? rejectionReason;
  const RejectedScreen({super.key, this.rejectionReason});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Back Arrow
              Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios,
                    color: Color(0xFF212529),
                  ),
                  onPressed: () async {
                    // Clear SharedPreferences
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.clear();

                    // Navigate to LoginScreen
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              // Rejected Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFFF44336).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  size: 60,
                  color: Color(0xFFF44336),
                ),
              ),
              const SizedBox(height: 32),
              // Title
              const Text(
                'Application Rejected',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF212529),
                ),
              ),
              const SizedBox(height: 16),
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF44336).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'REJECTED',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFF44336),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Message
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  'Your driver registration was not approved. Please contact the vendor for more information.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF6C757D),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 48),
              // Contact Support & Logout Buttons
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: OutlinedButton(
                        onPressed: () {
                          // TODO: Implement contact support functionality
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFFF6D00)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        child: const Text(
                          'Contact Support',
                          style: TextStyle(
                            color: Color(0xFFFF6D00),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () async {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.clear();
                          if (context.mounted) {
                            Provider.of<AuthViewModel>(context, listen: false).logout();
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(builder: (_) => const LoginScreen()),
                              (route) => false,
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF6D00),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        child: const Text(
                          'Logout',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
