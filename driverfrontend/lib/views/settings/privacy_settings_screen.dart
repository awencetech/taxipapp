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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Settings'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildPrivacyTile(
            'Profile Visibility',
            'Allow others to see your profile details',
            _profileVisible,
            (v) => setState(() => _profileVisible = v),
          ),
          const Divider(),
          _buildPrivacyTile(
            'Share Location',
            'Share your real-time location with passengers',
            _shareLocation,
            (v) => setState(() => _shareLocation = v),
          ),
          const Divider(),
          _buildPrivacyTile(
            'Read Receipts',
            'Let others know when you have read their messages',
            _readReceipts,
            (v) => setState(() => _readReceipts = v),
          ),
          const SizedBox(height: 32),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Your privacy is important to us. These settings help you control how your information is shared within the app.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyTile(String title, String subtitle, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
      activeThumbColor: const Color(0xFFFF6D00),
    );
  }
}
