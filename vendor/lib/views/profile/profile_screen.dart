import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/theme_viewmodel.dart';
import '../../services/profile_service.dart';
import '../auth/login_screen.dart';
import '../dashboard/dashboard_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String companyName = 'FleetHub Vendor Services';
  String vendorId = 'VND-2024-001';
  String ownerName = 'Ramesh Patel';
  String designation = 'Managing Director';
  String email = 'vendor@fleethub.com';
  String phoneNumber = '+91 98765 43210';
  String alternatePhone = '+91 98765 43211';
  String city = 'Mumbai, Maharashtra';

  bool isEditingProfile = false;
  bool isEditingContact = false;

  final TextEditingController companyNameController = TextEditingController();
  final TextEditingController ownerNameController = TextEditingController();
  final TextEditingController designationController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController alternatePhoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      companyName = prefs.getString('companyName') ?? companyName;
      ownerName = prefs.getString('ownerName') ?? ownerName;
      designation = prefs.getString('designation') ?? designation;
      email = prefs.getString('email') ?? email;
      phoneNumber = prefs.getString('phoneNumber') ?? phoneNumber;
      alternatePhone = prefs.getString('alternatePhone') ?? alternatePhone;
    });
    companyNameController.text = companyName;
    ownerNameController.text = ownerName;
    designationController.text = designation;
    emailController.text = email;
    phoneController.text = phoneNumber;
    alternatePhoneController.text = alternatePhone;
  }

  Future<void> _saveProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('companyName', companyName);
    await prefs.setString('ownerName', ownerName);
    await prefs.setString('designation', designation);
    await prefs.setString('email', email);
    await prefs.setString('phoneNumber', phoneNumber);
    await prefs.setString('alternatePhone', alternatePhone);
    
    final profileService = Provider.of<ProfileService>(context, listen: false);
    await profileService.updateUserName(ownerName);
  }

  Future<void> _pickImage() async {
    final mainContext = context;
    showModalBottomSheet(
      context: mainContext,
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Photo Gallery'),
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  final profileService = Provider.of<ProfileService>(mainContext, listen: false);
                  await profileService.updateProfileImage(ImageSource.gallery);
                  await _loadProfile();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Camera'),
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  final profileService = Provider.of<ProfileService>(mainContext, listen: false);
                  await profileService.updateProfileImage(ImageSource.camera);
                  await _loadProfile();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);
    final themeVM = context.watch<ThemeViewModel>();
    final isDark = themeVM.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF0F4FF),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      isDark ? const Color(0xFF0D1B2A) : const Color(0xFF1D2951),
                      isDark ? const Color(0xFF1B263B) : const Color(0xFF2D4A6D),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const DashboardScreen()),
                          (route) => false,
                        );
                      },
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 26),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Profile',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Manage your vendor profile and account information',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Profile Info Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Consumer<ProfileService>(
                  builder: (context, profileService, child) {
                    final imageProvider = profileService.getImageProvider();
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFFECD2),
                            isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFFF3E0),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(
                          color: isDark ? Colors.grey[700]! : const Color(0xFFFF7A00).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          Center(
                            child: Stack(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFFF7A00).withValues(alpha: 0.4),
                                        blurRadius: 30,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: CircleAvatar(
                                    radius: 70,
                                    backgroundColor: Colors.grey[200],
                                    backgroundImage: imageProvider,
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: GestureDetector(
                                    onTap: _pickImage,
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFFF7A00),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black12,
                                            blurRadius: 10,
                                            offset: Offset(0, 5),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.camera_alt,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      const SizedBox(height: 24),
                      Text(
                        companyName,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0F7E9),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Text(
                              'Verified',
                              style: TextStyle(
                                color: Color(0xFF22C55E),
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildProfileItemRow(
                        'Vendor ID:',
                        vendorId,
                        Icons.badge_outlined,
                        isDark,
                      ),
                    ],
                  ),
                  );
                },
                ),
              ),

              const SizedBox(height: 24),

              // Stats Cards (More Colorful!)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    _buildStatCard(
                      'Total Revenue',
                      '₹12.5L',
                      '+15.3% this month',
                      const Color(0xFF22C55E),
                      const Color(0xFFE0F7E9),
                      isDark,
                    ),
                    const SizedBox(height: 16),
                    _buildStatCard(
                      'Active Drivers',
                      '124',
                      '8 new this week',
                      const Color(0xFF4A90E2),
                      const Color(0xFFDBEAFE),
                      isDark,
                    ),
                    const SizedBox(height: 16),
                    _buildStatCard(
                      'Fleet Size',
                      '98',
                      'All vehicles',
                      const Color(0xFF9B59B6),
                      const Color(0xFFF3E5F5),
                      isDark,
                    ),
                    const SizedBox(height: 16),
                    _buildStatCard(
                      'Completed Trips',
                      '5,678',
                      'Last 30 days',
                      const Color(0xFFFF7A00),
                      const Color(0xFFFFECD2),
                      isDark,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Profile Information
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(
                      color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Profile Information',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              setState(() {
                                isEditingProfile = !isEditingProfile;
                              });
                              if (!isEditingProfile) {
                                setState(() {
                                  companyName = companyNameController.text;
                                  ownerName = ownerNameController.text;
                                  designation = designationController.text;
                                });
                                _saveProfile();
                              }
                            },
                            icon: const Icon(Icons.edit, size: 18),
                            label: Text(isEditingProfile ? 'Save' : 'Edit Profile'),
                            style: TextButton.styleFrom(
                              foregroundColor: isDark ? Colors.white : const Color(0xFF1F2937),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: isDark ? Colors.grey[600]! : Colors.grey[300]!,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildEditableField(
                        'Company Name',
                        companyNameController,
                        isEditingProfile,
                        isDark,
                      ),
                      const SizedBox(height: 16),
                      _buildEditableField(
                        'Owner Name',
                        ownerNameController,
                        isEditingProfile,
                        isDark,
                      ),
                      const SizedBox(height: 16),
                      _buildEditableField(
                        'Designation',
                        designationController,
                        isEditingProfile,
                        isDark,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Contact Information
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(
                      color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Contact Information',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              setState(() {
                                isEditingContact = !isEditingContact;
                              });
                              if (!isEditingContact) {
                                setState(() {
                                  email = emailController.text;
                                  phoneNumber = phoneController.text;
                                  alternatePhone = alternatePhoneController.text;
                                });
                                _saveProfile();
                              }
                            },
                            icon: const Icon(Icons.edit, size: 18),
                            label: Text(isEditingContact ? 'Save' : 'Edit Contact'),
                            style: TextButton.styleFrom(
                              foregroundColor: isDark ? Colors.white : const Color(0xFF1F2937),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: isDark ? Colors.grey[600]! : Colors.grey[300]!,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildEditableField(
                        'Email Address',
                        emailController,
                        isEditingContact,
                        isDark,
                        icon: Icons.email_outlined,
                      ),
                      const SizedBox(height: 16),
                      _buildEditableField(
                        'Phone Number',
                        phoneController,
                        isEditingContact,
                        isDark,
                        icon: Icons.phone_outlined,
                      ),
                      const SizedBox(height: 16),
                      _buildEditableField(
                        'Alternate Phone',
                        alternatePhoneController,
                        isEditingContact,
                        isDark,
                        icon: Icons.phone_outlined,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Logout Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  height: 56,
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await authViewModel.logout();
                      if (context.mounted) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                          (route) => false,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.logout, size: 24),
                    label: const Text(
                      'Logout',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileItemRow(String label, String value, IconData icon, bool isDark) {
    return Row(
      children: [
        Icon(icon, size: 16, color: isDark ? Colors.grey[400] : Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label.isEmpty ? value : '$label $value',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, String subtitle, Color primaryColor, Color bgColor, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            isDark ? const Color(0xFF1E1E1E) : bgColor,
            isDark ? const Color(0xFF1E1E1E) : Colors.white,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isDark ? Colors.grey[700]! : primaryColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableField(String label, TextEditingController controller, bool isEditing, bool isDark, {IconData? icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[800] : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(16),
          ),
          child: isEditing
              ? TextField(
                  controller: controller,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontSize: 15,
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                  ),
                )
              : Text(
                  controller.text,
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF1F2937),
                    fontSize: 15,
                  ),
                ),
        ),
      ],
    );
  }
}
