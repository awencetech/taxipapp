import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../home/home_screen.dart';

class GoogleOnboardingScreen extends StatefulWidget {
  const GoogleOnboardingScreen({super.key});

  @override
  State<GoogleOnboardingScreen> createState() => _GoogleOnboardingScreenState();
}

class _GoogleOnboardingScreenState extends State<GoogleOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _mobileController;
  late TextEditingController _vehicleTypeController;
  late TextEditingController _vehicleNumberController;

  @override
  void initState() {
    super.initState();
    final driver = context.read<AuthViewModel>().newDriverInfo;
    String fullName = driver?['name'] ?? '';
    List<String> nameParts = fullName.split(' ');

    _firstNameController = TextEditingController(
      text: nameParts.isNotEmpty ? nameParts[0] : '',
    );
    _lastNameController = TextEditingController(
      text: nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '',
    );
    _mobileController = TextEditingController();
    _vehicleTypeController = TextEditingController();
    _vehicleNumberController = TextEditingController();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _mobileController.dispose();
    _vehicleTypeController.dispose();
    _vehicleNumberController.dispose();
    super.dispose();
  }

  void _completeOnboarding() async {
    if (_formKey.currentState!.validate()) {
      final authViewModel = context.read<AuthViewModel>();
      final fullName =
          "${_firstNameController.text.trim()} ${_lastNameController.text.trim()}";

      // Complete Google profile and register driver in one call
      final success = await authViewModel.completeGoogleProfile(
        fullName,
        _mobileController.text.trim(),
        _vehicleTypeController.text.trim(),
        _vehicleNumberController.text.trim(),
      );

      if (success && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authViewModel.error ?? 'Failed to complete profile'),
            backgroundColor: Colors.black,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back, color: Colors.black, size: 20),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Confirm your information",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 30),

                // Name Row
                Row(
                  children: [
                    Expanded(
                      child: _buildUberField(
                        controller: _firstNameController,
                        hint: "First name",
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildUberField(
                        controller: _lastNameController,
                        hint: "Last name",
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Phone Field
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F3F3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "IN",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_drop_down, size: 20),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildUberField(
                        controller: _mobileController,
                        hint: "+91 0000000000",
                        keyboardType: TextInputType.phone,
                        isPhone: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Vehicle Type and Number
                Row(
                  children: [
                    Expanded(
                      child: _buildUberField(
                        controller: _vehicleTypeController,
                        hint: "Vehicle Type (Bike/Auto/Cab)",
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildUberField(
                        controller: _vehicleNumberController,
                        hint: "Vehicle Number",
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                const Text(
                  "By continuing, you agree to calls, including by autodialer, WhatsApp, or texts from Taxi Nanban and its affiliates.",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 40),

                // Buttons Row
                Padding(
                  padding: const EdgeInsets.only(bottom: 30.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Back Button
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF3F3F3),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_back,
                            color: Colors.black,
                          ),
                        ),
                      ),

                      // Next Button
                      GestureDetector(
                        onTap: authViewModel.isLoading
                            ? null
                            : _completeOnboarding,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              authViewModel.isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      "Next",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.arrow_forward,
                                color: Colors.white,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUberField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    bool isPhone = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: const Color(0xFFF3F3F3),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.black, width: 2),
        ),
        errorStyle: const TextStyle(height: 0),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return '';
        if (isPhone && (value.length < 10)) return '';
        return null;
      },
    );
  }
}

