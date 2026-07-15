import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../core/theme/app_theme.dart';
import '../dashboard/dashboard_screen.dart';

import 'complete_google_signup_screen.dart';
import 'forgot_password_screen.dart';
import 'waiting_for_approval_screen.dart';
import 'registration_declined_screen.dart';

enum LoginState { phone, otp, email }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  LoginState _loginState = LoginState.phone;
  String? _currentPhone;
  String? _phoneError;

  String? _validatePhoneNumber(String value) {
    // Remove any non-digit characters
    final cleaned = value.replaceAll(RegExp(r'[^\d]'), '');

    // Check if it's exactly 10 digits
    if (cleaned.length != 10) {
      return 'Phone number must be exactly 10 digits';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);

    // Handle auth status changes
    if (authViewModel.authStatus != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (authViewModel.authStatus == AuthStatus.success) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const DashboardScreen()),
          );
        } else if (authViewModel.authStatus == AuthStatus.pending) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const WaitingForApprovalScreen()),
          );
        } else if (authViewModel.authStatus == AuthStatus.declined) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const RegistrationDeclinedScreen(),
            ),
          );
        }
      });
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Top Section with Image and Text
              Stack(
                children: [
                  // Background Image
                  Container(
                    width: double.infinity,
                    height: 280,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      image: const DecorationImage(
                        image: NetworkImage(
                          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=800&auto=format&fit=crop&q=60',
                        ),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  // Overlay gradient
                  Container(
                    width: double.infinity,
                    height: 280,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.2),
                          Colors.black.withValues(alpha: 0.6),
                        ],
                      ),
                    ),
                  ),
                  // Back button
                  if (_loginState != LoginState.phone)
                    Positioned(
                      top: 20,
                      left: 16,
                      child: IconButton(
                        onPressed: () {
                          setState(() {
                            _loginState = LoginState.phone;
                          });
                        },
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                    ),
                  // Text overlay
                  Positioned(
                    bottom: 24,
                    left: 24,
                    right: 24,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Welcome Back!',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _loginState == LoginState.phone
                              ? 'Sign in to continue driving'
                              : _loginState == LoginState.otp
                              ? 'Enter OTP sent to your phone'
                              : 'Enter your email and password',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Main Content
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    if (_loginState == LoginState.phone)
                      // Phone Login Card
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Login with Phone',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Phone Number Field
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3F4F6),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    alignment: Alignment.center,
                                    child: const Text(
                                      '+91',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1F2937),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextField(
                                      controller: _phoneController,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Color(0xFF1F2937),
                                      ),
                                      decoration: InputDecoration(
                                        hintText: '9876543210',
                                        hintStyle: const TextStyle(
                                          color: Color(0xFF9CA3AF),
                                        ),
                                        border: InputBorder.none,
                                        isDense: true,
                                        contentPadding: EdgeInsets.zero,
                                        errorText: _phoneError,
                                      ),
                                      onChanged: (value) {
                                        setState(() {
                                          _phoneError = _validatePhoneNumber(
                                            value,
                                          );
                                        });
                                      },
                                      keyboardType: TextInputType.phone,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Send OTP Button
                            authViewModel.isLoading
                                ? const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                : SizedBox(
                                    width: double.infinity,
                                    height: 56,
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        final error = _validatePhoneNumber(
                                          _phoneController.text,
                                        );
                                        if (error != null) {
                                          setState(() {
                                            _phoneError = error;
                                          });
                                          if (mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(content: Text(error)),
                                            );
                                          }
                                          return;
                                        }
                                        final success = await authViewModel
                                            .sendOTP(
                                              _phoneController.text
                                                  .trim()
                                                  .replaceAll(
                                                    RegExp(r'[^\d]'),
                                                    '',
                                                  ),
                                            );
                                        if (success) {
                                          setState(() {
                                            _currentPhone = _phoneController
                                                .text
                                                .trim()
                                                .replaceAll(
                                                  RegExp(r'[^\d]'),
                                                  '',
                                                );
                                            _loginState = LoginState.otp;
                                          });
                                          if (authViewModel.errorMessage !=
                                              null) {
                                            if (mounted) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    authViewModel.errorMessage!,
                                                  ),
                                                ),
                                              );
                                            }
                                          }
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.primaryColor,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        elevation: 0,
                                      ),
                                      child: const Text(
                                        'Send OTP',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                            const SizedBox(height: 16),
                            // Forgot Password
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const ForgotPasswordScreen(),
                                    ),
                                  );
                                },
                                child: Text(
                                  'Forgot Password?',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Email Login Option
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _loginState = LoginState.email;
                                });
                              },
                              child: Text(
                                'Or login with email and password',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (_loginState == LoginState.otp)
                      // OTP Verification Card
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Verify OTP sent to $_currentPhone',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                            const SizedBox(height: 24),
                            // OTP Field
                            TextField(
                              controller: _otpController,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Color(0xFF1F2937),
                              ),
                              decoration: InputDecoration(
                                hintText: 'Enter 6-digit OTP',
                                prefixIcon: const Icon(Icons.sms),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: const Color(0xFFF3F4F6),
                              ),
                              keyboardType: TextInputType.number,
                              maxLength: 6,
                            ),
                            const SizedBox(height: 24),
                            // Verify OTP Button
                            authViewModel.isLoading
                                ? const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                : SizedBox(
                                    width: double.infinity,
                                    height: 56,
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        final status = await authViewModel
                                            .verifyOTP(
                                              _currentPhone!,
                                              _otpController.text,
                                            );
                                        if (authViewModel.errorMessage !=
                                                null &&
                                            mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                authViewModel.errorMessage!,
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.primaryColor,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        elevation: 0,
                                      ),
                                      child: const Text(
                                        'Verify & Login',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                            const SizedBox(height: 16),
                            // Resend OTP
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Didn\'t receive OTP?',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    await authViewModel.sendOTP(_currentPhone!);
                                  },
                                  child: Text(
                                    'Resend',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppTheme.primaryColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      )
                    else if (_loginState == LoginState.email)
                      // Email Login Card
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Login with Email',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                            const SizedBox(height: 24),
                            TextField(
                              controller: _emailController,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Color(0xFF1F2937),
                              ),
                              decoration: InputDecoration(
                                hintText: 'Enter your email',
                                prefixIcon: const Icon(Icons.email),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: const Color(0xFFF3F4F6),
                              ),
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Color(0xFF1F2937),
                              ),
                              decoration: InputDecoration(
                                hintText: 'Enter your password',
                                prefixIcon: const Icon(Icons.lock),
                                suffixIcon: IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                  ),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: const Color(0xFFF3F4F6),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const ForgotPasswordScreen(),
                                    ),
                                  );
                                },
                                child: Text(
                                  'Forgot Password?',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            authViewModel.isLoading
                                ? const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                : SizedBox(
                                    width: double.infinity,
                                    height: 56,
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        final status = await authViewModel
                                            .login(
                                              email: _emailController.text,
                                              password:
                                                  _passwordController.text,
                                            );
                                        if (authViewModel.errorMessage !=
                                                null &&
                                            mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                authViewModel.errorMessage!,
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.primaryColor,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        elevation: 0,
                                      ),
                                      child: const Text(
                                        'Login',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 32),

                    // OR Divider
                    if (_loginState == LoginState.phone)
                      Row(
                        children: [
                          Expanded(child: Divider(color: Colors.grey[300])),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'OR',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Expanded(child: Divider(color: Colors.grey[300])),
                        ],
                      ),

                    const SizedBox(height: 32),

                    // Social Buttons
                    if (_loginState == LoginState.phone)
                      Column(
                        children: [
                          // Google Button
                          authViewModel.isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : SizedBox(
                                  width: double.infinity,
                                  height: 56,
                                  child: OutlinedButton.icon(
                                    onPressed: () async {
                                      // TODO: Update signInWithGoogle to handle approvalStatus
                                      final result = await authViewModel
                                          .signInWithGoogle();
                                      if (result['success'] == true) {
                                        if (result['isNewUser'] == true) {
                                          if (mounted) {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    const CompleteGoogleSignupScreen(),
                                              ),
                                            );
                                          }
                                        } else {
                                          // Check auth status after google login
                                          if (authViewModel.authStatus ==
                                                  AuthStatus.success &&
                                              mounted) {
                                            Navigator.pushReplacement(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    const DashboardScreen(),
                                              ),
                                            );
                                          }
                                        }
                                      } else if (authViewModel.errorMessage !=
                                              null &&
                                          mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              authViewModel.errorMessage!,
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(
                                        color: Colors.grey[300]!,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      foregroundColor: const Color(0xFF1F2937),
                                    ),
                                    icon: const Icon(
                                      Icons.g_mobiledata,
                                      size: 28,
                                    ),
                                    label: const Text(
                                      'Continue with Google',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
