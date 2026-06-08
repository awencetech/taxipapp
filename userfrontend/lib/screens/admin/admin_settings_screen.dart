import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../models/settings_model.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _baseFareController = TextEditingController();
  final _pricePerKmController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<AdminProvider>();
      await provider.fetchSettings();
      if (provider.settings != null) {
        _nameController.text = provider.settings!.adminName;
        _emailController.text = provider.settings!.adminEmail;
        _phoneController.text = provider.settings!.adminPhone;
        _baseFareController.text = provider.settings!.baseFare.toString();
        _pricePerKmController.text = provider.settings!.pricePerKm.toString();
      }
    });
  }

  void _saveSettings() async {
    if (_formKey.currentState!.validate()) {
      final newSettings = SettingsModel(
        adminName: _nameController.text,
        adminEmail: _emailController.text,
        adminPhone: _phoneController.text,
        baseFare: double.parse(_baseFareController.text),
        pricePerKm: double.parse(_pricePerKmController.text),
      );

      final success =
          await context.read<AdminProvider>().updateSettings(newSettings);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                success ? 'Settings updated successfully' : 'Update failed'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.settings == null) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null && provider.settings == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: ${provider.error}', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => provider.fetchSettings(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('Admin Profile'),
                const SizedBox(height: 16),
                _buildTextField('Full Name', _nameController, Icons.person),
                const SizedBox(height: 16),
                _buildTextField('Email', _emailController, Icons.email,
                    isEmail: true),
                const SizedBox(height: 16),
                _buildTextField('Phone', _phoneController, Icons.phone),
                const SizedBox(height: 32),
                _buildSectionTitle('App Configuration'),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                        child: _buildTextField(
                            'Base Fare (₹)', _baseFareController, Icons.money,
                            isNumber: true)),
                    const SizedBox(width: 16),
                    Expanded(
                        child: _buildTextField('Price per KM (₹)',
                            _pricePerKmController, Icons.add_road,
                            isNumber: true)),
                  ],
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton.icon(
                    onPressed: provider.isLoading ? null : _saveSettings,
                    icon: provider.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.save, color: Colors.white),
                    label: const Text('SAVE SETTINGS',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
          fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
    );
  }

  Widget _buildTextField(
      String label, TextEditingController controller, IconData icon,
      {bool isEmail = false, bool isNumber = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber
          ? TextInputType.number
          : (isEmail ? TextInputType.emailAddress : TextInputType.text),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey.withValues(alpha: 0.05),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Field required';
        if (isNumber && double.tryParse(value) == null) {
          return 'Enter valid number';
        }
        return null;
      },
    );
  }
}
