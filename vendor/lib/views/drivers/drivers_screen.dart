import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/driver_viewmodel.dart';
import '../../models/vendor_models.dart';
import '../dashboard/dashboard_screen.dart';

class DriversScreen extends StatefulWidget {
  const DriversScreen({super.key});

  @override
  State<DriversScreen> createState() => _DriversScreenState();
}

class _DriversScreenState extends State<DriversScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DriverViewModel>().fetchDrivers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showDriverDetailsDialog(Driver driver) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          width: 600,
          constraints: const BoxConstraints(maxHeight: 700),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1D2951), Color(0xFF2D4A6D)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundImage: isNonEmpty(driver.profilePicture)
                          ? NetworkImage(driver.profilePicture!)
                          : null,
                      child: !isNonEmpty(driver.profilePicture)
                          ? Text(
                              driver.name.characters.first.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            driver.name,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          if (driver.driverId != null)
                            Text(
                              driver.driverId!,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailSection('Contact', [
                        _buildDetailItem('Phone', driver.phone),
                        _buildDetailItem('Email', driver.email),
                      ]),
                      const SizedBox(height: 20),
                      _buildDetailSection('Vehicle', [
                        _buildDetailItem(
                          'Vehicle Type',
                          driver.vehicleType ?? 'N/A',
                        ),
                        _buildDetailItem(
                          'Vehicle Number',
                          driver.vehicleNumber ?? 'N/A',
                        ),
                      ]),
                      const SizedBox(height: 20),
                      _buildDetailSection('Documents', [
                        _buildDetailItem(
                          'License Number',
                          driver.licenseNumber ?? 'Not provided',
                        ),
                        if (driver.aadhaarNumber != null)
                          _buildDetailItem(
                            'Aadhaar Number',
                            driver.aadhaarNumber!,
                          ),
                      ]),
                      const SizedBox(height: 20),
                      _buildDetailSection('Status', [
                        _buildDetailItem(
                          'Approval Status',
                          driver.isApproved == true
                              ? 'Approved'
                              : driver.status.toLowerCase() == 'rejected'
                              ? 'Rejected'
                              : 'Pending',
                        ),
                        _buildDetailItem(
                          'Account Status',
                          driver.accountStatus ?? driver.status,
                        ),
                        _buildDetailItem(
                          'Online Status',
                          driver.isOnline == true ? 'Online' : 'Offline',
                        ),
                      ]),
                      const SizedBox(height: 20),
                      _buildDetailSection('Stats', [
                        _buildDetailItem(
                          'Total Trips',
                          driver.totalRides.toString(),
                        ),
                        _buildDetailItem(
                          'Completed Trips',
                          driver.completedTrips.toString(),
                        ),
                        _buildDetailItem(
                          'Cancelled Trips',
                          driver.cancelledTrips.toString(),
                        ),
                        _buildDetailItem(
                          'Today\'s Trips',
                          driver.todayTrips.toString(),
                        ),
                        _buildDetailItem(
                          'Rating',
                          driver.rating.toStringAsFixed(1),
                        ),
                        _buildDetailItem(
                          'Total Earnings',
                          '₹${driver.totalEarnings?.toStringAsFixed(0) ?? '0'}',
                        ),
                        _buildDetailItem(
                          'Wallet Balance',
                          '₹${driver.walletBalance?.toStringAsFixed(0) ?? '0'}',
                        ),
                      ]),
                      const SizedBox(height: 20),
                      _buildDetailSection('Dates', [
                        _buildDetailItem(
                          'Registered On',
                          driver.createdAt.toLocal().toString().split(' ')[0],
                        ),
                        if (driver.approvedAt != null)
                          _buildDetailItem(
                            'Approved On',
                            driver.approvedAt!.toLocal().toString().split(
                              ' ',
                            )[0],
                          ),
                        if (driver.lastLogin != null)
                          _buildDetailItem(
                            'Last Login',
                            driver.lastLogin!.toLocal().toString().split(
                              ' ',
                            )[0],
                          ),
                      ]),
                      if (driver.rejectionReason != null) ...[
                        const SizedBox(height: 20),
                        _buildDetailSection('Rejection Reason', [
                          _buildDetailItem('', driver.rejectionReason!),
                        ]),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1D2951),
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  bool isNonEmpty(String? s) {
    return s != null && s.trim().isNotEmpty;
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label.isNotEmpty == true)
            SizedBox(
              width: 140,
              child: Text(
                '$label:',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Color(0xFF1D2951)),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddDriverDialog() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final licenseController = TextEditingController();
    final vehicleNumberController = TextEditingController();
    final addressController = TextEditingController();
    String selectedVehicleType = 'Car';
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          insetPadding: const EdgeInsets.all(20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            width: 500,
            constraints: const BoxConstraints(maxHeight: 700),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF1D2951), Color(0xFF2D4A6D)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Add New Driver',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Fill in the details to register a driver',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(dialogContext),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Personal Details',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1D2951),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildFormField(
                            controller: nameController,
                            label: 'Full Name',
                            icon: Icons.person_outline,
                            validator: (v) => (v == null || v.isEmpty)
                                ? 'Name is required'
                                : null,
                          ),
                          const SizedBox(height: 14),
                          _buildFormField(
                            controller: emailController,
                            label: 'Email Address',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Email is required';
                              }
                              if (!v.contains('@')) {
                                return 'Enter a valid email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          _buildFormField(
                            controller: phoneController,
                            label: 'Mobile Number',
                            icon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                            validator: (v) => (v == null || v.isEmpty)
                                ? 'Mobile is required'
                                : null,
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Vehicle & License',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1D2951),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildFormField(
                            controller: licenseController,
                            label: 'License Number',
                            icon: Icons.badge_outlined,
                            validator: (v) => (v == null || v.isEmpty)
                                ? 'License number is required'
                                : null,
                          ),
                          const SizedBox(height: 14),
                          _buildFormField(
                            controller: vehicleNumberController,
                            label: 'Vehicle Number (optional)',
                            icon: Icons.directions_car_outlined,
                          ),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0F4FF),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0xFFE0E7FF),
                              ),
                            ),
                            child: DropdownButtonFormField<String>(
                              initialValue: selectedVehicleType,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                icon: Icon(
                                  Icons.commute_outlined,
                                  color: Color(0xFF64748B),
                                ),
                                labelText: 'Vehicle Type',
                                labelStyle: TextStyle(color: Color(0xFF64748B)),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'Car',
                                  child: Text('Car'),
                                ),
                                DropdownMenuItem(
                                  value: 'Bike',
                                  child: Text('Bike'),
                                ),
                                DropdownMenuItem(
                                  value: 'Auto',
                                  child: Text('Auto'),
                                ),
                                DropdownMenuItem(
                                  value: 'Van',
                                  child: Text('Van'),
                                ),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setDialogState(
                                    () => selectedVehicleType = val,
                                  );
                                }
                              },
                            ),
                          ),
                          const SizedBox(height: 14),
                          _buildFormField(
                            controller: addressController,
                            label: 'Address (optional)',
                            icon: Icons.location_on_outlined,
                            maxLines: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: Color(0xFFE0E7FF)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        flex: 2,
                        child: Consumer<DriverViewModel>(
                          builder: (ctx, vm, _) => ElevatedButton(
                            onPressed: vm.isLoading
                                ? null
                                : () async {
                                    if (!formKey.currentState!.validate()) {
                                      return;
                                    }
                                    final success = await vm.addDriver({
                                      'name': nameController.text.trim(),
                                      'email': emailController.text.trim(),
                                      'mobile': phoneController.text.trim(),
                                      'licenseNumber': licenseController.text
                                          .trim(),
                                      'vehicleNumber': vehicleNumberController
                                          .text
                                          .trim(),
                                      'vehicleType': selectedVehicleType,
                                      'address': addressController.text.trim(),
                                    });
                                    if (success && context.mounted) {
                                      Navigator.pop(dialogContext);
                                      if (mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Driver added successfully!',
                                            ),
                                            backgroundColor: Color(0xFF22C55E),
                                          ),
                                        );
                                      }
                                    } else if (mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            vm.errorMessage ??
                                                'Failed to add driver',
                                          ),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF7A00),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                            ),
                            child: vm.isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Add Driver',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showRejectDialog(Driver driver) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reject Driver'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            hintText: 'Enter rejection reason',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final success = await context
                  .read<DriverViewModel>()
                  .rejectDriver(driver.id, reasonController.text.trim());
              if (success && mounted) {
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Driver rejected successfully'),
                    backgroundColor: Color(0xFF22C55E),
                  ),
                );
              }
            },
            child: const Text('Reject', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF64748B)),
        prefixIcon: Icon(icon, color: const Color(0xFF64748B)),
        filled: true,
        fillColor: const Color(0xFFF0F4FF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE0E7FF)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE0E7FF)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF1D2951), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
  }) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1D2951),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverCard(BuildContext context, Driver driver) {
    final approved = driver.isApproved == true;
    Color statusColor;
    String statusText;
    Color statusBgColor;

    if (!approved) {
      if (driver.status.toLowerCase() == 'rejected' ||
          driver.approvalStatus?.toLowerCase() == 'rejected' ||
          driver.accountStatus?.toLowerCase() == 'rejected') {
        statusColor = Colors.red;
        statusText = 'Rejected';
        statusBgColor = Colors.red.shade100;
      } else {
        statusColor = const Color(0xFFFF7A00);
        statusText = 'Pending Approval';
        statusBgColor = const Color(0xFFFFECD2);
      }
    } else if (driver.isBusy == true) {
      statusColor = Colors.orange;
      statusText = 'Busy';
      statusBgColor = Colors.orange.shade100;
    } else if (driver.isOnline == true) {
      statusColor = const Color(0xFF22C55E);
      statusText = 'Online';
      statusBgColor = const Color(0xFFE0F7E9);
    } else if (driver.accountStatus?.toLowerCase() == 'suspended' ||
        driver.status.toLowerCase() == 'suspended') {
      statusColor = Colors.black87;
      statusText = 'Suspended';
      statusBgColor = Colors.grey.shade200;
    } else {
      statusColor = const Color(0xFF64748B);
      statusText = 'Offline';
      statusBgColor = const Color(0xFFF0F4FF);
    }

    return GestureDetector(
      onTap: () => _showDriverDetailsDialog(driver),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: const Color(0xFFE0E7FF)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundImage: isNonEmpty(driver.profilePicture)
                            ? NetworkImage(driver.profilePicture!)
                            : null,
                        child: !isNonEmpty(driver.profilePicture)
                            ? Text(
                                driver.name.characters.first.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              driver.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1D2951),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (driver.driverId != null)
                              Text(
                                driver.driverId!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF64748B),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.star,
                                  color: Color(0xFFFFD700),
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  driver.rating.toStringAsFixed(1),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFFF7A00),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Color(0xFF64748B)),
                  onSelected: (value) async {
                    switch (value) {
                      case 'approve':
                        final success = await context
                            .read<DriverViewModel>()
                            .approveDriver(driver.id);
                        if (success && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Driver approved successfully!'),
                              backgroundColor: Color(0xFF22C55E),
                            ),
                          );
                        }
                        break;
                      case 'reject':
                        _showRejectDialog(driver);
                        break;
                      case 'suspend':
                        final success = await context
                            .read<DriverViewModel>()
                            .suspendDriver(driver.id);
                        if (success && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Driver suspended!'),
                              backgroundColor: Color(0xFF22C55E),
                            ),
                          );
                        }
                        break;
                      case 'activate':
                        final success = await context
                            .read<DriverViewModel>()
                            .activateDriver(driver.id);
                        if (success && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Driver activated!'),
                              backgroundColor: Color(0xFF22C55E),
                            ),
                          );
                        }
                        break;
                      case 'delete':
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Delete Driver'),
                            content: const Text(
                              'Are you sure you want to delete this driver?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text(
                                  'Delete',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true && mounted) {
                          final success = await context
                              .read<DriverViewModel>()
                              .deleteDriver(driver.id);
                          if (success && mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Driver deleted successfully!'),
                                backgroundColor: Color(0xFF22C55E),
                              ),
                            );
                          }
                        }
                        break;
                    }
                  },
                  itemBuilder: (context) {
                    final items = <PopupMenuEntry<String>>[];
                    if (!approved &&
                        driver.status.toLowerCase() != 'rejected' &&
                        driver.approvalStatus?.toLowerCase() != 'rejected' &&
                        driver.accountStatus?.toLowerCase() != 'rejected') {
                      items.addAll([
                        const PopupMenuItem(
                          value: 'approve',
                          child: ListTile(
                            leading: Icon(
                              Icons.check_circle_outline,
                              color: Colors.green,
                            ),
                            title: Text('Approve'),
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'reject',
                          child: ListTile(
                            leading: Icon(Icons.block, color: Colors.red),
                            title: Text(
                              'Reject',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ),
                      ]);
                    } else if (driver.accountStatus?.toLowerCase() ==
                            'suspended' ||
                        driver.status.toLowerCase() == 'suspended') {
                      items.add(
                        const PopupMenuItem(
                          value: 'activate',
                          child: ListTile(
                            leading: Icon(
                              Icons.check_circle_outline,
                              color: Colors.green,
                            ),
                            title: Text('Activate'),
                          ),
                        ),
                      );
                    } else if (approved) {
                      items.add(
                        const PopupMenuItem(
                          value: 'suspend',
                          child: ListTile(
                            leading: Icon(Icons.block, color: Colors.orange),
                            title: Text('Suspend'),
                          ),
                        ),
                      );
                    }
                    items.addAll([
                      const PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete, color: Colors.red),
                          title: Text(
                            'Delete',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ),
                    ]);
                    return items;
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.phone_outlined,
                  color: Color(0xFF64748B),
                  size: 18,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    driver.phone,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (driver.vehicleType != null)
              Row(
                children: [
                  const Icon(
                    Icons.directions_car_outlined,
                    color: Color(0xFF64748B),
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${driver.vehicleType} ${driver.vehicleNumber != null ? '• ${driver.vehicleNumber}' : ''}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF64748B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Trips',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      driver.totalRides.toString(),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1D2951),
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Today\'s Trips',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      driver.todayTrips.toString(),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1D2951),
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Today\'s Earnings',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹${driver.todayEarnings.toString()}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1D2951),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusBgColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
                if (!approved &&
                    driver.status.toLowerCase() != 'rejected' &&
                    driver.approvalStatus?.toLowerCase() != 'rejected' &&
                    driver.accountStatus?.toLowerCase() != 'rejected')
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: 32,
                        child: TextButton(
                          onPressed: () async {
                            final success = await context
                                .read<DriverViewModel>()
                                .approveDriver(driver.id);
                            if (success && mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Driver approved successfully!',
                                  ),
                                  backgroundColor: Color(0xFF22C55E),
                                ),
                              );
                            }
                          },
                          style: TextButton.styleFrom(
                            backgroundColor: const Color(0xFF22C55E),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Approve',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 32,
                        child: OutlinedButton(
                          onPressed: () => _showRejectDialog(driver),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Reject',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final driverVM = context.watch<DriverViewModel>();

    if (driverVM.isLoading && driverVM.drivers.isEmpty) {
      return const Scaffold(
        backgroundColor: Color(0xFFF0F4FF),
        body: SafeArea(child: Center(child: CircularProgressIndicator())),
      );
    }

    if (driverVM.errorMessage != null && driverVM.drivers.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFF0F4FF),
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 80, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  driverVM.errorMessage!,
                  style: const TextStyle(fontSize: 18),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => driverVM.fetchDrivers(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final filteredDrivers = driverVM.drivers;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1D2951), Color(0xFF2D4A6D)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(32),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const DashboardScreen(),
                          ),
                          (route) => false,
                        );
                      },
                      icon: const Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Driver Management',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Manage your driver network and approvals',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withValues(alpha: 0.95),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Stats Cards
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildStatCard(
                        title: 'Total Drivers',
                        value: driverVM.totalDriversCount.toString(),
                        icon: Icons.people_outlined,
                        iconColor: const Color(0xFFFF7A00),
                        bgColor: const Color(0xFFFFECD2),
                      ),
                      const SizedBox(width: 16),
                      _buildStatCard(
                        title: 'Approved',
                        value: driverVM.approvedDriversCount.toString(),
                        icon: Icons.check_circle_outline,
                        iconColor: const Color(0xFF22C55E),
                        bgColor: const Color(0xFFE0F7E9),
                      ),
                      const SizedBox(width: 16),
                      _buildStatCard(
                        title: 'Pending',
                        value: driverVM.pendingDriversCount.toString(),
                        icon: Icons.pending_outlined,
                        iconColor: const Color(0xFFFF7A00),
                        bgColor: const Color(0xFFFFECD2),
                      ),
                      const SizedBox(width: 16),
                      _buildStatCard(
                        title: 'Online',
                        value: driverVM.onlineDriversCount.toString(),
                        icon: Icons.online_prediction_outlined,
                        iconColor: const Color(0xFF22C55E),
                        bgColor: const Color(0xFFE0F7E9),
                      ),
                      const SizedBox(width: 16),
                      _buildStatCard(
                        title: 'Offline',
                        value: driverVM.offlineDriversCount.toString(),
                        icon: Icons.offline_bolt_outlined,
                        iconColor: const Color(0xFF64748B),
                        bgColor: const Color(0xFFF0F4FF),
                      ),
                      const SizedBox(width: 16),
                      _buildStatCard(
                        title: 'Busy',
                        value: driverVM.busyDriversCount.toString(),
                        icon: Icons.directions_car,
                        iconColor: Colors.orange,
                        bgColor: Colors.orange.shade100,
                      ),
                      const SizedBox(width: 16),
                      _buildStatCard(
                        title: 'Suspended',
                        value: driverVM.suspendedDriversCount.toString(),
                        icon: Icons.block,
                        iconColor: Colors.black87,
                        bgColor: Colors.grey.shade200,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Search & Filters
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
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
                    children: [
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            SizedBox(
                              width: 250,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0F4FF),
                                  borderRadius: BorderRadius.circular(32),
                                ),
                                child: TextField(
                                  controller: _searchController,
                                  onChanged: (value) {
                                    driverVM.setSearchQuery(value);
                                  },
                                  style: const TextStyle(
                                    color: Color(0xFF1D2951),
                                  ),
                                  decoration: const InputDecoration(
                                    hintText: 'Search drivers...',
                                    hintStyle: TextStyle(
                                      color: Color(0xFF64748B),
                                    ),
                                    border: InputBorder.none,
                                    icon: Icon(
                                      Icons.search,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            GestureDetector(
                              onTap: () => _showAddDriverDialog(),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFFF7A00),
                                      Color(0xFFFF8A3A),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.add, color: Colors.white),
                                    SizedBox(width: 8),
                                    Text(
                                      'Add Driver',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            // Status Filter
                            FilterChip(
                              label: Text(driverVM.selectedStatusFilter),
                              selected: driverVM.selectedStatusFilter != 'All',
                              onSelected: (_) => _showStatusFilterMenu(context),
                              backgroundColor: const Color(0xFFF0F4FF),
                              selectedColor: const Color(0xFF1D2951),
                              labelStyle: TextStyle(
                                color: driverVM.selectedStatusFilter != 'All'
                                    ? Colors.white
                                    : const Color(0xFF1D2951),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Vehicle Type Filter
                            if (driverVM.availableVehicleTypes.length > 1)
                              FilterChip(
                                label: Text(driverVM.selectedVehicleTypeFilter),
                                selected:
                                    driverVM.selectedVehicleTypeFilter != 'All',
                                onSelected: (_) =>
                                    _showVehicleTypeFilterMenu(context),
                                backgroundColor: const Color(0xFFF0F4FF),
                                selectedColor: const Color(0xFF1D2951),
                                labelStyle: TextStyle(
                                  color:
                                      driverVM.selectedVehicleTypeFilter !=
                                          'All'
                                      ? Colors.white
                                      : const Color(0xFF1D2951),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            const SizedBox(width: 8),

                            // Sort
                            FilterChip(
                              label: Text(
                                'Sort: ${_getSortLabel(driverVM.sortBy)}',
                              ),
                              selected: driverVM.sortBy != 'newest',
                              onSelected: (_) => _showSortMenu(context),
                              backgroundColor: const Color(0xFFF0F4FF),
                              selectedColor: const Color(0xFF1D2951),
                              labelStyle: TextStyle(
                                color: driverVM.sortBy != 'newest'
                                    ? Colors.white
                                    : const Color(0xFF1D2951),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Clear Filters
                            if (driverVM.selectedStatusFilter != 'All' ||
                                driverVM.selectedVehicleTypeFilter != 'All' ||
                                driverVM.searchQuery.isNotEmpty)
                              TextButton(
                                onPressed: () {
                                  driverVM.clearFilters();
                                  _searchController.clear();
                                },
                                child: const Text('Clear Filters'),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Driver List
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: filteredDrivers.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.person_outline,
                                size: 80,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                driverVM.searchQuery.isNotEmpty ||
                                        driverVM.selectedStatusFilter !=
                                            'All' ||
                                        driverVM.selectedVehicleTypeFilter !=
                                            'All'
                                    ? 'No drivers match your search/filters'
                                    : 'No drivers yet',
                                style: const TextStyle(fontSize: 18),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          int crossAxisCount = 3;
                          double childAspectRatio = 0.85;

                          if (constraints.maxWidth < 600) {
                            crossAxisCount = 1;
                            childAspectRatio = 0.9;
                          } else if (constraints.maxWidth < 900) {
                            crossAxisCount = 2;
                            childAspectRatio = 0.88;
                          }

                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  mainAxisSpacing: 16,
                                  crossAxisSpacing: 16,
                                  childAspectRatio: childAspectRatio,
                                ),
                            itemCount: filteredDrivers.length,
                            itemBuilder: (context, index) {
                              final driver = filteredDrivers[index];
                              return _buildDriverCard(context, driver);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getSortLabel(String sortBy) {
    switch (sortBy) {
      case 'newest':
        return 'Newest';
      case 'oldest':
        return 'Oldest';
      case 'highestRating':
        return 'Highest Rating';
      case 'mostTrips':
        return 'Most Trips';
      case 'highestEarnings':
        return 'Highest Earnings';
      case 'nameAsc':
        return 'Name A-Z';
      default:
        return 'Sort';
    }
  }

  void _showStatusFilterMenu(BuildContext context) {
    final driverVM = context.read<DriverViewModel>();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Filter by Status',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                shrinkWrap: true,
                children:
                    [
                      'All',
                      'Pending Approval',
                      'Approved',
                      'Rejected',
                      'Online',
                      'Offline',
                      'Busy',
                      'Suspended',
                    ].map((status) {
                      return ListTile(
                        title: Text(status),
                        trailing: driverVM.selectedStatusFilter == status
                            ? const Icon(Icons.check, color: Colors.green)
                            : null,
                        onTap: () {
                          driverVM.setStatusFilter(status);
                          Navigator.pop(ctx);
                        },
                      );
                    }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showVehicleTypeFilterMenu(BuildContext context) {
    final driverVM = context.read<DriverViewModel>();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Filter by Vehicle Type',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                shrinkWrap: true,
                children: driverVM.availableVehicleTypes.map((type) {
                  return ListTile(
                    title: Text(type),
                    trailing: driverVM.selectedVehicleTypeFilter == type
                        ? const Icon(Icons.check, color: Colors.green)
                        : null,
                    onTap: () {
                      driverVM.setVehicleTypeFilter(type);
                      Navigator.pop(ctx);
                    },
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSortMenu(BuildContext context) {
    final driverVM = context.read<DriverViewModel>();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Sort Drivers',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                shrinkWrap: true,
                children:
                    [
                      'newest',
                      'oldest',
                      'highestRating',
                      'mostTrips',
                      'highestEarnings',
                      'nameAsc',
                    ].map((sort) {
                      return ListTile(
                        title: Text(_getSortLabel(sort)),
                        trailing: driverVM.sortBy == sort
                            ? const Icon(Icons.check, color: Colors.green)
                            : null,
                        onTap: () {
                          driverVM.setSortBy(sort);
                          Navigator.pop(ctx);
                        },
                      );
                    }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
