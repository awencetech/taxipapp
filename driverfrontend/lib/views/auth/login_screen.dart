import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import 'signup_screen.dart';
import '../home/home_screen.dart';
import 'pending_approval_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _nameController = TextEditingController();
  bool _obscurePassword = true;
  bool _isPhoneLogin = true;
  bool _isOtpSent = false;
  bool _isNewDriver = false;
  String? _verificationId;
  int _resendTimer = 0;
  bool _canResend = false;

  String? _validatePhoneNumber(String value) {
    final cleaned = value.replaceAll(RegExp(r'[^\d]'), '');
    if (cleaned.length != 10) {
      return 'Phone number must be exactly 10 digits';
    }
    return null;
  }

  String _formatPhoneNumber(String input) {
    final digits = input.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.length == 10) {
      return '+91$digits';
    }
    return input;
  }

  void _startResendTimer() {
    _resendTimer = 60;
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() {
          if (_resendTimer > 0) {
            _resendTimer--;
          }
          _canResend = _resendTimer == 0;
        });
      }
      return _resendTimer > 0 && mounted;
    });
  }

  Future<void> _verifyPhoneNumber() async {
    debugPrint('=== _verifyPhoneNumber START ===');
    FocusScope.of(context).unfocus();
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);

    final error = _validatePhoneNumber(_phoneController.text);
    if (error != null) {
      debugPrint('=== _verifyPhoneNumber: Validation failed: $error ===');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error)));
      }
      return;
    }

    final formattedPhone = _formatPhoneNumber(_phoneController.text);
    debugPrint('=== Formatted Phone: $formattedPhone ===');

    // Set loading state
    authViewModel.setLoading(true);
    debugPrint('=== Loading state set to true ===');

    // Add a timeout for verifyPhoneNumber (30 seconds)
    bool isTimedOut = false;
    Timer? timeoutTimer;
    timeoutTimer = Timer(const Duration(seconds: 30), () {
      if (!isTimedOut && mounted) {
        debugPrint('=== verifyPhoneNumber TIMEOUT ===');
        isTimedOut = true;
        authViewModel.setLoading(false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('OTP request timed out. Please try again.'),
          ),
        );
      }
    });

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: formattedPhone,
        timeout: const Duration(seconds: 60), // Explicit timeout
        verificationCompleted: (PhoneAuthCredential credential) async {
          debugPrint('=== verificationCompleted ===');
          if (isTimedOut) {
            debugPrint(
              '=== verificationCompleted: Already timed out, skipping ===',
            );
            return;
          }
          isTimedOut = true;
          timeoutTimer?.cancel();
          await _signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          debugPrint('=== verificationFailed ===');
          debugPrint('Code: ${e.code}, Message: ${e.message}');
          if (isTimedOut) {
            debugPrint(
              '=== verificationFailed: Already timed out, skipping ===',
            );
            return;
          }
          isTimedOut = true;
          timeoutTimer?.cancel();
          if (mounted) {
            setState(() {
              _isOtpSent = false;
            });
            authViewModel.setLoading(false);
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('${e.code}: ${e.message}')));
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          debugPrint('=== codeSent ===');
          debugPrint(
            '=== Verification ID: $verificationId, Resend Token: $resendToken ===',
          );
          if (isTimedOut) {
            debugPrint('=== codeSent: Already timed out, skipping ===');
            return;
          }
          isTimedOut = true;
          timeoutTimer?.cancel();
          if (mounted) {
            debugPrint('=== codeSent: Mounted, updating state ===');
            setState(() {
              _verificationId = verificationId;
              _isOtpSent = true;
              _resendTimer = 60;
              _canResend = false;
            });
            authViewModel.setLoading(false);
            _startResendTimer();
            debugPrint(
              '=== codeSent: Loading stopped, resend timer started ===',
            );
          } else {
            debugPrint('=== codeSent: Not mounted ===');
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          debugPrint('=== codeAutoRetrievalTimeout ===');
          debugPrint('Verification ID: $verificationId');
          if (isTimedOut) {
            debugPrint(
              '=== codeAutoRetrievalTimeout: Already timed out, skipping ===',
            );
            return;
          }
          if (mounted) {
            setState(() {
              _verificationId = verificationId;
              _canResend = true;
            });
          }
        },
      );
    } catch (e, stackTrace) {
      debugPrint('=== Exception in verifyPhoneNumber ===');
      debugPrint('Error: $e');
      debugPrint('Stack trace: $stackTrace');
      if (isTimedOut) {
        debugPrint('=== Exception: Already timed out, skipping ===');
        return;
      }
      isTimedOut = true;
      timeoutTimer.cancel();
      if (mounted) {
        authViewModel.setLoading(false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _signInWithOtp() async {
    FocusScope.of(context).unfocus();
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);

    final otp = _otpController.text.trim();
    if (otp.isEmpty || _verificationId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter the OTP')));
      return;
    }

    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OTP must be exactly 6 digits')),
      );
      return;
    }

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );
      await _signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      debugPrint('=== FirebaseAuthException in signInWithOtp ===');
      debugPrint('Code: ${e.code}, Message: ${e.message}');
      if (mounted) {
        authViewModel.setLoading(false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${e.code}: ${e.message}')));
      }
    } catch (e) {
      debugPrint('=== Exception in signInWithOtp ===');
      if (mounted) {
        authViewModel.setLoading(false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _signInWithCredential(PhoneAuthCredential credential) async {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    authViewModel.setLoading(true);
    try {
      debugPrint('=== Signing in with credential ===');
      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );
      debugPrint('=== User Credential: $userCredential ===');

      final user = userCredential.user;
      if (user == null) {
        throw Exception('Failed to sign in: User is null');
      }

      debugPrint('=== Getting ID Token ===');
      final idToken = await user.getIdToken();
      debugPrint('=== ID Token retrieved ===');
      final firebaseUid = user.uid;
      final cleanMobile = _phoneController.text.replaceAll(
        RegExp(r'[^0-9]'),
        '',
      );

      if (mounted) {
        if (_nameController.text.trim().isNotEmpty) {
          debugPrint('=== Signing in as returning driver with name ===');
          final result = await authViewModel.signInWithFirebasePhone(
            idToken!,
            'driver',
            name: _nameController.text.trim(),
            firebaseUid: firebaseUid,
            mobile: cleanMobile,
          );
          if (result['success'] == true) {
            if (result['isNewDriver'] == true && mounted) {
              setState(() {
                _isNewDriver = true;
              });
              authViewModel.setLoading(false);
            } else if (mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const HomeScreen()),
              );
            }
          } else if (mounted) {
            authViewModel.setLoading(false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(authViewModel.error ?? 'Sign in failed')),
            );
          }
        } else {
          debugPrint('=== Signing in as new driver ===');
          final result = await authViewModel.signInWithFirebasePhone(
            idToken!,
            'driver',
            firebaseUid: firebaseUid,
            mobile: cleanMobile,
          );
          if (result['success'] == true) {
            if (result['isNewDriver'] == true && mounted) {
              setState(() {
                _isNewDriver = true;
              });
              authViewModel.setLoading(false);
            } else if (mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const HomeScreen()),
              );
            }
          } else if (mounted) {
            authViewModel.setLoading(false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(authViewModel.error ?? 'Sign in failed')),
            );
          }
        }
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('=== FirebaseAuthException ===');
      debugPrint('Code: ${e.code}, Message: ${e.message}');
      if (mounted) {
        authViewModel.setLoading(false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${e.code}: ${e.message}')));
      }
    } catch (e, stackTrace) {
      debugPrint('=== Exception in signInWithCredential ===');
      debugPrint('Error: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        authViewModel.setLoading(false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  void _handleEmailLogin() async {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email and password')),
      );
      return;
    }

    final success = await authViewModel.login(email, password);

    if (success && mounted) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authViewModel.error ?? 'Login failed')),
      );
    }
  }

  void _handleGoogleLogin() async {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    // Show full-screen loading overlay
    _showFullScreenLoading(true);

    final result = await authViewModel.loginWithGoogle();

    // Hide loading overlay
    if (mounted) {
      _showFullScreenLoading(false);
    }

    if (!mounted) return;

    if (result['success']) {
      if (result['status'] == 'APPROVED') {
        // Navigate to Home Screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      } else if (result['status'] == 'PENDING') {
        // Navigate to Pending Approval Screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const PendingApprovalScreen()),
        );
      } else if (result['status'] == 'REJECTED') {
        // Navigate to Rejected Screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) =>
                RejectedScreen(rejectionReason: result['rejectionReason']),
          ),
        );
      } else if (result['status'] == 'NOT_FOUND' ||
          result['isNewUser'] == true) {
        // Show NOT FOUND bottom sheet
        _showDriverNotFoundBottomSheet();
      }
    } else {
      // Show error dialog
      _showConnectionErrorDialog();
    }
  }

  // Show/hide full-screen loading overlay
  void _showFullScreenLoading(bool show) {
    if (show) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const _FullScreenLoadingOverlay(),
      );
    } else {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  // Show NOT FOUND bottom sheet
  void _showDriverNotFoundBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _DriverNotFoundBottomSheet(
        onRegister: () {
          Navigator.of(context).pop();
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const SignupScreen()));
        },
        onUseAnotherAccount: () async {
          final authViewModel = Provider.of<AuthViewModel>(
            context,
            listen: false,
          );
          await authViewModel.logout();
          if (mounted) {
            Navigator.of(context).pop();
          }
        },
        onClose: () => Navigator.of(context).pop(),
      ),
    );
  }

  // Show connection error dialog
  void _showConnectionErrorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Connection Problem'),
        content: const Text(
          'We couldn\'t verify your account right now. Please try again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _handleGoogleLogin();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: (_isNewDriver || _isOtpSent)
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
                onPressed: () {
                  setState(() {
                    if (_isNewDriver) {
                      _isNewDriver = false;
                      _isOtpSent = true;
                    } else {
                      _isOtpSent = false;
                      _otpController.clear();
                      _verificationId = null;
                    }
                  });
                },
              ),
            )
          : null,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              height: 300,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF2D2D2D), Color(0xFFE65100)],
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!_isNewDriver)
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.directions_car,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'TaxiNanban Driver',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Start earning today',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  const SizedBox(height: 40),
                  Text(
                    _isNewDriver ? 'Complete Profile' : 'Welcome Back',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isNewDriver
                        ? 'Tell us your name'
                        : 'Login to start accepting rides',
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
              ),
            ),

            Transform.translate(
              offset: const Offset(0, -40),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: _isNewDriver
                    ? _buildNewDriverScreen(authViewModel)
                    : (_isOtpSent
                          ? _buildOtpScreen(authViewModel)
                          : _buildLoginScreen(authViewModel)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginScreen(AuthViewModel authViewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Driver Login',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Choose your preferred login method',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
        const SizedBox(height: 24),

        Container(
          height: 45,
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Row(
            children: [
              _buildToggleButton(
                'Phone',
                _isPhoneLogin,
                () => setState(() => _isPhoneLogin = true),
              ),
              _buildToggleButton(
                'Email',
                !_isPhoneLogin,
                () => setState(() => _isPhoneLogin = false),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        if (_isPhoneLogin) ...[
          const Text(
            'Mobile Number',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: const Text(
                  '+91',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(hintText: '9876543210'),
                ),
              ),
            ],
          ),
        ] else ...[
          const Text(
            'Email Address',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              hintText: 'driver@taxinanban.com',
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Password',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              hintText: '********',
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
          ),
        ],

        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: authViewModel.isLoading
                ? null
                : (_isPhoneLogin ? _verifyPhoneNumber : _handleEmailLogin),
            child: authViewModel.isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(_isPhoneLogin ? Icons.phone_android : Icons.login),
                      const SizedBox(width: 8),
                      Text(_isPhoneLogin ? 'Send OTP' : 'Login'),
                    ],
                  ),
          ),
        ),

        const SizedBox(height: 24),

        Row(
          children: [
            Expanded(child: Divider(color: Colors.grey[300])),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'or continue with',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(child: Divider(color: Colors.grey[300])),
          ],
        ),

        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          height: 54,
          child: OutlinedButton(
            onPressed: authViewModel.isLoading ? null : _handleGoogleLogin,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFDDDDDD), width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              backgroundColor: Colors.white,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _GoogleLogo(),
                const SizedBox(width: 12),
                const Text(
                  'Continue with Google',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 32),

        Center(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account? ",
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SignupScreen()),
                    ),
                    child: const Text(
                      'Register as Driver',
                      style: TextStyle(
                        color: Color(0xFFFF6D00),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'By continuing, you agree to our Terms of Service and Privacy Policy',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[500], fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOtpScreen(AuthViewModel authViewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: const Icon(Icons.arrow_back_ios, size: 16),
              onPressed: () => setState(() {
                _isOtpSent = false;
                _otpController.clear();
                _verificationId = null;
              }),
            ),
            const SizedBox(width: 8),
            const Text(
              'Enter OTP',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        const Center(
          child: Text(
            'Enter 6-digit OTP',
            style: TextStyle(
              fontSize: 22,
              color: Color(0xFF666666),
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            'OTP sent to +91 ${_phoneController.text}',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ),
        const SizedBox(height: 32),
        TextField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 6,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 12,
          ),
          decoration: InputDecoration(
            counterText: "",
            hintText: '******',
            hintStyle: TextStyle(color: Colors.grey[300], letterSpacing: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: const Color(0xFFF5F5F5),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _resendTimer > 0
                  ? 'Resend OTP in $_resendTimer seconds'
                  : "Didn't receive OTP?",
              style: TextStyle(color: Colors.grey[600]),
            ),
            if (_canResend)
              TextButton(
                onPressed: authViewModel.isLoading ? null : _verifyPhoneNumber,
                child: const Text(
                  'Resend',
                  style: TextStyle(color: Color(0xFFFF6D00)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: authViewModel.isLoading ? null : _signInWithOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6D00),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            child: authViewModel.isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
                    'Verify & Login',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildNewDriverScreen(AuthViewModel authViewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Enter your name',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Tell us your name to continue',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
        const SizedBox(height: 32),
        TextField(
          controller: _nameController,
          decoration: InputDecoration(
            hintText: 'Your name',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: const Color(0xFFF5F5F5),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: authViewModel.isLoading
                ? null
                : () async {
                    if (_nameController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter your name')),
                      );
                      return;
                    }
                    if (authViewModel.newDriverInfo == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Session expired, please try again'),
                        ),
                      );
                      return;
                    }
                    final success = await authViewModel.completeGoogleProfile(
                      _nameController.text.trim(),
                      authViewModel.newDriverInfo!['mobile'],
                    );
                    if (success && mounted) {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const HomeScreen()),
                      );
                    } else if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            authViewModel.error ?? 'Failed to complete profile',
                          ),
                        ),
                      );
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6D00),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            child: authViewModel.isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
                    'Continue',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildToggleButton(String label, bool isActive, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive ? Colors.black : Colors.grey[600],
            ),
          ),
        ),
      ),
    );
  }
}

// Full-screen loading overlay
class _FullScreenLoadingOverlay extends StatelessWidget {
  const _FullScreenLoadingOverlay();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.5),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 24),
            Text(
              'Signing you in… Please wait.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Driver not found bottom sheet
class _DriverNotFoundBottomSheet extends StatelessWidget {
  final VoidCallback onRegister;
  final VoidCallback onUseAnotherAccount;
  final VoidCallback onClose;

  const _DriverNotFoundBottomSheet({
    required this.onRegister,
    required this.onUseAnotherAccount,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Warning icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFFF9800).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning_rounded,
                size: 40,
                color: Color(0xFFFF9800),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Driver Account Not Found',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'This Google account is not registered as a TaxiNanban Driver. Please register first or use another approved Google account.',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 40),
            // Primary button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: onRegister,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6D00),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: const Text(
                  'Register as Driver',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Secondary button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: TextButton(
                onPressed: onUseAnotherAccount,
                child: const Text(
                  'Use Another Google Account',
                  style: TextStyle(
                    color: Color(0xFF1A1A1A),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Close button
            TextButton(
              onPressed: onClose,
              child: Text(
                'Close',
                style: TextStyle(color: Colors.grey[500], fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoogleLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 22,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double cy = size.height / 2;
    final double r = size.width / 2;

    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.38
      ..strokeCap = StrokeCap.butt;

    arcPaint.color = const Color(0xFFEA4335);
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.78),
      _rad(210),
      _rad(100),
      false,
      arcPaint,
    );

    arcPaint.color = const Color(0xFF4285F4);
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.78),
      _rad(-60),
      _rad(120),
      false,
      arcPaint,
    );

    arcPaint.color = const Color(0xFF34A853);
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.78),
      _rad(60),
      _rad(80),
      false,
      arcPaint,
    );

    arcPaint.color = const Color(0xFFFBBC05);
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.78),
      _rad(140),
      _rad(70),
      false,
      arcPaint,
    );

    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(cx + r * 0.06, cy - r * 0.22, r * 0.88, r * 0.44),
      barPaint,
    );

    final maskPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), r * 0.58, maskPaint);
  }

  double _rad(double deg) => deg * 3.14159265358979 / 180;

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
