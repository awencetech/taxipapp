import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import 'pending_approval_screen.dart';

class VehicleType {
  final String name;
  final IconData icon;

  const VehicleType({required this.name, required this.icon});
}

const List<VehicleType> vehicleTypes = [
  VehicleType(name: 'Auto Rickshaw', icon: Icons.directions_car),
  VehicleType(name: 'Bike', icon: Icons.directions_bike),
  VehicleType(name: 'Scooter', icon: Icons.motorcycle),
  VehicleType(name: 'Sedan', icon: Icons.directions_car),
  VehicleType(name: 'Hatchback', icon: Icons.directions_car),
  VehicleType(name: 'SUV', icon: Icons.directions_car),
  VehicleType(name: 'Mini SUV', icon: Icons.directions_car),
  VehicleType(name: 'Prime Sedan', icon: Icons.directions_car),
  VehicleType(name: 'XL', icon: Icons.directions_car),
  VehicleType(name: 'Premium', icon: Icons.directions_car),
  VehicleType(name: 'Luxury', icon: Icons.directions_car),
  VehicleType(name: 'EV Car', icon: Icons.electric_car),
  VehicleType(name: 'EV Bike', icon: Icons.electric_bike),
  VehicleType(name: 'Pickup Van', icon: Icons.local_shipping),
  VehicleType(name: 'Mini Truck', icon: Icons.local_shipping),
  VehicleType(name: 'Tempo Traveller', icon: Icons.directions_bus),
];

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
  late TextEditingController _vehicleNumberController;

  bool _isMobileVerified = false;
  final String _countryCode = '+91';
  VehicleType? _selectedVehicleType;

  @override
  void initState() {
    super.initState();
    final driver = context.read<AuthViewModel>().newDriverInfo;
    String fullName = driver?['name'] ?? '';
    String mobile = driver?['mobile'] ?? '';
    List<String> nameParts = fullName.split(' ');

    _firstNameController = TextEditingController(
      text: nameParts.isNotEmpty ? nameParts[0] : '',
    );
    _lastNameController = TextEditingController(
      text: nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '',
    );
    _mobileController = TextEditingController(text: mobile);
    _vehicleNumberController = TextEditingController();

    // Set mobile verified if mobile is present
    if (mobile.isNotEmpty) {
      _isMobileVerified = true;
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _mobileController.dispose();
    _vehicleNumberController.dispose();
    super.dispose();
  }

  String _capitalizeEachWord(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  String _formatVehicleNumber(String text) {
    // Remove all non-alphanumeric characters
    String cleaned = text.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    StringBuffer buffer = StringBuffer();
    for (int i = 0; i < cleaned.length; i++) {
      if (i == 2 || i == 4 || i == 6) {
        buffer.write(' ');
      }
      buffer.write(cleaned[i]);
    }
    return buffer.toString();
  }

  bool _isVehicleNumberValid(String number) {
    // Remove all spaces
    String cleaned = number.replaceAll(RegExp(r'\s'), '');
    RegExp regex = RegExp(r'^[A-Z]{2}[0-9]{1,2}[A-Z]{1,2}[0-9]{4}$');
    return regex.hasMatch(cleaned);
  }

  bool _isFormValid() {
    // Validate first name
    final firstName = _firstNameController.text.trim();
    if (firstName.isEmpty || firstName.length < 3 || firstName.length > 40) {
      return false;
    }
    // Check first name has only letters and spaces
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(firstName)) {
      return false;
    }
    // Validate mobile
    final mobile = _mobileController.text.trim();
    if (!_isMobileVerified || mobile.length != 10) {
      return false;
    }
    // Validate vehicle type
    if (_selectedVehicleType == null) {
      return false;
    }
    // Validate vehicle number
    if (!_isVehicleNumberValid(_vehicleNumberController.text)) {
      return false;
    }
    return true;
  }

  void _completeOnboarding() async {
    if (!_isFormValid()) return;
    final authViewModel = context.read<AuthViewModel>();
    final vehicleNumber = _vehicleNumberController.text.replaceAll(RegExp(r'\s'), '');
    final firstName = _capitalizeEachWord(_firstNameController.text.trim());
    final lastName = _capitalizeEachWord(_lastNameController.text.trim());

    final success = await authViewModel.registerPendingDriver(
      firstName,
      lastName,
      _mobileController.text.trim(),
      _selectedVehicleType!.name,
      vehicleNumber,
      firebaseUid: authViewModel.newDriverInfo?['firebaseUid'],
      googleId: authViewModel.newDriverInfo?['googleId'],
      countryCode: _countryCode,
    );

    if (success && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const PendingApprovalScreen(),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authViewModel.error ?? 'Failed to submit registration'),
          backgroundColor: Colors.black,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: GestureDetector(
          onTap: () {
            // Dismiss keyboard when tapping outside
            FocusScope.of(context).unfocus();
          },
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
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child:
                          const Icon(Icons.arrow_back, color: Colors.black, size: 20),
                    ),
                  ),
                  const SizedBox(height: 40),
                  const Text(
                    "Confirm your information",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // First Name
                  _buildNameField(),
                  const SizedBox(height: 16),

                  // Last Name
                  _buildLastNameField(),
                  const SizedBox(height: 16),

                  // Mobile Number
                  _buildMobileField(),
                  const SizedBox(height: 16),

                  // Vehicle Type
                  _buildVehicleTypeField(),
                  const SizedBox(height: 16),

                  // Vehicle Number
                  _buildVehicleNumberField(),
                  const SizedBox(height: 24),

                  const Text(
                    "By continuing, you agree to calls, including by autodialer, WhatsApp, or texts from Taxi Nanban and its affiliates.",
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6C757D),
                      height: 1.6,
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Next Button
                  _buildNextButton(authViewModel),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'First name',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF212529),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _firstNameController,
          textCapitalization: TextCapitalization.words,
          onChanged: (value) {
            setState(() {}); // Update button state
          },
          decoration: InputDecoration(
            hintText: 'Enter your first name',
            hintStyle: const TextStyle(color: Color(0xFFADB5BD)),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE9ECEF), width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE9ECEF), width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFFF6D00), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFFF4444), width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFFF4444), width: 2),
            ),
            suffixIcon: _firstNameController.text.trim().length >= 3 &&
                    RegExp(r'^[a-zA-Z\s]+$')
                        .hasMatch(_firstNameController.text.trim())
                ? const Icon(Icons.check_circle, color: Color(0xFF22C55E), size: 20)
                : null,
          ),
          autovalidateMode: AutovalidateMode.onUserInteraction,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter your first name';
            }
            if (value.trim().length < 3) {
              return 'First name must be at least 3 characters';
            }
            if (value.trim().length > 40) {
              return 'First name must be at most 40 characters';
            }
            if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value.trim())) {
              return 'First name can only contain letters and spaces';
            }
            return null;
          },
          style: const TextStyle(fontSize: 16, color: Color(0xFF212529)),
        ),
      ],
    );
  }

  Widget _buildLastNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Last name (optional)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF212529),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _lastNameController,
          textCapitalization: TextCapitalization.words,
          onChanged: (value) {
            setState(() {}); // Update button state
          },
          decoration: InputDecoration(
            hintText: 'Enter your last name',
            hintStyle: const TextStyle(color: Color(0xFFADB5BD)),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE9ECEF), width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE9ECEF), width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFFF6D00), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFFF4444), width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFFF4444), width: 2),
            ),
          ),
          autovalidateMode: AutovalidateMode.onUserInteraction,
          validator: (value) {
            if (value != null && value.trim().isNotEmpty) {
              if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value.trim())) {
                return 'Last name can only contain letters and spaces';
              }
            }
            return null;
          },
          style: const TextStyle(fontSize: 16, color: Color(0xFF212529)),
        ),
      ],
    );
  }

  Widget _buildMobileField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mobile number',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF212529),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE9ECEF), width: 1.5),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.network(
                      'https://flagcdn.com/w40/in.png',
                      width: 24,
                      height: 16,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.flag, size: 20),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '+91',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF212529),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_drop_down, size: 20, color: Color(0xFFADB5BD)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _mobileController,
                keyboardType: TextInputType.number,
                enabled: !_isMobileVerified,
                maxLength: 10,
                onChanged: (value) {
                  setState(() {});
                },
                decoration: InputDecoration(
                  hintText: '9876543210',
                  hintStyle: const TextStyle(color: Color(0xFFADB5BD)),
                  filled: true,
                  fillColor: Colors.white,
                  counterText: '',
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 16,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFE9ECEF), width: 1.5),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFE9ECEF), width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFFF6D00), width: 2),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFFF4444), width: 1.5),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFFF4444), width: 2),
                  ),
                  suffixIcon: _isMobileVerified
                      ? const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(width: 8),
                            Icon(Icons.check_circle, color: Color(0xFF22C55E), size: 20),
                            SizedBox(width: 6),
                            Text(
                              'Verified',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF22C55E),
                              ),
                            ),
                            SizedBox(width: 12),
                          ],
                        )
                      : _mobileController.text.trim().length == 10
                          ? const Icon(Icons.check_circle,
                              color: Color(0xFF22C55E), size: 20)
                          : null,
                ),
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter a valid 10-digit mobile number';
                  }
                  if (value.trim().length != 10) {
                    return 'Enter a valid 10-digit mobile number';
                  }
                  if (!RegExp(r'^[0-9]{10}$').hasMatch(value.trim())) {
                    return 'Enter a valid 10-digit mobile number';
                  }
                  return null;
                },
                style: const TextStyle(fontSize: 16, color: Color(0xFF212529)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVehicleTypeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Vehicle type',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF212529),
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<VehicleType>(
          value: _selectedVehicleType,
          onChanged: (VehicleType? data) {
            setState(() {
              _selectedVehicleType = data;
            });
          },
          items: vehicleTypes.map((VehicleType type) {
            return DropdownMenuItem<VehicleType>(
              value: type,
              child: Row(
                children: [
                  Icon(type.icon, color: const Color(0xFF6C757D)),
                  const SizedBox(width: 12),
                  Text(
                    type.name,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF212529),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          decoration: InputDecoration(
            hintText: 'Select your vehicle type',
            hintStyle: const TextStyle(color: Color(0xFFADB5BD)),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE9ECEF), width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE9ECEF), width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFFF6D00), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFFF4444), width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFFF4444), width: 2),
            ),
            suffixIcon: _selectedVehicleType != null
                ? const Icon(Icons.check_circle, color: Color(0xFF22C55E), size: 20)
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildVehicleNumberField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Vehicle number',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF212529),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _vehicleNumberController,
          textCapitalization: TextCapitalization.characters,
          onChanged: (value) {
            final formatted = _formatVehicleNumber(value);
            if (value != formatted) {
              _vehicleNumberController.value = TextEditingValue(
                text: formatted,
                selection: TextSelection.collapsed(offset: formatted.length),
              );
            }
            setState(() {});
          },
          decoration: InputDecoration(
            hintText: 'TN 01 AB 1234',
            hintStyle: const TextStyle(color: Color(0xFFADB5BD)),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE9ECEF), width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE9ECEF), width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFFF6D00), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFFF4444), width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFFF4444), width: 2),
            ),
            suffixIcon: _isVehicleNumberValid(_vehicleNumberController.text)
                ? const Icon(Icons.check_circle, color: Color(0xFF22C55E), size: 20)
                : null,
            errorStyle: const TextStyle(color: Color(0xFFFF4444), fontSize: 13),
          ),
          autovalidateMode: AutovalidateMode.onUserInteraction,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter your vehicle number';
            }
            if (!_isVehicleNumberValid(value)) {
              return 'Please enter a valid Indian vehicle number (e.g. TN01AB1234)';
            }
            return null;
          },
          style: const TextStyle(fontSize: 16, color: Color(0xFF212529)),
        ),
      ],
    );
  }

  Widget _buildNextButton(AuthViewModel authViewModel) {
    final isFormValid = _isFormValid();
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: isFormValid
            ? const LinearGradient(
                colors: [
                  Color(0xFFFF6D00),
                  Color(0xFFFF8F00),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              )
            : LinearGradient(
                colors: [
                  Colors.grey.shade300,
                  Colors.grey.shade300,
                ],
              ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: isFormValid
            ? [
                BoxShadow(
                  color: const Color(0xFFFF6D00).withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(28),
        child: InkWell(
          onTap: isFormValid && !authViewModel.isLoading ? _completeOnboarding : null,
          borderRadius: BorderRadius.circular(28),
          child: Center(
            child: authViewModel.isLoading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : const Text(
                    'Next',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
