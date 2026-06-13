import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../home/home_screen.dart';
import '../wallet/wallet_screen.dart';
import '../vehicle/vehicle_management_screen.dart';
import '../auth/login_screen.dart';
import '../../viewmodels/theme_viewmodel.dart';
import '../profile/bank_details_screen.dart';
import './privacy_settings_screen.dart';
import './change_password_screen.dart';
import '../support/help_center_screen.dart';
import '../support/static_page_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final themeViewModel = Provider.of<ThemeViewModel>(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top Header with Gradient
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 60, left: 24, right: 24, bottom: 40),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF2D2D2D), Color(0xFFE65100)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                      onPressed: () {
                        if (Navigator.canPop(context)) {
                          Navigator.pop(context);
                        } else {
                          HomeScreen.of(context)?.setSelectedIndex(0);
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Settings',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'Manage your preferences',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ACCOUNT SECTION
            _buildSectionHeader('ACCOUNT'),
            _buildSettingsCard([
              _buildSettingItem(
                Icons.person_outline, 
                'Personal Information', 
                onTap: () {
                  HomeScreen.of(context)?.setSelectedIndex(3); // Index for ProfileScreen
                },
              ),
              const Divider(height: 1, indent: 60),
              _buildSettingItem(
                Icons.credit_card_outlined, 
                'Payment Methods', 
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const WalletScreen()),
                  );
                },
              ),
              const Divider(height: 1, indent: 60),
              _buildSettingItem(
                Icons.description_outlined, 
                'Documents', 
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const VehicleManagementScreen()),
                  );
                },
              ),
              const Divider(height: 1, indent: 60),
              _buildSettingItem(
                Icons.account_balance_outlined, 
                'Bank Details', 
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const BankDetailsScreen()),
                  );
                },
              ),
            ]),

            const SizedBox(height: 24),

            // PREFERENCES SECTION
            _buildSectionHeader('PREFERENCES'),
            _buildSettingsCard([
              _buildSettingItem(
                Icons.dark_mode_outlined, 
                'Dark Mode', 
                trailing: Switch(
                  value: themeViewModel.isDarkMode,
                  onChanged: (value) {
                    themeViewModel.toggleTheme(value);
                  },
                  activeThumbColor: const Color(0xFFFF6D00),
                ),
              ),
              const Divider(height: 1, indent: 60),
              _buildSettingItem(
                Icons.notifications_none_outlined,
                'Notifications',
                trailing: Switch(
                  value: _notificationsEnabled,
                  onChanged: (v) => setState(() => _notificationsEnabled = v),
                  activeThumbColor: const Color(0xFFFF6D00),
                ),
              ),
            ]),

            const SizedBox(height: 24),

            // SECURITY SECTION
            _buildSectionHeader('SECURITY'),
            _buildSettingsCard([
              _buildSettingItem(
                Icons.shield_outlined, 
                'Privacy Settings', 
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const PrivacySettingsScreen()),
                  );
                },
              ),
              const Divider(height: 1, indent: 60),
              _buildSettingItem(
                Icons.lock_outline, 
                'Change Password', 
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ChangePasswordScreen()),
                  );
                },
              ),
            ]),

            const SizedBox(height: 24),

            // SUPPORT SECTION
            _buildSectionHeader('SUPPORT'),
            _buildSettingsCard([
              _buildSettingItem(
                Icons.help_outline, 
                'Help Center', 
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const HelpCenterScreen()),
                  );
                },
              ),
              const Divider(height: 1, indent: 60),
              _buildSettingItem(
                Icons.article_outlined, 
                'Terms & Conditions', 
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const StaticPageScreen(
                        title: 'Terms & Conditions',
                        content: 'These Terms & Conditions govern your use of the TaxiNanban Driver app. By using the app, you agree to these terms in full...',
                      ),
                    ),
                  );
                },
              ),
              const Divider(height: 1, indent: 60),
              _buildSettingItem(
                Icons.privacy_tip_outlined, 
                'Privacy Policy', 
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const StaticPageScreen(
                        title: 'Privacy Policy',
                        content: 'Your privacy is important to us. This Privacy Policy explains how we collect, use, and share your personal information...',
                      ),
                    ),
                  );
                },
              ),
            ]),

            const SizedBox(height: 40),

            // Footer info
            const Text(
              'Version 2.5.0',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const Text(
              'TaxiNanban Driver App',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),

            const SizedBox(height: 24),

            // Logout Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: OutlinedButton.icon(
                onPressed: () async {
                  final navigator = Navigator.of(context);
                  await authViewModel.logout();
                  navigator.pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (route) => false,
                  );
                },
                icon: const Icon(Icons.logout, size: 18),
                label: const Text('Logout'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildSettingItem(IconData icon, String label, {Widget? trailing, VoidCallback? onTap}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDark ? theme.scaffoldBackgroundColor : const Color(0xFFF5F5F5),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: theme.colorScheme.onSurface, size: 22),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurface,
        ),
      ),
      trailing: trailing ?? Icon(Icons.chevron_right, color: theme.hintColor, size: 20),
    );
  }
}


