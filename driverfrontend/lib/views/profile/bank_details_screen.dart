import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../models/driver_models.dart';

class BankDetailsScreen extends StatefulWidget {
  const BankDetailsScreen({super.key});

  @override
  State<BankDetailsScreen> createState() => _BankDetailsScreenState();
}

class _BankDetailsScreenState extends State<BankDetailsScreen> {
  List<BankAccountModel> _bankAccounts = [];
  int? _editingIndex;
  bool _isAddingNew = false;

  final _formKeys = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];

  @override
  void initState() {
    super.initState();
    final driver = context.read<AuthViewModel>().driver;
    if (driver != null) {
      _bankAccounts = List.from(driver.bankAccounts);
    }
  }

  @override
  void dispose() {
    for (var controller in _formKeys) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _saveAccounts() async {
    final authViewModel = context.read<AuthViewModel>();
    final success = await authViewModel.updateDriverProfile(
      bankAccounts: _bankAccounts,
    );
    if (success && mounted) {
      setState(() {
        _editingIndex = null;
        _isAddingNew = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bank details updated successfully!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authViewModel.error ?? 'Failed to update bank details'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _startEditing(int index) {
    final account = _bankAccounts[index];
    _formKeys[0].text = account.bankName;
    _formKeys[1].text = account.accountHolderName;
    _formKeys[2].text = account.accountNumber;
    _formKeys[3].text = account.ifscCode;
    _formKeys[4].text = account.branchName;
    setState(() {
      _editingIndex = index;
    });
  }

  void _startAdding() {
    for (var controller in _formKeys) {
      controller.clear();
    }
    setState(() {
      _isAddingNew = true;
    });
  }

  void _cancelEditing() {
    setState(() {
      _editingIndex = null;
      _isAddingNew = false;
    });
  }

  void _confirmDelete(int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Bank Account?'),
        content: const Text('Are you sure you want to remove this bank account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _bankAccounts.removeAt(index);
      });
      await _saveAccounts();
    }
  }

  void _saveNewOrEdited() {
    final bankName = _formKeys[0].text.trim();
    final accountHolderName = _formKeys[1].text.trim();
    final accountNumber = _formKeys[2].text.trim();
    final ifscCode = _formKeys[3].text.trim();
    final branchName = _formKeys[4].text.trim();

    if (bankName.isEmpty || accountHolderName.isEmpty || accountNumber.isEmpty || ifscCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields!'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final newAccount = BankAccountModel(
      bankName: bankName,
      accountHolderName: accountHolderName,
      accountNumber: accountNumber,
      ifscCode: ifscCode,
      branchName: branchName,
    );

    if (_isAddingNew) {
      setState(() {
        _bankAccounts.add(newAccount);
      });
    } else if (_editingIndex != null) {
      setState(() {
        _bankAccounts[_editingIndex!] = newAccount;
      });
    }
    _saveAccounts();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authViewModel = context.watch<AuthViewModel>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: authViewModel.isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF6D00)))
          : SingleChildScrollView(
              child: Column(
                children: _buildContent(context, theme, authViewModel),
              ),
            ),
    );
  }

  List<Widget> _buildContent(BuildContext context, ThemeData theme, AuthViewModel authViewModel) {
    final List<Widget> content = [];

    // Top Header with Gradient
    content.add(
      Stack(
        children: [
          Container(
            width: double.infinity,
            height: 200,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2D2D2D), Color(0xFFE65100)],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                  const Text(
                    'Bank Details',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_bankAccounts.length < 3)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.add, color: Colors.white, size: 20),
                        onPressed: _startAdding,
                      ),
                    )
                  else
                    const SizedBox(width: 48),
                ],
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 140),
            child: Center(
              child: Icon(
                Icons.account_balance,
                color: Colors.white,
                size: 60,
              ),
            ),
          ),
        ],
      ),
    );

    content.add(const SizedBox(height: 24));

    // Main Content
    final List<Widget> mainChildren = [];
    mainChildren.add(
      const Text(
        'Your Bank Accounts',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    mainChildren.add(const SizedBox(height: 16));

    // Empty state
    if (_bankAccounts.isEmpty && !_isAddingNew) {
      mainChildren.add(
        Center(
          child: Column(
            children: [
              const SizedBox(height: 40),
              Icon(Icons.account_balance_wallet, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No bank accounts added yet',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _startAdding,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6D00),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                icon: const Icon(Icons.add),
                label: const Text('Add Bank Account'),
              ),
            ],
          ),
        ),
      );
    } else {
      // List of bank accounts
      for (var i = 0; i < _bankAccounts.length; i++) {
        final account = _bankAccounts[i];
        final isEditingThis = _editingIndex == i;

        mainChildren.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: isEditingThis
                ? _buildEditAccountCard(
                    onSave: _saveNewOrEdited,
                    onCancel: _cancelEditing,
                  )
                : _buildAccountCard(
                    account: account,
                    onEdit: () => _startEditing(i),
                    onDelete: () => _confirmDelete(i),
                  ),
          ),
        );
      }

      // Add new account form
      if (_isAddingNew) {
        mainChildren.add(
          _buildEditAccountCard(
            onSave: _saveNewOrEdited,
            onCancel: _cancelEditing,
          ),
        );
      }
    }

    mainChildren.add(const SizedBox(height: 40));

    content.add(
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: mainChildren,
        ),
      ),
    );

    return content;
  }

  Widget _buildAccountCard({
    required BankAccountModel account,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    final List<Widget> columnChildren = [];
    columnChildren.add(
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6D00).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.account_balance,
                    color: Color(0xFFFF6D00),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        account.bankName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '**** ${account.accountNumber.substring(account.accountNumber.length - 4)}',
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.edit, color: Color(0xFFFF6D00)),
                onPressed: onEdit,
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
    columnChildren.add(const SizedBox(height: 12));
    columnChildren.add(_buildInfoRow('Account Holder', account.accountHolderName));
    columnChildren.add(const SizedBox(height: 8));
    columnChildren.add(_buildInfoRow('Account Number', account.accountNumber));
    columnChildren.add(const SizedBox(height: 8));
    columnChildren.add(_buildInfoRow('IFSC Code', account.ifscCode));
    if (account.branchName.isNotEmpty) {
      columnChildren.add(const SizedBox(height: 8));
      columnChildren.add(_buildInfoRow('Branch', account.branchName));
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: columnChildren,
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
        Flexible(
          child: Text(
            label == 'Account Number'
                ? '**** **** **** ${value.substring(value.length - 4)}'
                : value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildEditAccountCard({
    required VoidCallback onSave,
    required VoidCallback onCancel,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Form(
        child: Column(
          children: [
            _buildTextField(
              context,
              controller: _formKeys[0],
              label: 'Bank Name',
              icon: Icons.account_balance,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              context,
              controller: _formKeys[1],
              label: 'Account Holder Name',
              icon: Icons.person,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              context,
              controller: _formKeys[2],
              label: 'Account Number',
              icon: Icons.numbers,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              context,
              controller: _formKeys[3],
              label: 'IFSC Code',
              icon: Icons.code,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              context,
              controller: _formKeys[4],
              label: 'Branch Name (Optional)',
              icon: Icons.location_city,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: onCancel,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6D00),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    BuildContext context, {
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFFFF6D00)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFFF6D00)),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
    );
  }
}
