import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  PackageInfo? _packageInfo;

  @override
  void initState() {
    super.initState();
    _initPackageInfo();
  }

  Future<void> _initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _packageInfo = info;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 60,
              child: Icon(
                Icons.directions_car,
                size: 60,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Taxi Vendor App',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            if (_packageInfo != null)
              Text(
                'Version ${_packageInfo!.version} (${_packageInfo!.buildNumber})',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            const SizedBox(height: 32),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('App Information'),
              subtitle: const Text(
                  'A comprehensive vendor app for managing taxi services, drivers, and earnings.'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.developer_mode_outlined),
              title: const Text('Developed By'),
              subtitle: const Text('Your Company Name'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.copyright_outlined),
              title: const Text('Copyright'),
              subtitle: Text('© ${DateTime.now().year} All Rights Reserved'),
            ),
          ],
        ),
      ),
    );
  }
}