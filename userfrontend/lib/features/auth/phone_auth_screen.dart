
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/auth_provider.dart';
import '../booking/home_screen.dart';

class PhoneAuthScreen extends StatefulWidget {
  const PhoneAuthScreen({super.key});

  @override
  State<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLoading = false;
  bool _isOtpSent = false;
  String? _verificationId;
  int? _resendToken;
  bool _isNewUser = false;
  int _resendTimer = 0;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _requestNotificationPermission();
  }

  Future<void> _requestNotificationPermission() async {
    if (mounted) {
      final status = await Permission.notification.request();
      if (status.isDenied || status.isPermanentlyDenied) {
        // Optionally show a snackbar or dialog explaining why we need notifications
      }
    }
  }

  /// Formats the phone number into valid E.164 format (+91XXXXXXXXXX)
  String _formatPhoneNumber(String input) {
    // Remove all non-digit characters
    final digits = input.replaceAll(RegExp(r'\D'), '');
    
    // If starts with 91, assume it's country code and format properly
    if (digits.startsWith('91') && digits.length == 12) {
      return '+$digits';
    }
    
    // If starts with 0, remove leading 0 and add +91
    if (digits.startsWith('0') && digits.length == 11) {
      return '+91${digits.substring(1)}';
    }
    
    // If it's 10 digits, add +91 prefix
    if (digits.length == 10) {
      return '+91$digits';
    }
    
    // If it's already has +, validate length
    if (input.startsWith('+') && digits.length == 12 && digits.startsWith('91')) {
      return input;
    }
    
    // Return as is for further validation
    return input;
  }

  String? _validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a phone number';
    }
    
    final formatted = _formatPhoneNumber(value);
    // Remove + for digit count check
    final digitsOnly = formatted.replaceAll(RegExp(r'\D'), '');
    
    if (!formatted.startsWith('+91')) {
      return 'Phone number must be from India (+91)';
    }
    
    if (digitsOnly.length != 12) {
      return 'Phone number must be exactly 10 digits';
    }
    
    return null;
  }

  Future<void> _verifyPhoneNumber() async {
    FocusScope.of(context).unfocus();
    
    final validationError = _validatePhoneNumber(_phoneController.text);
    if (validationError != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(validationError), backgroundColor: AppColors.error),
        );
      }
      return;
    }

    final formattedPhoneNumber = _formatPhoneNumber(_phoneController.text);
    debugPrint('=== Formatted Phone Number: $formattedPhoneNumber ===');

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      debugPrint('=== Starting verifyPhoneNumber ===');
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: formattedPhoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          debugPrint('=== verificationCompleted ===');
          debugPrint('Credential: $credential');
          if (mounted) {
            setState(() {
              _isLoading = true;
            });
          }
          await _signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          debugPrint('=== verificationFailed ===');
          debugPrint('Code: ${e.code}');
          debugPrint('Message: ${e.message}');
          debugPrint('Stack Trace: ${e.stackTrace}');
          if (mounted) {
            setState(() {
              _isLoading = false;
              _isOtpSent = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${e.code}: ${e.message}'),
                backgroundColor: AppColors.error,
                duration: const Duration(seconds: 5),
              ),
            );
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          debugPrint('=== codeSent ===');
          debugPrint('Verification ID: $verificationId');
          debugPrint('Resend token: $resendToken');
          if (mounted) {
            setState(() {
              _verificationId = verificationId;
              _resendToken = resendToken;
              _isOtpSent = true;
              _isLoading = false;
              _resendTimer = 60;
              _canResend = false;
            });
            _startResendTimer();
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          debugPrint('=== codeAutoRetrievalTimeout ===');
          debugPrint('Verification ID: $verificationId');
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
      debugPrint('Stack Trace: $stackTrace');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
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

  Future<void> _signInWithOtp() async {
    FocusScope.of(context).unfocus();
    
    final otp = _otpController.text.trim();
    if (otp.isEmpty || _verificationId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter the OTP'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }
    
    if (otp.length != 6) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('OTP must be exactly 6 digits'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      debugPrint('=== Signing in with OTP ===');
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );
      await _signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      debugPrint('=== FirebaseAuthException in signInWithOtp ===');
      debugPrint('Code: ${e.code}');
      debugPrint('Message: ${e.message}');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${e.code}: ${e.message}'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('=== Exception in signInWithOtp ===');
      debugPrint('Error: $e');
      debugPrint('Stack Trace: $stackTrace');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _signInWithCredential(PhoneAuthCredential credential) async {
    final authProvider = context.read<AuthProvider>();
    try {
      debugPrint('=== Signing in with credential ===');
      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      debugPrint('=== User Credential: $userCredential ===');
      
      final user = userCredential.user;
      if (user == null) {
        throw Exception('Failed to sign in: User is null');
      }

      debugPrint('=== Getting ID Token ===');
      final idToken = await user.getIdToken();
      debugPrint('=== ID Token retrieved ===');

      if (mounted) {
        if (_nameController.text.trim().isNotEmpty) {
          debugPrint('=== Signing in as returning user with name ===');
          final success = await authProvider.signInWithFirebasePhone(
            idToken!,
            'user',
            name: _nameController.text.trim(),
          );
          if (success && mounted) {
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
              );
            }
          } else if (mounted) {
            setState(() {
              _isLoading = false;
            });
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(authProvider.error ?? 'Sign in failed'),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          }
        } else {
          debugPrint('=== Signing in as new user ===');
          final success =
              await authProvider.signInWithFirebasePhone(idToken!, 'user');
          if (success && mounted) {
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
              );
            }
          } else if (mounted) {
            setState(() {
              _isNewUser = true;
              _isLoading = false;
            });
          }
        }
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('=== FirebaseAuthException in signInWithCredential ===');
      debugPrint('Code: ${e.code}');
      debugPrint('Message: ${e.message}');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${e.code}: ${e.message}'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('=== Exception in signInWithCredential ===');
      debugPrint('Error: $e');
      debugPrint('Stack Trace: $stackTrace');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _nameController.dispose();
    super.dispose();
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
                          ? 'We have sent an OTP to ${_formatPhoneNumber(_phoneController.text)}'
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
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Please enter your name'),
                                      backgroundColor: AppColors.error,
                                    ),
                                  );
                                }
                                return;
                              }
                              print("=== Number of initialized Firebase apps: ${Firebase.apps.length}");
                              for (var app in Firebase.apps) {
                                print("=== Firebase app: ${app.name}");
                              }
                              final authProvider = context.read&lt;AuthProvider&gt;();
                              final user = FirebaseAuth.instance.currentUser;
                              if (user == null) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('User not found, please try again'),
                                      backgroundColor: AppColors.error,
                                    ),
                                  );
                                }
                                return;
                              }
                              final idToken = await user.getIdToken();
                              if (idToken == null) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Failed to retrieve ID token'),
                                      backgroundColor: AppColors.error,
                                    ),
                                  );
                                }
                                return;
                              }
                              if (mounted) {
                                setState(() {
                                  _isLoading = true;
                                });
                              }
                              final success =
                                  await authProvider.signInWithFirebasePhone(
                                idToken,
                                'user',
                                name: _nameController.text.trim(),
                              );
                              if (success && mounted) {
                                if (mounted) {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const HomeScreen()),
                                  );
                                }
                              } else if (mounted) {
                                setState(() {
                                  _isLoading = false;
                                });
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(authProvider.error ??
                                          'Sign in failed'),
                                      backgroundColor: AppColors.error,
                                    ),
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
                      counterText: '',
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
                      if (_canResend)
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
                      if (mounted) {
                        setState(() {
                          _isOtpSent = false;
                          _otpController.clear();
                          _verificationId = null;
                        });
                      }
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
                      hintText: 'Enter your phone number',
                      labelText: 'Phone Number',
                      prefixIcon: const Icon(Icons.phone),
                      prefixText: '+91 ',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
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
