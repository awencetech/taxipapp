import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/address_provider.dart';
import '../../core/models/address_model.dart';
import '../../core/theme/app_colors.dart';

class SavedAddressesScreen extends StatefulWidget {
  const SavedAddressesScreen({super.key});

  @override
  State<SavedAddressesScreen> createState() => _SavedAddressesScreenState();
}

class _SavedAddressesScreenState extends State<SavedAddressesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AddressProvider>(context, listen: false).fetchAddresses();
    });
  }

  @override
  Widget build(BuildContext context) {
    final addressProvider = Provider.of<AddressProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Saved Addresses',
            style: TextStyle(color: AppColors.black)),
      ),
      body: addressProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : addressProvider.addresses.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.location_on_outlined,
                          size: 80, color: AppColors.grey400),
                      SizedBox(height: 16),
                      Text('No addresses saved yet',
                          style: TextStyle(color: AppColors.grey600)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: addressProvider.addresses.length,
                  itemBuilder: (context, index) {
                    final address = addressProvider.addresses[index];
                    return _buildAddressCard(address, addressProvider);
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddAddressDialog(),
        backgroundColor: AppColors.secondary,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildAddressCard(AddressModel address, AddressProvider provider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getTypeColor(address.type).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    address.type.toUpperCase(),
                    style: TextStyle(
                      color: _getTypeColor(address.type),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                if (address.isDefault) const SizedBox(width: 8),
                if (address.isDefault)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'DEFAULT',
                      style: TextStyle(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                const Spacer(),
                PopupMenuButton(
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                        leading: Icon(Icons.edit),
                        title: Text('Edit'),
                      ),
                    ),
                    if (!address.isDefault)
                      const PopupMenuItem(
                        value: 'default',
                        child: ListTile(
                          leading: Icon(Icons.check_circle_outline),
                          title: Text('Set as Default'),
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(Icons.delete_outline, color: Colors.red),
                        title:
                            Text('Delete', style: TextStyle(color: Colors.red)),
                      ),
                    ),
                  ],
                  onSelected: (value) =>
                      _handleAddressAction(value, address, provider),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              address.label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              address.address,
              style: const TextStyle(color: AppColors.grey600),
            ),
            if (address.landmark != null)
              Text(
                address.landmark!,
                style: const TextStyle(color: AppColors.grey600, fontSize: 12),
              ),
            Text(
              '${address.city}, ${address.state} - ${address.pincode}',
              style: const TextStyle(color: AppColors.grey600),
            ),
          ],
        ),
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'home':
        return AppColors.secondary;
      case 'work':
        return const Color(0xFF4A90E2);
      default:
        return const Color(0xFF9B59B6);
    }
  }

  void _handleAddressAction(
      dynamic value, AddressModel address, AddressProvider provider) async {
    switch (value) {
      case 'edit':
        _showAddAddressDialog(address: address);
        break;
      case 'default':
        await provider.setDefaultAddress(address.id);
        break;
      case 'delete':
        bool? confirm = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Address'),
            content:
                const Text('Are you sure you want to delete this address?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child:
                    const Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
        if (confirm == true) {
          await provider.deleteAddress(address.id);
        }
        break;
    }
  }

  void _showAddAddressDialog({AddressModel? address}) {
    showDialog(
      context: context,
      builder: (context) => AddAddressDialog(address: address),
    );
  }
}

class AddAddressDialog extends StatefulWidget {
  final AddressModel? address;

  const AddAddressDialog({super.key, this.address});

  @override
  State<AddAddressDialog> createState() => _AddAddressDialogState();
}

class _AddAddressDialogState extends State<AddAddressDialog> {
  final _formKey = GlobalKey<FormState>();
  final _labelController = TextEditingController();
  final _addressController = TextEditingController();
  final _landmarkController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  String _selectedType = 'home';

  @override
  void initState() {
    super.initState();
    if (widget.address != null) {
      _labelController.text = widget.address!.label;
      _addressController.text = widget.address!.address;
      _landmarkController.text = widget.address!.landmark ?? '';
      _cityController.text = widget.address!.city;
      _stateController.text = widget.address!.state;
      _pincodeController.text = widget.address!.pincode;
      _selectedType = widget.address!.type;
    }
  }

  @override
  void dispose() {
    _labelController.dispose();
    _addressController.dispose();
    _landmarkController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = Provider.of<AddressProvider>(context, listen: false);
    final newAddress = AddressModel(
      id: widget.address?.id ?? '',
      type: _selectedType,
      label: _labelController.text,
      address: _addressController.text,
      landmark:
          _landmarkController.text.isNotEmpty ? _landmarkController.text : null,
      city: _cityController.text,
      state: _stateController.text,
      pincode: _pincodeController.text,
      latitude: 0.0,
      longitude: 0.0,
      isDefault: widget.address?.isDefault ?? false,
    );

    bool success;
    if (widget.address != null) {
      success = await provider.updateAddress(newAddress);
    } else {
      success = await provider.addAddress(newAddress);
    }

    if (mounted) {
      if (success) {
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.error ?? 'Failed to save address')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AddressProvider>(context);
    return AlertDialog(
      title: Text(widget.address != null ? 'Edit Address' : 'Add New Address'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _selectedType,
                decoration: InputDecoration(
                  labelText: 'Address Type',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                items: const [
                  DropdownMenuItem(value: 'home', child: Text('Home')),
                  DropdownMenuItem(value: 'work', child: Text('Work')),
                  DropdownMenuItem(value: 'other', child: Text('Other')),
                ],
                onChanged: (value) => setState(() => _selectedType = value!),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _labelController,
                decoration: InputDecoration(
                  labelText: 'Label',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _landmarkController,
                decoration: InputDecoration(
                  labelText: 'Landmark (Optional)',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _cityController,
                decoration: InputDecoration(
                  labelText: 'City',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _stateController,
                decoration: InputDecoration(
                  labelText: 'State',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _pincodeController,
                decoration: InputDecoration(
                  labelText: 'Pincode',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel')),
        TextButton(
            onPressed: provider.isLoading ? null : _saveAddress,
            child: provider.isLoading
                ? const CircularProgressIndicator()
                : Text(widget.address != null ? 'Update' : 'Save')),
      ],
    );
  }
}
