import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import 'google_onboarding_screen.dart';
import '../home/home_screen.dart';

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
  final _vehicleColorController = TextEditingController();
  final _vehicleModelController = TextEditingController();
  final _manufacturingYearController = TextEditingController();
  final _rcNumberController = TextEditingController();
  final _drivingLicenseController = TextEditingController();

  bool _obscurePassword = true;
  String? _selectedVehicleType;
  bool _isVehicleNumberValid = false;

  static const List<String> vehicleTypes = [
    'Bike',
    'Auto',
    'Sedan',
    'Hatchback',
    'SUV',
    'Mini Cab',
    'Taxi',
    'Van',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _vehicleNumberController.dispose();
    _vehicleColorController.dispose();
    _vehicleModelController.dispose();
    _manufacturingYearController.dispose();
    _rcNumberController.dispose();
    _drivingLicenseController.dispose();
    super.dispose();
  }

  void _handleSignup() async {
    if (_formKey.currentState!.validate()) {
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      final success = await authViewModel.register(
        _nameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _phoneController.text.trim(),
        _selectedVehicleType ?? '',
        _vehicleNumberController.text.trim(),
      );

      if (success && mounted) {
        debugPrint('SignupScreen: Signup success reported by AuthViewModel');
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(authViewModel.error ?? 'Signup Failed')),
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
        // New driver — go to onboarding to complete profile
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const GoogleOnboardingScreen()),
        );
      } else {
        // Existing driver — go home
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
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

  void _formatVehicleNumber(String value) {
    final cleanValue = value.toUpperCase().replaceAll(' ', '');
    String formatted = '';

    for (int i = 0; i < cleanValue.length; i++) {
      if (i == 2 || i == 4 || i == 7) {
        formatted += ' ';
      }
      formatted += cleanValue[i];
    }

    _vehicleNumberController.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.fromPosition(
        TextPosition(offset: formatted.length),
      ),
    );

    final isValid = _validateVehicleNumber(formatted);
    setState(() {
      _isVehicleNumberValid = isValid;
    });
  }

  bool _validateVehicleNumber(String? value) {
    if (value == null || value.isEmpty) return false;
    final RegExp regex = RegExp(
      r'^[A-Z]{2}\s?[0-9]{1,2}\s?[A-Z]{1,3}\s?[0-9]{1,4}$',
    );
    return regex.hasMatch(value);
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Hero Header ───────────────────────────────────────────────
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
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
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Create Account',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'Join our fleet and start driving',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
              ),
            ),

            // ── Form Card ─────────────────────────────────────────────────
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
                    // ── Google Sign-Up Button ─────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: OutlinedButton(
                        onPressed: authViewModel.isLoading
                            ? null
                            : _handleGoogleSignUp,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                              color: Color(0xFFDDDDDD), width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                          backgroundColor: Colors.white,
                        ),
                        child: authViewModel.isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Color(0xFF4285F4),
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _GoogleLogo(),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Sign up with Google',
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

                    const SizedBox(height: 22),

                    // ── Divider ───────────────────────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: Colors.grey.shade300,
                            thickness: 1,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'or sign up with email',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: Colors.grey.shade300,
                            thickness: 1,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // ── Email / Password Form ─────────────────────────────
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _buildField(
                            controller: _nameController,
                            hint: 'Full Name',
                            label: 'Name',
                          ),
                          const SizedBox(height: 16),
                          _buildField(
                            controller: _emailController,
                            hint: 'Email Address',
                            label: 'Email',
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    'Phone',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF1A1A1A),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Container(
                                    height: 56,
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(16)),
                                    alignment: Alignment.center,
                                    child: const Text('+91', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _phoneController,
                                      keyboardType: TextInputType.phone,
                                      decoration: InputDecoration(
                                        hintText: '9876543210',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(16),
                                          borderSide: BorderSide.none,
                                        ),
                                        filled: true,
                                        fillColor: const Color(0xFFF5F5F5),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Required';
                                        }
                                        // Remove any non-digit characters
                                        final cleaned = value.replaceAll(RegExp(r'[^\d]'), '');
                                        if (cleaned.length != 10) {
                                          return 'Phone number must be exactly 10 digits';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildField(
                            controller: _passwordController,
                            hint: '********',
                            label: 'Password',
                            obscureText: _obscurePassword,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Colors.grey,
                              ),
                              onPressed: () => setState(
                                () =>
                                    _obscurePassword = !_obscurePassword,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Vehicle Type Dropdown
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Vehicle Type',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF1A1A1A),
                                ),
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                decoration: InputDecoration(
                                  hintText: 'Select Vehicle Type',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                  filled: true,
                                  fillColor: const Color(0xFFF5F5F5),
                                  prefixIcon: const Icon(
                                    Icons.directions_car,
                                    color: Colors.grey,
                                  ),
                                  suffixIcon:
                                      const Icon(Icons.arrow_drop_down),
                                ),
                                initialValue: _selectedVehicleType,
                                items: vehicleTypes.map((type) {
                                  return DropdownMenuItem<String>(
                                    value: type,
                                    child: Text(type),
                                  );
                                }).toList(),
                                validator: (value) {
                                  if (value == null) {
                                    return 'Please select a vehicle type.';
                                  }
                                  return null;
                                },
                                onChanged: (value) {
                                  setState(() {
                                    _selectedVehicleType = value;
                                  });
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Vehicle Number Field with Validation
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Vehicle Number',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF1A1A1A),
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _vehicleNumberController,
                                onChanged: _formatVehicleNumber,
                                decoration: InputDecoration(
                                  hintText: 'TN 01 AB 1234',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: _isVehicleNumberValid
                                        ? const BorderSide(
                                            color: Colors.green,
                                            width: 2,
                                          )
                                        : BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFFF6D00),
                                      width: 2,
                                    ),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(
                                      color: Colors.red,
                                      width: 2,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: const Color(0xFFF5F5F5),
                                  prefixIcon: const Icon(
                                    Icons.local_car_wash,
                                    color: Colors.grey,
                                  ),
                                  suffixIcon: _isVehicleNumberValid
                                      ? const Icon(
                                          Icons.check_circle,
                                          color: Colors.green,
                                        )
                                      : null,
                                ),
                                validator: (value) {
                                  if (!_validateVehicleNumber(value)) {
                                    return 'Enter a valid vehicle number.';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                          // Show additional fields only if vehicle type is selected
                          if (_selectedVehicleType != null) ...[
                            const SizedBox(height: 16),
                            _buildField(
                              controller: _vehicleColorController,
                              hint: 'e.g., White, Black',
                              label: 'Vehicle Color',
                              isOptional: true,
                            ),
                            const SizedBox(height: 16),
                            _buildField(
                              controller: _vehicleModelController,
                              hint: 'e.g., Honda City, Swift Dzire',
                              label: 'Model Name',
                              isOptional: true,
                            ),
                            const SizedBox(height: 16),
                            _buildField(
                              controller: _manufacturingYearController,
                              hint: 'e.g., 2020',
                              label: 'Manufacturing Year',
                              keyboardType: TextInputType.number,
                              isOptional: true,
                            ),
                            const SizedBox(height: 16),
                            _buildField(
                              controller: _rcNumberController,
                              hint: 'RC Number (optional)',
                              label: 'RC Number',
                              isOptional: true,
                            ),
                            const SizedBox(height: 16),
                            _buildField(
                              controller: _drivingLicenseController,
                              hint: 'Driving License (optional)',
                              label: 'Driving License Number',
                              isOptional: true,
                            ),
                          ],
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: authViewModel.isLoading
                                  ? null
                                  : _handleSignup,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFF6D00),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(28),
                                ),
                                elevation: 0,
                              ),
                              child: authViewModel.isLoading
                                  ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                  : const Text(
                                      'SIGN UP',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text("Already have an account? "),
                              GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: const Text(
                                  'Login',
                                  style: TextStyle(
                                    color: Color(0xFFFF6D00),
                                    fontWeight: FontWeight.bold,
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
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
    bool isOptional = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1A1A1A),
              ),
            ),
            if (isOptional)
              const Text(
                ' (optional)',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: const Color(0xFFF5F5F5),
            suffixIcon: suffixIcon,
          ),
          validator: (value) {
            if (!isOptional && (value == null || value.isEmpty)) {
              return 'Required';
            }
            return null;
          },
        ),
      ],
    );
  }
}

// ── Google "G" Logo (painted, no external assets needed) ─────────────────────

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

    // Red arc (top-left)
    arcPaint.color = const Color(0xFFEA4335);
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.78),
      _rad(210),
      _rad(100),
      false,
      arcPaint,
    );

    // Blue arc (top-right + right)
    arcPaint.color = const Color(0xFF4285F4);
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.78),
      _rad(-60),
      _rad(120),
      false,
      arcPaint,
    );

    // Green arc (bottom-right)
    arcPaint.color = const Color(0xFF34A853);
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.78),
      _rad(60),
      _rad(80),
      false,
      arcPaint,
    );

    // Yellow arc (bottom-left)
    arcPaint.color = const Color(0xFFFBBC05);
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.78),
      _rad(140),
      _rad(70),
      false,
      arcPaint,
    );

    // Horizontal bar (right arm of G) in blue
    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(cx + r * 0.06, cy - r * 0.22, r * 0.88, r * 0.44),
      barPaint,
    );

    // White mask over inner arc to create ring effect
    final maskPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), r * 0.58, maskPaint);
  }

  double _rad(double deg) => deg * 3.14159265358979 / 180;

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
