import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/providers/auth_provider.dart';
import '../features/booking/home_screen.dart';

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

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().newUserInfo;
    String fullName = user?['name'] ?? '';
    List<String> nameParts = fullName.split(' ');

    _firstNameController =
        TextEditingController(text: nameParts.isNotEmpty ? nameParts[0] : '');
    _lastNameController = TextEditingController(
        text: nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '');
    _mobileController = TextEditingController();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  void _completeOnboarding() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = context.read<AuthProvider>();
      final fullName =
          "${_firstNameController.text.trim()} ${_lastNameController.text.trim()}";
      final success = await authProvider.completeGoogleProfile(
        fullName,
        _mobileController.text.trim(),
      );

      if (success && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.error ?? 'Failed to complete profile'),
            backgroundColor: Colors.black,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 60),
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
                          horizontal: 16, vertical: 16),
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
                                fontSize: 16, fontWeight: FontWeight.w500),
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

                const SizedBox(height: 24),
                const Text(
                  "By continuing, you agree to calls, including by autodialer, WhatsApp, or texts from Taxi Nanban and its affiliates.",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    height: 1.5,
                  ),
                ),

                const Spacer(),

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
                          child:
                              const Icon(Icons.arrow_back, color: Colors.black),
                        ),
                      ),

                      // Next Button
                      GestureDetector(
                        onTap:
                            authProvider.isLoading ? null : _completeOnboarding,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              authProvider.isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                          color: Colors.white, strokeWidth: 2),
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
                              const Icon(Icons.arrow_forward,
                                  color: Colors.white, size: 20),
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
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.black, width: 2),
        ),
        errorStyle:
            const TextStyle(height: 0), // Hide error text to keep it clean
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return '';
        if (isPhone && (value.length < 10)) return '';
        return null;
      },
    );
  }
}
