import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import 'package:cached_network_image/cached_network_image.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _nameController;
  late TextEditingController _mobileController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _vehicleTypeController;
  late TextEditingController _vehicleNumberController;

  XFile? _pickedImage;
  String? _currentProfilePic;

  @override
  void initState() {
    super.initState();
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final driver = authViewModel.driver;

    _nameController = TextEditingController(text: driver?.name ?? '');
    _mobileController = TextEditingController(text: driver?.mobile ?? '');
    _emailController = TextEditingController(text: driver?.email ?? '');
    _addressController = TextEditingController(text: driver?.address ?? 'Koramangala, Bangalore, Karnataka');
    _vehicleTypeController = TextEditingController(text: driver?.vehicleType ?? '');
    _vehicleNumberController = TextEditingController(text: driver?.vehicleNumber ?? '');
    _currentProfilePic = driver?.profilePic;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _vehicleTypeController.dispose();
    _vehicleNumberController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      debugPrint('Picked image path: ${image.path}');
      setState(() {
        _pickedImage = image;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    
    bool success = await authViewModel.updateDriverProfile(
      name: _nameController.text,
      mobile: _mobileController.text,
      email: _emailController.text,
      address: _addressController.text,
      vehicleType: _vehicleTypeController.text,
      vehicleNumber: _vehicleNumberController.text,
      profilePicFile: _pickedImage,
      profilePicUrl: _currentProfilePic,
    );

    debugPrint('Profile update success: $success');

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authViewModel.error ?? 'Failed to update profile'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: authViewModel.isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF6D00)))
          : SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Top Header with Gradient
                    Stack(
                      children: [
                        Container(
                          width: double.infinity,
                          height: 220,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF2D2D2D), Color(0xFFE65100)],
                            ),
                          ),
                        ),
                        SafeArea(
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Row(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: IconButton(
                                        icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                                        onPressed: () => Navigator.pop(context),
                                      ),
                                    ),
                                    const Expanded(
                                      child: Center(
                                        child: Text(
                                          'Edit Profile',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 48), // Spacer to balance back button
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                              Center(
                                child: Stack(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 4),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.1),
                                            blurRadius: 10,
                                            offset: const Offset(0, 5),
                                          ),
                                        ],
                                      ),
                                      child: CircleAvatar(
                                        radius: 60,
                                        backgroundColor: Colors.white,
                                        backgroundImage: _pickedImage != null
                                            ? (kIsWeb
                                                  ? NetworkImage(_pickedImage!.path)
                                                  : FileImage(File(_pickedImage!.path))
                                                        as ImageProvider)
                                            : (_currentProfilePic != null &&
                                                      _currentProfilePic!.isNotEmpty
                                                  ? CachedNetworkImageProvider(_currentProfilePic!)
                                                  : null),
                                        child: _pickedImage == null &&
                                                (_currentProfilePic == null || _currentProfilePic!.isEmpty)
                                            ? const Icon(Icons.person, size: 60, color: Colors.grey)
                                            : null,
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: GestureDetector(
                                        onTap: _pickImage,
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: const BoxDecoration(
                                            color: Color(0xFFFF6D00),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.camera_alt,
                                            size: 20,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),

                    // Input Fields
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle('PERSONAL INFORMATION'),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _nameController,
                            label: 'Full Name',
                            icon: Icons.person_outline,
                            validator: (value) => value?.isEmpty ?? true ? 'Enter your name' : null,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _mobileController,
                            label: 'Mobile Number',
                            icon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                            validator: (value) => value?.isEmpty ?? true ? 'Enter mobile number' : null,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _emailController,
                            label: 'Email Address',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _addressController,
                            label: 'Address',
                            icon: Icons.location_on_outlined,
                            maxLines: 2,
                          ),
                          const SizedBox(height: 32),
                          _buildSectionTitle('VEHICLE INFORMATION'),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _vehicleTypeController,
                            label: 'Vehicle Type',
                            icon: Icons.directions_car_outlined,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _vehicleNumberController,
                            label: 'Vehicle Number',
                            icon: Icons.pin_outlined,
                          ),
                          const SizedBox(height: 40),
                          
                          // Save Button
                          SizedBox(
                            width: double.infinity,
                            height: 60,
                            child: ElevatedButton(
                              onPressed: _saveProfile,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFF6D00),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                elevation: 5,
                                shadowColor: const Color(0xFFFF6D00).withValues(alpha: 0.3),
                              ),
                              child: const Text(
                                'Save Changes',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    final theme = Theme.of(context);
    return Text(
      title,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: theme.hintColor,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        maxLines: maxLines,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurface,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: theme.hintColor,
            fontSize: 14,
            fontWeight: FontWeight.normal,
          ),
          prefixIcon: Icon(icon, color: const Color(0xFFFF6D00), size: 22),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: theme.cardColor,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }
}


