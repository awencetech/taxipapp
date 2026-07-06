import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/auth_provider.dart';
import '../booking/home_screen.dart';

class PhoneAuthScreen extends StatefulWidget {
  const PhoneAuthScreen({super.key});

  @override
  State<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  final _phoneController = TextEditingController(text: '+91');
  final _otpController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLoading = false;
  bool _isOtpSent = false;
  String? _verificationId;
  bool _isNewUser = false;
  int _resendTimer = 60;

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(_ensurePrefix);
  }

  void _ensurePrefix() {
    final text = _phoneController.text;
    if (!text.startsWith('+91')) {
      _phoneController.text = '+91$text';
    }
    // Ensure cursor stays at the end
    _phoneController.selection = TextSelection.fromPosition(
      TextPosition(offset: _phoneController.text.length),
    );
  }

  @override
  void dispose() {
    _phoneController.removeListener(_ensurePrefix);
    _phoneController.dispose();
    _otpController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  String? _validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a phone number';
    }
    // Remove any non-digit characters except +
    final cleaned = value.replaceAll(RegExp(r'[^\d+]'), '');

    // Check if it starts with +91
    if (!cleaned.startsWith('+91')) {
      return 'Phone number must start with +91';
    }

    // Get the 10-digit number after +91
    final numberPart = cleaned.substring(3);
    if (numberPart.length != 10) {
      return 'Phone number must be exactly 10 digits';
    }

    return null;
  }

  Future<void> _verifyPhoneNumber() async {
    final validationError = _validatePhoneNumber(_phoneController.text);
    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(validationError), backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: _phoneController.text.trim(),
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(e.message ?? 'Verification failed'),
                backgroundColor: AppColors.error),
          );
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            _isOtpSent = true;
            _verificationId = verificationId;
            _isLoading = false;
            _startResendTimer();
          });
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          setState(() {
            _verificationId = verificationId;
          });
        },
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
      );
    }
  }

  void _startResendTimer() {
    _resendTimer = 60;
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() {
          _resendTimer--;
        });
      }
      return _resendTimer > 0 && mounted;
    });
  }

  Future<void> _signInWithOtp() async {
    if (_otpController.text.trim().isEmpty || _verificationId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: _otpController.text.trim(),
      );
      await _signInWithCredential(credential);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _signInWithCredential(PhoneAuthCredential credential) async {
    final authProvider = context.read<AuthProvider>();
    try {
      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final idToken = await userCredential.user?.getIdToken();

      if (idToken != null) {
        if (_nameController.text.trim().isNotEmpty) {
          final success = await authProvider.signInWithFirebasePhone(
            idToken,
            'user',
            name: _nameController.text.trim(),
          );
          if (success && mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          } else if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(authProvider.error ?? 'Sign in failed'),
                  backgroundColor: AppColors.error),
            );
          }
        } else {
          final success =
              await authProvider.signInWithFirebasePhone(idToken, 'user');
          if (success && mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          } else if (mounted) {
            setState(() {
              _isNewUser = true;
              _isLoading = false;
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.toString()), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.phone_android,
                  size: 80,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 32),
                Text(
                  _isNewUser
                      ? 'Enter your name'
                      : (_isOtpSent ? 'Enter OTP' : 'Phone Authentication'),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isNewUser
                      ? 'Tell us your name to continue'
                      : (_isOtpSent
                          ? 'We have sent an OTP to ${_phoneController.text.trim()}'
                          : 'Enter your phone number to continue'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.grey600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 32),
                if (_isNewUser) ...[
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      hintText: 'Your name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : () async {
                              if (_nameController.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Please enter your name'),
                                      backgroundColor: AppColors.error),
                                );
                                return;
                              }
                              final authProvider = context.read<AuthProvider>();
                              final user = FirebaseAuth.instance.currentUser;
                              final idToken = await user?.getIdToken();
                              if (idToken != null) {
                                setState(() {
                                  _isLoading = true;
                                });
                                final success =
                                    await authProvider.signInWithFirebasePhone(
                                  idToken,
                                  'user',
                                  name: _nameController.text.trim(),
                                );
                                if (success && mounted) {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const HomeScreen()),
                                  );
                                } else if (mounted) {
                                  setState(() {
                                    _isLoading = false;
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(authProvider.error ??
                                            'Sign in failed'),
                                        backgroundColor: AppColors.error),
                                  );
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Continue'),
                    ),
                  ),
                ] else if (_isOtpSent) ...[
                  TextField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: InputDecoration(
                      hintText: '6-digit OTP',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.sms),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _signInWithOtp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Verify OTP'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _resendTimer > 0
                            ? 'Resend OTP in $_resendTimer seconds'
                            : 'Didn\'t receive OTP?',
                        style: const TextStyle(color: AppColors.grey600),
                      ),
                      if (_resendTimer == 0)
                        TextButton(
                          onPressed: _isLoading ? null : _verifyPhoneNumber,
                          child: const Text(
                            'Resend',
                            style: TextStyle(color: AppColors.primary),
                          ),
                        ),
                    ],
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isOtpSent = false;
                        _otpController.clear();
                      });
                    },
                    child: const Text('Change phone number'),
                  ),
                ] else ...[
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: _validatePhoneNumber,
                    decoration: InputDecoration(
                      hintText: '+91 1234567890',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.phone),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _verifyPhoneNumber,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Send OTP'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
