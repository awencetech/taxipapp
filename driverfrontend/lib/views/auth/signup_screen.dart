import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import 'google_onboarding_screen.dart';
import '../home/home_screen.dart';
import 'pending_approval_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _vehicleNumberController = TextEditingController();

  // Validation state
  bool _isNameValid = false;
  bool _isEmailValid = false;
  bool _isPhoneValid = false;
  bool _isPasswordValid = false;
  bool _isVehicleTypeSelected = false;
  bool _isVehicleNumberValid = false;

  // Password visibility
  bool _obscurePassword = true;

  // Vehicle type
  String? _selectedVehicleType;

  // Password strength
  String _passwordStrength = 'Weak';
  Color _passwordStrengthColor = Colors.red;

  // Vehicle type list with icons
  final List<Map<String, dynamic>> vehicleTypes = [
    {'name': 'Auto Rickshaw', 'icon': Icons.electric_rickshaw},
    {'name': 'Bike', 'icon': Icons.two_wheeler},
    {'name': 'Scooter', 'icon': Icons.moped},
    {'name': 'Sedan', 'icon': Icons.directions_car},
    {'name': 'Hatchback', 'icon': Icons.directions_car_outlined},
    {'name': 'SUV', 'icon': Icons.directions_car_filled},
    {'name': 'Mini SUV', 'icon': Icons.directions_car_filled_outlined},
    {'name': 'Prime Sedan', 'icon': Icons.directions_car_rounded},
    {'name': 'XL', 'icon': Icons.car_rental},
    {'name': 'Premium', 'icon': Icons.local_taxi},
    {'name': 'Luxury', 'icon': Icons.car_repair},
    {'name': 'EV Car', 'icon': Icons.electric_car},
    {'name': 'EV Bike', 'icon': Icons.electric_bike},
    {'name': 'Pickup Van', 'icon': Icons.local_shipping},
    {'name': 'Mini Truck', 'icon': Icons.local_shipping_outlined},
    {'name': 'Tempo Traveller', 'icon': Icons.airport_shuttle},
  ];

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_validateName);
    _emailController.addListener(_validateEmail);
    _phoneController.addListener(_validatePhone);
    _passwordController.addListener(_validatePassword);
    _vehicleNumberController.addListener(_validateVehicleNumber);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _vehicleNumberController.dispose();
    super.dispose();
  }

  // 1. Name Validation
  void _validateName() {
    String name = _nameController.text.trim();
    // Auto capitalize first letter of each word
    name = _capitalizeFirstLetterOfEachWord(name);
    // Update text with auto-capitalized value
    if (_nameController.text != name) {
      _nameController.value = TextEditingValue(
        text: name,
        selection: TextSelection.fromPosition(
          TextPosition(offset: name.length),
        ),
      );
    }
    // Validate
    final RegExp nameRegex = RegExp(r'^[a-zA-Z ]{3,40}$');
    setState(() {
      _isNameValid = nameRegex.hasMatch(name);
    });
  }

  String _capitalizeFirstLetterOfEachWord(String input) {
    if (input.isEmpty) return input;
    List<String> words = input.split(' ');
    for (int i = 0; i < words.length; i++) {
      if (words[i].isNotEmpty) {
        words[i] = words[i][0].toUpperCase() + words[i].substring(1).toLowerCase();
      }
    }
    return words.join(' ');
  }

  // 2. Email Validation
  void _validateEmail() {
    String email = _emailController.text.trim();
    final RegExp emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@gmail\.com$');
    setState(() {
      _isEmailValid = emailRegex.hasMatch(email);
    });
  }

  // 3. Phone Validation
  void _validatePhone() {
    String phone = _phoneController.text.trim();
    // Remove non-digit characters
    String cleaned = phone.replaceAll(RegExp(r'[^\d]'), '');
    // Limit to 10 digits
    if (cleaned.length > 10) {
      cleaned = cleaned.substring(0, 10);
      _phoneController.value = TextEditingValue(
        text: cleaned,
        selection: TextSelection.fromPosition(
          TextPosition(offset: cleaned.length),
        ),
      );
    }
    // Validate
    final RegExp phoneRegex = RegExp(r'^[6-9]\d{9}$');
    setState(() {
      _isPhoneValid = phoneRegex.hasMatch(cleaned);
    });
  }

  // 4. Password Validation
  void _validatePassword() {
    String password = _passwordController.text.trim();
    final RegExp hasUppercase = RegExp(r'[A-Z]');
    final RegExp hasLowercase = RegExp(r'[a-z]');
    final RegExp hasDigit = RegExp(r'\d');
    final RegExp hasSpecial = RegExp(r'[@#$%&!*?]');

    bool isValid = password.length >= 8 &&
        hasUppercase.hasMatch(password) &&
        hasLowercase.hasMatch(password) &&
        hasDigit.hasMatch(password) &&
        hasSpecial.hasMatch(password);

    // Calculate strength
    int strength = 0;
    if (password.length >= 8) strength++;
    if (hasUppercase.hasMatch(password)) strength++;
    if (hasLowercase.hasMatch(password)) strength++;
    if (hasDigit.hasMatch(password)) strength++;
    if (hasSpecial.hasMatch(password)) strength++;

    String strengthText = 'Weak';
    Color strengthColor = Colors.red;
    if (strength <= 2) {
      strengthText = 'Weak';
      strengthColor = Colors.red;
    } else if (strength <= 3) {
      strengthText = 'Medium';
      strengthColor = Colors.orange;
    } else {
      strengthText = 'Strong';
      strengthColor = Colors.green;
    }

    setState(() {
      _isPasswordValid = isValid;
      _passwordStrength = strengthText;
      _passwordStrengthColor = strengthColor;
    });
  }

  // 5. Vehicle Number Validation
  void _validateVehicleNumber() {
    String value = _vehicleNumberController.text.trim().toUpperCase();
    // Auto format
    String formatted = _formatVehicleNumber(value);
    // Update text
    if (_vehicleNumberController.text != formatted) {
      _vehicleNumberController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.fromPosition(
          TextPosition(offset: formatted.length),
        ),
      );
    }
    // Validate
    final RegExp vehicleRegex = RegExp(r'^[A-Z]{2}\s[0-9]{2}\s[A-Z]{1,2}\s[0-9]{4}$');
    setState(() {
      _isVehicleNumberValid = vehicleRegex.hasMatch(formatted);
    });
  }

  String _formatVehicleNumber(String input) {
    // Remove spaces and non-alphanumeric characters, convert to uppercase
    String clean = input.replaceAll(RegExp(r'[^A-Z0-9]'), '');
    String formatted = '';
    for (int i = 0; i < clean.length; i++) {
      if (i == 2 || i == 4 || (i == 6 || (i == 5 && clean.length >= 6))) {
        // Insert space after 2 chars, then after next 2 chars, then after next 1-2 chars
        if (i == 2 || i == 4 || (i == 6) || (i == 5 && clean.length > 6)) {
          formatted += ' ';
        }
      }
      formatted += clean[i];
      if (formatted.length >= 13) { // TN 58 AV 2345 is 13 chars
        break;
      }
    }
    return formatted;
  }

  bool _isFormValid() {
    return _isNameValid &&
        _isEmailValid &&
        _isPhoneValid &&
        _isPasswordValid &&
        _isVehicleTypeSelected &&
        _isVehicleNumberValid;
  }

  void _handleSignup() async {
    if (_isFormValid()) {
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      final result = await authViewModel.register(
        _nameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _phoneController.text.trim(),
        _selectedVehicleType ?? '',
        _vehicleNumberController.text.trim(),
      );

      if (result['success'] && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const PendingApprovalScreen()),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Signup Failed')),
        );
      }
    }
  }

  void _handleGoogleSignUp() async {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final result = await authViewModel.loginWithGoogle();

    if (!mounted) return;

    if (result['success'] == true) {
      if (result['isNewUser'] == true) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const GoogleOnboardingScreen()),
        );
      } else {
        // Check status
        final status = result['status'];
        if (status == 'APPROVED') {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
            (route) => false,
          );
        } else if (status == 'PENDING') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const PendingApprovalScreen()),
          );
        } else if (status == 'REJECTED') {
          // Navigate to RejectedScreen (from pending_approval_screen.dart)
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => RejectedScreen(rejectionReason: result['rejectionReason'])),
          );
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authViewModel.error ?? 'Google Sign-Up failed'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              height: 200,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF2D2D2D), Color(0xFFE65100)],
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Create Account',
                    style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    'Join our fleet and start driving',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
              ),
            ),

            // Form Card
            Transform.translate(
              offset: const Offset(0, -30),
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
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Google Sign Up Button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: OutlinedButton(
                        onPressed: authViewModel.isLoading ? null : _handleGoogleSignUp,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFDDDDDD), width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                          backgroundColor: Colors.white,
                        ),
                        child: authViewModel.isLoading
                            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF4285F4)))
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _GoogleLogo(),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Sign up with Google',
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A), letterSpacing: 0.2),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    // Divider
                    Row(
                      children: [
                        Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text('or sign up with email', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                        ),
                        Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Form Fields
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Name Field
                          Text('Name', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF1A1A1A))),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              hintText: 'Full Name',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: _isNameValid
                                    ? const BorderSide(color: Colors.green, width: 2)
                                    : BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(color: Color(0xFFFF6D00), width: 2),
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF5F5F5),
                              suffixIcon: _isNameValid
                                  ? const Icon(Icons.check_circle, color: Colors.green)
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Email Field
                          Text('Email', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF1A1A1A))),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              hintText: 'Email Address',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: _isEmailValid
                                    ? const BorderSide(color: Colors.green, width: 2)
                                    : BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(color: Color(0xFFFF6D00), width: 2),
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF5F5F5),
                              suffixIcon: _isEmailValid
                                  ? const Icon(Icons.check_circle, color: Colors.green)
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Phone Field
                          Text('Phone', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF1A1A1A))),
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
                                child: const Text('+91', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _phoneController,
                                  keyboardType: TextInputType.phone,
                                  maxLength: 10,
                                  decoration: InputDecoration(
                                    hintText: '9876543210',
                                    counterText: '',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: _isPhoneValid
                                          ? const BorderSide(color: Colors.green, width: 2)
                                          : BorderSide.none,
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(color: Color(0xFFFF6D00), width: 2),
                                    ),
                                    filled: true,
                                    fillColor: const Color(0xFFF5F5F5),
                                    suffixIcon: _isPhoneValid
                                        ? const Icon(Icons.check_circle, color: Colors.green)
                                        : null,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Password Field
                          Text('Password', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF1A1A1A))),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              hintText: '********',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: _isPasswordValid
                                    ? const BorderSide(color: Colors.green, width: 2)
                                    : BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(color: Color(0xFFFF6D00), width: 2),
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF5F5F5),
                              suffixIcon: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_isPasswordValid)
                                    const Icon(Icons.check_circle, color: Colors.green),
                                  const SizedBox(width: 4),
                                  IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      color: Colors.grey,
                                    ),
                                    onPressed: () => setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    }),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Strength: $_passwordStrength',
                            style: TextStyle(color: _passwordStrengthColor, fontSize: 12),
                          ),
                          const SizedBox(height: 16),
                          // Vehicle Type Dropdown
                          Text('Vehicle Type', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF1A1A1A))),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            decoration: InputDecoration(
                              hintText: 'Select Vehicle Type',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: _isVehicleTypeSelected
                                    ? const BorderSide(color: Colors.green, width: 2)
                                    : BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(color: Color(0xFFFF6D00), width: 2),
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF5F5F5),
                              prefixIcon: _selectedVehicleType != null
                                  ? Icon(
                                      vehicleTypes.firstWhere((element) => element['name'] == _selectedVehicleType)['icon'],
                                      color: Colors.grey,
                                    )
                                  : const Icon(Icons.directions_car, color: Colors.grey),
                              suffixIcon: const Icon(Icons.arrow_drop_down),
                            ),
                            items: vehicleTypes.map((type) {
                              return DropdownMenuItem<String>(
                                value: type['name'],
                                child: Row(
                                  children: [
                                    Icon(type['icon']),
                                    const SizedBox(width: 8),
                                    Text(type['name']),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedVehicleType = value;
                                _isVehicleTypeSelected = value != null;
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          // Vehicle Number Field
                          Text('Vehicle Number', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF1A1A1A))),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _vehicleNumberController,
                            decoration: InputDecoration(
                              hintText: 'TN 01 AB 1234',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: _isVehicleNumberValid
                                    ? const BorderSide(color: Colors.green, width: 2)
                                    : BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(color: Color(0xFFFF6D00), width: 2),
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF5F5F5),
                              suffixIcon: _isVehicleNumberValid
                                  ? const Icon(Icons.check_circle, color: Colors.green)
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 32),
                          // Sign Up Button
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _isFormValid() && !authViewModel.isLoading
                                  ? _handleSignup
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isFormValid()
                                    ? const Color(0xFFFF6D00)
                                    : Colors.grey.shade300,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(28),
                                ),
                                elevation: 0,
                              ),
                              child: authViewModel.isLoading
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : const Text(
                                      'SIGN UP',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Login Link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text("Already have an account? "),
                              GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: const Text(
                                  'Login',
                                  style: TextStyle(color: Color(0xFFFF6D00), fontWeight: FontWeight.bold),
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
          ],
        ),
      ),
    );
  }
}

// Google Logo Widget
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

    // Red arc
    arcPaint.color = const Color(0xFFEA4335);
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.78),
      _rad(210),
      _rad(100),
      false,
      arcPaint,
    );

    // Blue arc
    arcPaint.color = const Color(0xFF4285F4);
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.78),
      _rad(-60),
      _rad(120),
      false,
      arcPaint,
    );

    // Green arc
    arcPaint.color = const Color(0xFF34A853);
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.78),
      _rad(60),
      _rad(80),
      false,
      arcPaint,
    );

    // Yellow arc
    arcPaint.color = const Color(0xFFFBBC05);
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.78),
      _rad(140),
      _rad(70),
      false,
      arcPaint,
    );

    // Blue bar
    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(cx + r * 0.06, cy - r * 0.22, r * 0.88, r * 0.44),
      barPaint,
    );

    // White mask
    final maskPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), r * 0.58, maskPaint);
  }

  double _rad(double deg) => deg * 3.14159265358979 / 180;

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
