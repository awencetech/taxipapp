import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/payment_provider.dart';
import '../../core/models/payment_method_model.dart';
import '../../core/theme/app_colors.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PaymentProvider>(context, listen: false)
          .fetchPaymentMethods();
    });
  }

  @override
  Widget build(BuildContext context) {
    final paymentProvider = Provider.of<PaymentProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Payment Methods',
            style: TextStyle(color: AppColors.black)),
      ),
      body: paymentProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Wallet
                _buildMethodCard(
                  icon: Icons.account_balance_wallet,
                  title: 'Wallet',
                  subtitle: 'Quick payments from wallet',
                  color: AppColors.secondary,
                  isDefault:
                      paymentProvider.defaultPaymentMethod?.type == 'wallet',
                ),
                const SizedBox(height: 16),
                // Add New Methods Section
                const Text('Add Payment Method',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _buildAddMethodTile(
                      icon: Icons.credit_card,
                      title: 'Credit Card',
                      onTap: () => _showAddCardDialog('credit'),
                    ),
                    _buildAddMethodTile(
                      icon: Icons.credit_card,
                      title: 'Debit Card',
                      onTap: () => _showAddCardDialog('debit'),
                    ),
                    _buildAddMethodTile(
                      icon: Icons.phone_android,
                      title: 'UPI',
                      onTap: () => _showAddUPIDialog(),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                // Saved Cards
                if (paymentProvider.paymentMethods.any((p) => p.type == 'card'))
                  const Text('Saved Cards',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                if (paymentProvider.paymentMethods.any((p) => p.type == 'card'))
                  const SizedBox(height: 16),
                ...paymentProvider.paymentMethods
                    .where((p) => p.type == 'card')
                    .map(
                      (method) => _buildSavedCardCard(method, paymentProvider),
                    ),
                // Saved UPI
                if (paymentProvider.paymentMethods.any((p) => p.type == 'upi'))
                  const SizedBox(height: 24),
                if (paymentProvider.paymentMethods.any((p) => p.type == 'upi'))
                  const Text('UPI IDs',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                if (paymentProvider.paymentMethods.any((p) => p.type == 'upi'))
                  const SizedBox(height: 16),
                ...paymentProvider.paymentMethods
                    .where((p) => p.type == 'upi')
                    .map(
                      (method) => _buildSavedUPICard(method, paymentProvider),
                    ),
              ],
            ),
    );
  }

  Widget _buildMethodCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    bool isDefault = false,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(subtitle,
                      style: const TextStyle(
                          color: AppColors.grey600, fontSize: 12)),
                ],
              ),
            ),
            if (isDefault)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('DEFAULT',
                    style: TextStyle(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.bold)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddMethodTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: (MediaQuery.of(context).size.width / 2) - 24,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.grey300),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: AppColors.grey600),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(color: AppColors.grey600)),
          ],
        ),
      ),
    );
  }

  Widget _buildSavedCardCard(
      PaymentMethodModel method, PaymentProvider provider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 32,
              decoration: BoxDecoration(
                color: method.cardType == 'credit' ? Colors.blue : Colors.green,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Center(
                  child:
                      Icon(Icons.credit_card, color: Colors.white, size: 20)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(method.maskedCardNumber,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(method.cardHolderName ?? '',
                      style: const TextStyle(color: AppColors.grey600)),
                ],
              ),
            ),
            if (method.isDefault)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('DEFAULT',
                    style: TextStyle(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.bold)),
              ),
            PopupMenuButton(
              itemBuilder: (context) => [
                if (!method.isDefault)
                  const PopupMenuItem(
                    value: 'default',
                    child: ListTile(
                        leading: Icon(Icons.check_circle_outline),
                        title: Text('Set as Default')),
                  ),
                const PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                      leading: Icon(Icons.delete_outline, color: Colors.red),
                      title:
                          Text('Delete', style: TextStyle(color: Colors.red))),
                ),
              ],
              onSelected: (value) =>
                  _handlePaymentAction(value, method, provider),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSavedUPICard(
      PaymentMethodModel method, PaymentProvider provider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.purple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.phone_android,
                  color: Colors.purple, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(method.upiId ?? '',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            if (method.isDefault)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('DEFAULT',
                    style: TextStyle(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.bold)),
              ),
            PopupMenuButton(
              itemBuilder: (context) => [
                if (!method.isDefault)
                  const PopupMenuItem(
                    value: 'default',
                    child: ListTile(
                        leading: Icon(Icons.check_circle_outline),
                        title: Text('Set as Default')),
                  ),
                const PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                      leading: Icon(Icons.delete_outline, color: Colors.red),
                      title:
                          Text('Delete', style: TextStyle(color: Colors.red))),
                ),
              ],
              onSelected: (value) =>
                  _handlePaymentAction(value, method, provider),
            ),
          ],
        ),
      ),
    );
  }

  void _handlePaymentAction(dynamic value, PaymentMethodModel method,
      PaymentProvider provider) async {
    switch (value) {
      case 'default':
        await provider.setDefaultPaymentMethod(method.id);
        break;
      case 'delete':
        bool? confirm = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Payment Method'),
            content: const Text(
                'Are you sure you want to delete this payment method?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel')),
              TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Delete',
                      style: TextStyle(color: Colors.red))),
            ],
          ),
        );
        if (confirm == true) {
          await provider.deletePaymentMethod(method.id);
        }
        break;
    }
  }

  void _showAddCardDialog(String cardType) {
    showDialog(
      context: context,
      builder: (context) => AddCardDialog(cardType: cardType),
    );
  }

  void _showAddUPIDialog() {
    showDialog(
      context: context,
      builder: (context) => const AddUPIDialog(),
    );
  }
}

class AddCardDialog extends StatefulWidget {
  final String cardType;

  const AddCardDialog({super.key, required this.cardType});

  @override
  State<AddCardDialog> createState() => _AddCardDialogState();
}

class _AddCardDialogState extends State<AddCardDialog> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _cardHolderNameController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _cvvController = TextEditingController();

  @override
  void dispose() {
    _cardNumberController.dispose();
    _cardHolderNameController.dispose();
    _expiryDateController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  Future<void> _saveCard() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = Provider.of<PaymentProvider>(context, listen: false);
    final newMethod = PaymentMethodModel(
      id: '',
      type: 'card',
      cardNumber: _cardNumberController.text,
      cardHolderName: _cardHolderNameController.text,
      expiryDate: _expiryDateController.text,
      cvv: _cvvController.text,
      cardType: widget.cardType,
      isDefault: provider.paymentMethods.isEmpty,
      isActive: true,
    );

    bool success = await provider.addPaymentMethod(newMethod);
    if (mounted) {
      if (success) {
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.error ?? 'Failed to save card')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PaymentProvider>(context);
    return AlertDialog(
      title:
          Text('Add ${widget.cardType == 'credit' ? 'Credit' : 'Debit'} Card'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _cardNumberController,
                decoration: InputDecoration(
                  labelText: 'Card Number',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  if (value.length < 13) return 'Invalid card number';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _cardHolderNameController,
                decoration: InputDecoration(
                  labelText: 'Card Holder Name',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _expiryDateController,
                      decoration: InputDecoration(
                        labelText: 'Expiry (MM/YY)',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Required';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _cvvController,
                      decoration: InputDecoration(
                        labelText: 'CVV',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      obscureText: true,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Required';
                        if (value.length < 3) return 'Invalid CVV';
                        return null;
                      },
                    ),
                  ),
                ],
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
            onPressed: provider.isLoading ? null : _saveCard,
            child: provider.isLoading
                ? const CircularProgressIndicator()
                : const Text('Add Card')),
      ],
    );
  }
}

class AddUPIDialog extends StatefulWidget {
  const AddUPIDialog({super.key});

  @override
  State<AddUPIDialog> createState() => _AddUPIDialogState();
}

class _AddUPIDialogState extends State<AddUPIDialog> {
  final _formKey = GlobalKey<FormState>();
  final _upiIdController = TextEditingController();

  @override
  void dispose() {
    _upiIdController.dispose();
    super.dispose();
  }

  Future<void> _saveUPI() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = Provider.of<PaymentProvider>(context, listen: false);
    final newMethod = PaymentMethodModel(
      id: '',
      type: 'upi',
      upiId: _upiIdController.text,
      isDefault: provider.paymentMethods.isEmpty,
      isActive: true,
    );

    bool success = await provider.addPaymentMethod(newMethod);
    if (mounted) {
      if (success) {
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.error ?? 'Failed to save UPI ID')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PaymentProvider>(context);
    return AlertDialog(
      title: const Text('Add UPI ID'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _upiIdController,
          decoration: InputDecoration(
            labelText: 'Enter UPI ID',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) return 'Required';
            if (!value.contains('@')) return 'Invalid UPI ID';
            return null;
          },
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel')),
        TextButton(
            onPressed: provider.isLoading ? null : _saveUPI,
            child: provider.isLoading
                ? const CircularProgressIndicator()
                : const Text('Add UPI')),
      ],
    );
  }
}
