import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../models/vendor_models.dart';

class VendorsScreen extends StatefulWidget {
  const VendorsScreen({super.key});

  @override
  State<VendorsScreen> createState() => _VendorsScreenState();
}

class _VendorsScreenState extends State<VendorsScreen> {
  List<Vendor> _vendors = [];
  bool _isLoading = true;
  bool _showAddVendor = false;
  bool _isDeleting = false;
  String _searchQuery = '';
  String _selectedFilter = 'all'; // all, pending, approved, declined
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchVendors();
  }

  Future<void> _fetchVendors() async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final Map<String, dynamic> queryParams = {};
      if (_searchQuery.isNotEmpty) {
        queryParams['search'] = _searchQuery;
      }
      if (_selectedFilter != 'all') {
        queryParams['status'] = _selectedFilter;
      }
      final response = await apiService.get(
        '/vendor/all',
        queryParameters: queryParams,
      );
      if (response.data['success'] == true) {
        final List<dynamic> vendorsData = response.data['vendors'];
        setState(() {
          _vendors = vendorsData.map((json) => Vendor.fromJson(json)).toList();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load vendors: $e')));
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _approveVendor(String vendorId) async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final response = await apiService.put('/vendor/$vendorId/approve');
      if (response.data['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Vendor approved successfully!')),
          );
        }
        await _fetchVendors();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to approve vendor: $e')));
      }
    }
  }

  Future<void> _declineVendor(String vendorId) async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final response = await apiService.put('/vendor/$vendorId/decline');
      if (response.data['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Vendor declined.')));
        }
        await _fetchVendors();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to decline vendor: $e')));
      }
    }
  }

  Future<void> _deleteVendor(Vendor vendor) async {
    // First, we need to know if this vendor has assigned drivers
    // For now, we'll show the first confirmation dialog
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Delete Vendor?'),
        content: const Text(
          'Are you sure you want to permanently delete this vendor? This action cannot be undone.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Show second confirmation if needed (we'll assume we might have assigned drivers, but for now just proceed)
    setState(() {
      _isDeleting = true;
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final response = await apiService.delete('/vendor/${vendor.id}');

      if (response.data['success'] == true) {
        if (mounted) {
          // Remove the vendor from the list immediately without full refresh
          setState(() {
            _vendors.removeWhere((v) => v.id == vendor.id);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Vendor deleted successfully')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: const Text('Unable to Delete Vendor'),
            content: const Text(
              'Something went wrong while deleting the vendor. Please try again.',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  Future<void> _addVendor() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final response = await apiService.post(
        '/vendor/register',
        data: {
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'phone': _phoneController.text.trim(),
          'password': _passwordController.text.trim(),
          'companyName': _companyNameController.text.trim(),
        },
      );

      if (response.data['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Vendor added successfully!')),
          );
        }
        _clearForm();
        setState(() {
          _showAddVendor = false;
        });
        await _fetchVendors();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to add vendor: $e')));
      }
    }
  }

  void _clearForm() {
    _nameController.clear();
    _emailController.clear();
    _phoneController.clear();
    _passwordController.clear();
    _companyNameController.clear();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _companyNameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        title: const Text('Vendor Management'),
        backgroundColor: const Color(0xFF1D2951),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_showAddVendor ? Icons.close : Icons.add),
            onPressed: () {
              setState(() {
                _showAddVendor = !_showAddVendor;
                if (!_showAddVendor) {
                  _clearForm();
                }
              });
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Add Vendor Form
              if (_showAddVendor) ...[
                Container(
                  width: double.infinity,
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
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Add New Vendor',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            hintText: 'Full Name',
                            prefixIcon: const Icon(Icons.person),
                            filled: true,
                            fillColor: const Color(0xFFF3F4F6),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 18,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            hintText: 'Email',
                            prefixIcon: const Icon(Icons.email),
                            filled: true,
                            fillColor: const Color(0xFFF3F4F6),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 18,
                            ),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter email';
                            }
                            if (!value.contains('@')) {
                              return 'Please enter valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _phoneController,
                          decoration: InputDecoration(
                            hintText: 'Phone Number',
                            prefixIcon: const Icon(Icons.phone),
                            filled: true,
                            fillColor: const Color(0xFFF3F4F6),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 18,
                            ),
                          ),
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter phone number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _companyNameController,
                          decoration: InputDecoration(
                            hintText: 'Company Name',
                            prefixIcon: const Icon(Icons.business),
                            filled: true,
                            fillColor: const Color(0xFFF3F4F6),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 18,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter company name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            hintText: 'Password',
                            prefixIcon: const Icon(Icons.lock),
                            filled: true,
                            fillColor: const Color(0xFFF3F4F6),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 18,
                            ),
                          ),
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter password';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _addVendor,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Add Vendor',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Search and Filters
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search vendors...',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: const Color(0xFFF3F4F6),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value.trim();
                        });
                        _fetchVendors();
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('All'),
                      selected: _selectedFilter == 'all',
                      onSelected: (selected) {
                        setState(() {
                          _selectedFilter = 'all';
                        });
                        _fetchVendors();
                      },
                      selectedColor: AppTheme.primaryColor,
                      checkmarkColor: Colors.white,
                      labelStyle: TextStyle(
                        color: _selectedFilter == 'all'
                            ? Colors.white
                            : Colors.black,
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Pending'),
                      selected: _selectedFilter == 'pending',
                      onSelected: (selected) {
                        setState(() {
                          _selectedFilter = 'pending';
                        });
                        _fetchVendors();
                      },
                      selectedColor: Colors.orange,
                      checkmarkColor: Colors.white,
                      labelStyle: TextStyle(
                        color: _selectedFilter == 'pending'
                            ? Colors.white
                            : Colors.black,
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Approved'),
                      selected: _selectedFilter == 'approved',
                      onSelected: (selected) {
                        setState(() {
                          _selectedFilter = 'approved';
                        });
                        _fetchVendors();
                      },
                      selectedColor: Colors.green,
                      checkmarkColor: Colors.white,
                      labelStyle: TextStyle(
                        color: _selectedFilter == 'approved'
                            ? Colors.white
                            : Colors.black,
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Declined'),
                      selected: _selectedFilter == 'declined',
                      onSelected: (selected) {
                        setState(() {
                          _selectedFilter = 'declined';
                        });
                        _fetchVendors();
                      },
                      selectedColor: Colors.red,
                      checkmarkColor: Colors.white,
                      labelStyle: TextStyle(
                        color: _selectedFilter == 'declined'
                            ? Colors.white
                            : Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Vendors List
              if (_isLoading) ...[
                const Center(child: CircularProgressIndicator()),
              ] else ...[
                Text(
                  '${_vendors.length} Vendors',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 16),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _vendors.length,
                  itemBuilder: (context, index) {
                    final vendor = _vendors[index];
                    Color statusColor;
                    String statusText;
                    if (vendor.approvalStatus == 'approved') {
                      statusColor = Colors.green[100]!;
                      statusText = 'Approved';
                    } else if (vendor.approvalStatus == 'declined') {
                      statusColor = Colors.red[100]!;
                      statusText = 'Declined';
                    } else {
                      statusColor = Colors.orange[100]!;
                      statusText = 'Pending';
                    }
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          // Avatar
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: statusColor,
                            ),
                            child: Icon(
                              Icons.person,
                              size: 28,
                              color: vendor.approvalStatus == 'approved'
                                  ? Colors.green[700]
                                  : vendor.approvalStatus == 'declined'
                                  ? Colors.red[700]
                                  : Colors.orange[700],
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Vendor Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  vendor.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1F2937),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  vendor.email,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  vendor.companyName,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Status
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              statusText,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: vendor.approvalStatus == 'approved'
                                    ? Colors.green[700]
                                    : vendor.approvalStatus == 'declined'
                                    ? Colors.red[700]
                                    : Colors.orange[700],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Actions
                          if (vendor.approvalStatus == 'pending') ...[
                            IconButton(
                              icon: const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                              ),
                              onPressed: () => _approveVendor(vendor.id),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.cancel,
                                color: Colors.redAccent,
                              ),
                              onPressed: () => _declineVendor(vendor.id),
                            ),
                          ],
                          // Delete button
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: _isDeleting
                                ? null
                                : () => _deleteVendor(vendor),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
