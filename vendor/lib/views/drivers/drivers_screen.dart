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
  String _selectedStatus = 'All';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _statuses = [
    'All',
    'Active',
    'Pending Approval',
    'Deactivated',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Driver> _filterDrivers(List<Driver> drivers) {
    var filtered = drivers;

    if (_selectedStatus != 'All') {
      filtered = filtered.where((driver) {
        final approved = driver.isApproved == true;
        if (_selectedStatus == 'Active') {
          return approved &&
              (driver.status.toLowerCase() == 'online' ||
                  driver.status.toLowerCase() == 'active');
        } else if (_selectedStatus == 'Pending Approval') {
          return !approved;
        } else if (_selectedStatus == 'Deactivated') {
          return approved &&
              (driver.status.toLowerCase() == 'offline' ||
                  driver.status.toLowerCase() == 'inactive' ||
                  driver.status.toLowerCase() == 'deactivated');
        }
        return true;
      }).toList();
    }

    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered = filtered.where((driver) {
        return driver.name.toLowerCase().contains(query) ||
            driver.id.toLowerCase().contains(query) ||
            driver.phone.toLowerCase().contains(query);
      }).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final driverVM = context.watch<DriverViewModel>();

    if (driverVM.isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF0F4FF),
        body: SafeArea(child: Center(child: CircularProgressIndicator())),
      );
    }

    if (driverVM.errorMessage != null) {
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

    final filteredDrivers = _filterDrivers(driverVM.drivers);
    final activeDrivers = driverVM.drivers
        .where(
          (d) =>
              (d.isApproved == true) &&
              (d.status.toLowerCase() == 'online' ||
                  d.status.toLowerCase() == 'active'),
        )
        .length;
    final pendingDrivers = driverVM.drivers
        .where((d) => d.isApproved != true)
        .length;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
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
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
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
                        value: driverVM.drivers.length.toString(),
                        icon: Icons.people_outlined,
                        iconColor: const Color(0xFFFF7A00),
                        bgColor: const Color(0xFFFFECD2),
                      ),
                      const SizedBox(width: 16),
                      _buildStatCard(
                        title: 'Active Drivers',
                        value: activeDrivers.toString(),
                        icon: Icons.people_outlined,
                        iconColor: const Color(0xFF22C55E),
                        bgColor: const Color(0xFFE0F7E9),
                      ),
                      const SizedBox(width: 16),
                      _buildStatCard(
                        title: 'Pending Approval',
                        value: pendingDrivers.toString(),
                        icon: Icons.people_outlined,
                        iconColor: const Color(0xFFFF7A00),
                        bgColor: const Color(0xFFFFECD2),
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
                                  onChanged: (_) => setState(() {}),
                                  style: const TextStyle(
                                    color: Color(0xFF1F2937),
                                  ),
                                  decoration: const InputDecoration(
                                    hintText: 'Search...',
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
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFFE0E7FF),
                                ),
                              ),
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.filter_alt_outlined,
                                    color: Color(0xFF1F2937),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Filter',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1F2937),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            GestureDetector(
                              onTap: () => _showAddDriverDialog(context),
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
                          children: _statuses.map((status) {
                            final isSelected = _selectedStatus == status;
                            return Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedStatus = status;
                                  });
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.easeInOut,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFF1D2951)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(24),
                                    border: isSelected
                                        ? null
                                        : Border.all(
                                            color: const Color(0xFFE0E7FF),
                                          ),
                                  ),
                                  child: Text(
                                    status,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.w600,
                                      color: isSelected
                                          ? Colors.white
                                          : const Color(0xFF1F2937),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
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
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.person_outline,
                                size: 80,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No drivers yet',
                                style: TextStyle(fontSize: 18),
                              ),
                            ],
                          ),
                        ),
                      )
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          // Determine cross axis count based on screen width
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

  void _showAddDriverDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final mobileCtrl = TextEditingController();
    final licenseCtrl = TextEditingController();
    final vehicleNumberCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    String selectedVehicleType = 'Car';
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.all(24),
              child: Container(
                width: 560,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 30,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Dialog Header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF1D2951), Color(0xFF2D4A6D)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(28),
                          topRight: Radius.circular(28),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Add New Driver',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Fill in the details to register a driver',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            icon: const Icon(Icons.close, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    // Form Body
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
                                controller: nameCtrl,
                                label: 'Full Name',
                                icon: Icons.person_outline,
                                validator: (v) => (v == null || v.isEmpty)
                                    ? 'Name is required'
                                    : null,
                              ),
                              const SizedBox(height: 14),
                              _buildFormField(
                                controller: emailCtrl,
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
                                controller: mobileCtrl,
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
                                controller: licenseCtrl,
                                label: 'License Number',
                                icon: Icons.badge_outlined,
                                validator: (v) => (v == null || v.isEmpty)
                                    ? 'License number is required'
                                    : null,
                              ),
                              const SizedBox(height: 14),
                              _buildFormField(
                                controller: vehicleNumberCtrl,
                                label: 'Vehicle Number (optional)',
                                icon: Icons.directions_car_outlined,
                              ),
                              const SizedBox(height: 14),
                              // Vehicle Type Dropdown
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFF),
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
                                    labelStyle: TextStyle(
                                      color: Color(0xFF64748B),
                                    ),
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
                                controller: addressCtrl,
                                label: 'Address (optional)',
                                icon: Icons.location_on_outlined,
                                maxLines: 2,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Action Buttons
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () =>
                                  Navigator.of(dialogContext).pop(),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                side: const BorderSide(
                                  color: Color(0xFFE0E7FF),
                                ),
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
                                          'name': nameCtrl.text.trim(),
                                          'email': emailCtrl.text.trim(),
                                          'mobile': mobileCtrl.text.trim(),
                                          'licenseNumber': licenseCtrl.text
                                              .trim(),
                                          'vehicleNumber': vehicleNumberCtrl
                                              .text
                                              .trim(),
                                          'vehicleType': selectedVehicleType,
                                          'address': addressCtrl.text.trim(),
                                        });
                                        if (success && dialogContext.mounted) {
                                          Navigator.of(dialogContext).pop();
                                          ScaffoldMessenger.of(
                                            dialogContext,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Driver added successfully!',
                                              ),
                                              backgroundColor: Color(
                                                0xFF22C55E,
                                              ),
                                            ),
                                          );
                                        } else if (!success && ctx.mounted) {
                                          ScaffoldMessenger.of(
                                            ctx,
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
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
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
            );
          },
        );
      },
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
        fillColor: const Color(0xFFF8FAFF),
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
        borderRadius: BorderRadius.circular(28),
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
                    color: Color(0xFF1F2937),
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
    final bool approved = driver.isApproved == true;

    Color statusColor;
    String statusText;
    Color statusBgColor;

    if (!approved) {
      statusColor = const Color(0xFFFF7A00);
      statusText = 'Pending Approval';
      statusBgColor = const Color(0xFFFFECD2);
    } else {
      switch (driver.status.toLowerCase()) {
        case 'online':
        case 'active':
          statusColor = const Color(0xFF22C55E);
          statusText = 'Active';
          statusBgColor = const Color(0xFFE0F7E9);
          break;
        case 'pending':
          statusColor = const Color(0xFFFF7A00);
          statusText = 'Pending';
          statusBgColor = const Color(0xFFFFECD2);
          break;
        default:
          statusColor = const Color(0xFF64748B);
          statusText = 'Inactive';
          statusBgColor = const Color(0xFFF0F4FF);
      }
    }

    return Container(
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
                      backgroundImage:
                          (driver.profilePicture != null &&
                              driver.profilePicture!.isNotEmpty)
                          ? NetworkImage(driver.profilePicture!)
                                as ImageProvider
                          : const NetworkImage(
                              'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150&auto=format&fit=crop&q=60',
                            ),
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
                              color: Color(0xFF1F2937),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            driver.id,
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
                  if (value == 'approve') {
                    final success = await context
                        .read<DriverViewModel>()
                        .approveDriver(driver.id);
                    if (success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Driver approved successfully!'),
                        ),
                      );
                    }
                  } else if (value == 'decline') {
                    final success = await context
                        .read<DriverViewModel>()
                        .declineDriver(driver.id);
                    if (success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Driver declined/suspended!'),
                        ),
                      );
                    }
                  } else if (value == 'delete') {
                    final success = await context
                        .read<DriverViewModel>()
                        .deleteDriver(driver.id);
                    if (success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Driver deleted successfully!'),
                        ),
                      );
                    }
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: approved ? 'decline' : 'approve',
                    child: ListTile(
                      leading: Icon(
                        approved ? Icons.block : Icons.check_circle_outline,
                        color: approved ? Colors.red : Colors.green,
                      ),
                      title: Text(
                        approved ? 'Decline / Suspend' : 'Approve',
                        style: TextStyle(
                          color: approved ? Colors.red : Colors.green,
                        ),
                      ),
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                      leading: Icon(Icons.edit),
                      title: Text('Edit'),
                    ),
                  ),
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
                ],
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
          const Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                color: Color(0xFF64748B),
                size: 18,
              ),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Mumbai',
                  style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
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
                    driver.todayTrips.toString(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Earnings',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${driver.todayEarnings.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
              if (!approved)
                ElevatedButton(
                  onPressed: () async {
                    final success = await context
                        .read<DriverViewModel>()
                        .approveDriver(driver.id);
                    if (success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Driver approved successfully!'),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF22C55E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Approve',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
