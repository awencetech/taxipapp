import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/notification_provider.dart';
import '../../core/theme/app_colors.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NotificationProvider>(context, listen: false).fetchSettings();
    });
  }

  Future<void> _saveSettings() async {
    final provider = Provider.of<NotificationProvider>(context, listen: false);
    bool success = await provider.updateSettings();
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved successfully!'),
          backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.error ?? 'Failed to save settings')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final notificationProvider = Provider.of<NotificationProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Notification Settings', style: TextStyle(color: AppColors.black)),
        actions: [
          TextButton(
            onPressed: notificationProvider.isLoading ? null : _saveSettings,
            child: const Text('Save'),
          ),
        ],
      ),
      body: notificationProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSectionTitle('Ride Notifications'),
                _buildSwitchTile(
                  title: 'Ride Updates',
                  subtitle: 'Get updates about your rides',
                  value: notificationProvider.settings.rideUpdates,
                  onChanged: (value) =>
                      notificationProvider.updateSetting('rideUpdates', value),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('Promotions'),
                _buildSwitchTile(
                  title: 'Promotional Offers',
                  subtitle: 'Get notified about offers and discounts',
                  value: notificationProvider.settings.promotionalOffers,
                  onChanged: (value) =>
                      notificationProvider.updateSetting('promotionalOffers', value),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('Wallet'),
                _buildSwitchTile(
                  title: 'Wallet Notifications',
                  subtitle: 'Get updates about your wallet balance',
                  value: notificationProvider.settings.walletNotifications,
                  onChanged: (value) =>
                      notificationProvider.updateSetting('walletNotifications', value),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('Referral'),
                _buildSwitchTile(
                  title: 'Referral Notifications',
                  subtitle: 'Get updates about your referrals',
                  value: notificationProvider.settings.referralNotifications,
                  onChanged: (value) =>
                      notificationProvider.updateSetting('referralNotifications', value),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('Alert Types'),
                _buildSwitchTile(
                  title: 'Push Notifications',
                  subtitle: 'Receive push notifications',
                  value: notificationProvider.settings.pushNotifications,
                  onChanged: (value) =>
                      notificationProvider.updateSetting('pushNotifications', value),
                ),
                const SizedBox(height: 12),
                _buildSwitchTile(
                  title: 'SMS Alerts',
                  subtitle: 'Receive SMS notifications',
                  value: notificationProvider.settings.smsAlerts,
                  onChanged: (value) =>
                      notificationProvider.updateSetting('smsAlerts', value),
                ),
                const SizedBox(height: 12),
                _buildSwitchTile(
                  title: 'Email Alerts',
                  subtitle: 'Receive email notifications',
                  value: notificationProvider.settings.emailAlerts,
                  onChanged: (value) =>
                      notificationProvider.updateSetting('emailAlerts', value),
                ),
              ],
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Card(
      child: SwitchListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle, style: const TextStyle(color: AppColors.grey600)),
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppColors.secondary,
      ),
    );
  }
}
