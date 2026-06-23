import 'package:flutter/material.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  bool _profileVisible = true;
  bool _shareLocation = true;
  bool _readReceipts = true;
  bool _rideHistoryVisible = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
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
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Privacy Settings',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Manage your privacy',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              children: [
                _buildPrivacyTile(
                  'Profile Visibility',
                  'Allow others to see your profile details',
                  _profileVisible,
                  (v) => setState(() => _profileVisible = v),
                ),
                const Divider(height: 1),
                _buildPrivacyTile(
                  'Share Location',
                  'Share your real-time location with passengers',
                  _shareLocation,
                  (v) => setState(() => _shareLocation = v),
                ),
                const Divider(height: 1),
                _buildPrivacyTile(
                  'Read Receipts',
                  'Let others know when you have read their messages',
                  _readReceipts,
                  (v) => setState(() => _readReceipts = v),
                ),
                const Divider(height: 1),
                _buildPrivacyTile(
                  'Ride History Visible',
                  'Allow other drivers to see your ride history',
                  _rideHistoryVisible,
                  (v) => setState(() => _rideHistoryVisible = v),
                ),
                const SizedBox(height: 32),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Your privacy is important to us. These settings help you control how your information is shared within the app.',
                    style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyTile(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
  ) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: theme.hintColor),
        ),
        value: value,
        onChanged: onChanged,
        activeThumbColor: const Color(0xFFFF6D00),
      ),
    );
  }
}
