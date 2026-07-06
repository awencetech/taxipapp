import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/theme_viewmodel.dart';
import '../../viewmodels/driver_viewmodel.dart';
import '../../viewmodels/vehicle_viewmodel.dart';
import '../../models/vendor_models.dart';
import '../../services/api_service.dart';
import '../dashboard/dashboard_screen.dart';

class FleetScreen extends StatefulWidget {
  const FleetScreen({super.key});

  @override
  State<FleetScreen> createState() => _FleetScreenState();
}

class _FleetScreenState extends State<FleetScreen> {
  String activeTab = 'Vehicles';
  String activeVehicleTab = 'All Vehicles';
  String activeDriverTab = 'All Drivers';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (activeTab == 'Vehicles') {
        context.read<VehicleViewModel>().setSearchQuery(_searchController.text);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DriverViewModel>().fetchDrivers();
      context.read<VehicleViewModel>().fetchVehicles();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddDriverDialog() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final licenseController = TextEditingController();
    final passwordController = TextEditingController();
    final vehicleTypeController = TextEditingController();
    final vehicleNumberController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Driver'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Phone'),
              ),
              TextField(
                controller: licenseController,
                decoration: const InputDecoration(labelText: 'License Number'),
              ),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              TextField(
                controller: vehicleTypeController,
                decoration: const InputDecoration(labelText: 'Vehicle Type'),
              ),
              TextField(
                controller: vehicleNumberController,
                decoration: const InputDecoration(labelText: 'Vehicle Number'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                final apiService = ApiService();
                await apiService.post(
                  '/vendor/drivers',
                  data: {
                    'name': nameController.text,
                    'email': emailController.text,
                    'mobile': phoneController.text,
                    'licenseNumber': licenseController.text,
                    'password': passwordController.text,
                    'vehicleType': vehicleTypeController.text,
                    'vehicleNumber': vehicleNumberController.text,
                  },
                );
                if (mounted) {
                  await context.read<DriverViewModel>().fetchDrivers();
                  Navigator.pop(context);
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString().replaceAll('Exception: ', '')),
                    ),
                  );
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showFilterBottomSheet() {
    final themeVM = context.read<ThemeViewModel>();
    final vehicleVM = context.read<VehicleViewModel>();
    String tempStatusFilter = vehicleVM.statusFilter;
    String tempVehicleTypeFilter = vehicleVM.vehicleTypeFilter;
    String tempDriverStatusFilter = vehicleVM.driverStatusFilter;
    String tempSortBy = vehicleVM.sortBy;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: themeVM.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(32),
              topRight: Radius.circular(32),
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Filter Vehicles',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Status Filter
              const Text(
                'Status',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ['All', 'Active', 'Inactive', 'Maintenance'].map((
                  status,
                ) {
                  final isSelected =
                      (status == 'All' && tempStatusFilter == 'all') ||
                      status.toLowerCase() == tempStatusFilter;
                  return ChoiceChip(
                    label: Text(status),
                    selected: isSelected,
                    onSelected: (selected) {
                      setModalState(() {
                        if (selected) {
                          tempStatusFilter = status == 'All'
                              ? 'all'
                              : status.toLowerCase();
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Vehicle Type Filter
              const Text(
                'Vehicle Type',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ['All', 'Bike', 'Auto', 'Mini', 'Sedan', 'SUV'].map((
                  type,
                ) {
                  final isSelected =
                      (type == 'All' && tempVehicleTypeFilter == 'all') ||
                      type.toLowerCase() == tempVehicleTypeFilter;
                  return ChoiceChip(
                    label: Text(type),
                    selected: isSelected,
                    onSelected: (selected) {
                      setModalState(() {
                        if (selected) {
                          tempVehicleTypeFilter = type == 'All'
                              ? 'all'
                              : type.toLowerCase();
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Driver Status Filter
              const Text(
                'Driver Status',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ['All', 'Online', 'Offline', 'On Trip'].map((status) {
                  String key;
                  switch (status) {
                    case 'On Trip':
                      key = 'on-trip';
                      break;
                    case 'All':
                      key = 'all';
                      break;
                    default:
                      key = status.toLowerCase();
                  }
                  final isSelected = tempDriverStatusFilter == key;
                  return ChoiceChip(
                    label: Text(status),
                    selected: isSelected,
                    onSelected: (selected) {
                      setModalState(() {
                        if (selected) {
                          tempDriverStatusFilter = key;
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Sort By
              const Text(
                'Sort By',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ['Newest', 'Oldest', 'Earnings', 'Trips'].map((sort) {
                  final isSelected = sort.toLowerCase() == tempSortBy;
                  return ChoiceChip(
                    label: Text(sort),
                    selected: isSelected,
                    onSelected: (selected) {
                      setModalState(() {
                        if (selected) {
                          tempSortBy = sort.toLowerCase();
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        vehicleVM.resetFilters();
                        Navigator.pop(context);
                      },
                      child: const Text('Reset'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        vehicleVM.setStatusFilter(tempStatusFilter);
                        vehicleVM.setVehicleTypeFilter(tempVehicleTypeFilter);
                        vehicleVM.setDriverStatusFilter(tempDriverStatusFilter);
                        vehicleVM.setSortBy(tempSortBy);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF7A00),
                      ),
                      child: const Text('Apply'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToAddVehicle() {
    // TODO: Implement Add Vehicle page navigation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add Vehicle page coming soon!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeVM = context.watch<ThemeViewModel>();
    final isDark = themeVM.isDarkMode;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F172A)
          : const Color(0xFFF0F4FF),
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
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      isDark
                          ? const Color(0xFF0D1B2A)
                          : const Color(0xFF1D2951),
                      isDark
                          ? const Color(0xFF1B263B)
                          : const Color(0xFF2D4A6D),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
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
                    const SizedBox(height: 8),
                    const Text(
                      'Fleet Management',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Manage your fleet',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Tabs (Drivers / Vehicles)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[800] : Colors.grey[200],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => activeTab = 'Drivers'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: activeTab == 'Drivers'
                                  ? (isDark ? Colors.grey[700] : Colors.white)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: activeTab == 'Drivers'
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.08,
                                        ),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : [],
                            ),
                            child: Center(
                              child: Text(
                                'Drivers',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: activeTab == 'Drivers'
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  color: activeTab == 'Drivers'
                                      ? (isDark ? Colors.white : Colors.black)
                                      : (isDark
                                            ? Colors.grey[400]
                                            : Colors.grey[600]),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => activeTab = 'Vehicles'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: activeTab == 'Vehicles'
                                  ? (isDark ? Colors.grey[700] : Colors.white)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: activeTab == 'Vehicles'
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.08,
                                        ),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : [],
                            ),
                            child: Center(
                              child: Text(
                                'Vehicles',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: activeTab == 'Vehicles'
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  color: activeTab == 'Vehicles'
                                      ? (isDark ? Colors.white : Colors.black)
                                      : (isDark
                                            ? Colors.grey[400]
                                            : Colors.grey[600]),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Search and Filter
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    // Search Box
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.search,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF1F2937),
                              ),
                              decoration: InputDecoration(
                                hintText: activeTab == 'Vehicles'
                                    ? 'Search by vehicle number, driver, etc.'
                                    : 'Search by driver name, phone, etc.',
                                hintStyle: TextStyle(
                                  color: isDark
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                                  fontSize: 14,
                                ),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Filter and Add
                    Row(
                      children: [
                        // Filter Button
                        OutlinedButton.icon(
                          onPressed: activeTab == 'Vehicles'
                              ? _showFilterBottomSheet
                              : null,
                          icon: const Icon(
                            Icons.filter_alt,
                            color: Color(0xFF6B7280),
                          ),
                          label: const Text(
                            'Filter',
                            style: TextStyle(
                              color: Color(0xFF6B7280),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            side: BorderSide(color: Colors.grey[300]!),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Add Button
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: activeTab == 'Vehicles'
                                ? _navigateToAddVehicle
                                : _showAddDriverDialog,
                            icon: const Icon(Icons.add, color: Colors.white),
                            label: Text(
                              activeTab == 'Vehicles'
                                  ? 'Add Vehicle'
                                  : 'Add Driver',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF7A00),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Status Tabs
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children:
                        (activeTab == 'Vehicles'
                                ? [
                                    'All Vehicles',
                                    'Active',
                                    'Inactive',
                                    'Maintenance',
                                  ]
                                : [
                                    'All Drivers',
                                    'Active',
                                    'Inactive',
                                    'Maintenance',
                                  ])
                            .map((tab) {
                              final isSelected = activeTab == 'Vehicles'
                                  ? activeVehicleTab == tab
                                  : activeDriverTab == tab;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      if (activeTab == 'Vehicles') {
                                        activeVehicleTab = tab;
                                        switch (tab) {
                                          case 'All Vehicles':
                                            context
                                                .read<VehicleViewModel>()
                                                .setStatusFilter('all');
                                            break;
                                          case 'Active':
                                            context
                                                .read<VehicleViewModel>()
                                                .setStatusFilter('active');
                                            break;
                                          case 'Inactive':
                                            context
                                                .read<VehicleViewModel>()
                                                .setStatusFilter('inactive');
                                            break;
                                          case 'Maintenance':
                                            context
                                                .read<VehicleViewModel>()
                                                .setStatusFilter('maintenance');
                                            break;
                                        }
                                      } else {
                                        activeDriverTab = tab;
                                      }
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(0xFFFF7A00)
                                          : (isDark
                                                ? const Color(0xFF1E1E1E)
                                                : Colors.white),
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    child: Text(
                                      tab,
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.white
                                            : (isDark
                                                  ? Colors.grey[400]
                                                  : Colors.grey[600]),
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.w500,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            })
                            .toList(),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // List
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: activeTab == 'Vehicles'
                    ? _buildVehicleList(
                        isDark,
                        context.watch<VehicleViewModel>(),
                        context.watch<DriverViewModel>(),
                      )
                    : _buildDriverList(
                        isDark,
                        context.watch<DriverViewModel>(),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDriverList(bool isDark, DriverViewModel driverVM) {
    if (driverVM.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (driverVM.drivers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Text(
            'No drivers found',
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ),
      );
    }

    List<Driver> filteredDrivers = driverVM.drivers;
    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      filteredDrivers = filteredDrivers.where((driver) {
        final matchesName = driver.name.toLowerCase().contains(query);
        final matchesPhone = driver.phone.toLowerCase().contains(query);
        final matchesDriverId =
            driver.driverId?.toLowerCase().contains(query) ?? false;
        return matchesName || matchesPhone || matchesDriverId;
      }).toList();
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filteredDrivers.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final driver = filteredDrivers[index];

        Color statusColor;
        String statusText;
        if (driver.isBusy == true) {
          statusColor = const Color(0xFF3B82F6);
          statusText = 'On Trip';
        } else if (driver.isOnline == true) {
          statusColor = const Color(0xFF22C55E);
          statusText = 'Active';
        } else {
          statusColor = Colors.grey;
          statusText = 'Inactive';
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
            ),
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
                          radius: 18,
                          backgroundImage:
                              (driver.profilePicture != null &&
                                  driver.profilePicture!.isNotEmpty)
                              ? NetworkImage(driver.profilePicture!)
                              : const NetworkImage(
                                  'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150&auto=format&fit=crop&q=60',
                                ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                driver.name,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 1),
                              if (driver.driverId != null)
                                Text(
                                  'Driver ID: ${driver.driverId}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFFFF7A00),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Phone',
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          driver.phone,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.grey[300] : Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'License',
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          driver.licenseNumber ?? 'N/A',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.grey[300] : Colors.grey[700],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Trips',
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          driver.totalRides.toString(),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rating',
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 1),
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: Color(0xFFFFC107),
                              size: 12,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              driver.rating.toStringAsFixed(1),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Vehicle',
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          driver.vehicleNumber ?? 'N/A',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFFFF7A00),
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVehicleList(
    bool isDark,
    VehicleViewModel vehicleVM,
    DriverViewModel driverVM,
  ) {
    if (vehicleVM.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (vehicleVM.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 80, color: Colors.red[400]),
              const SizedBox(height: 16),
              Text(
                'Error',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.grey[300] : Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                vehicleVM.errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (vehicleVM.vehicles.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.directions_car, size: 80, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No Vehicles Found',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.grey[300] : Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tap "Add Vehicle" to register your first fleet vehicle.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: vehicleVM.vehicles.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final vehicle = vehicleVM.vehicles[index];
        return _buildVehicleCard(vehicle, isDark);
      },
    );
  }

  Widget _buildVehicleCard(Vehicle vehicle, bool isDark) {
    Color vehicleStatusColor;
    String vehicleStatusText;
    switch (vehicle.status) {
      case 'inactive':
        vehicleStatusColor = Colors.grey;
        vehicleStatusText = 'Inactive';
        break;
      case 'maintenance':
        vehicleStatusColor = const Color(0xFFFF9800);
        vehicleStatusText = 'Maintenance';
        break;
      default:
        vehicleStatusColor = const Color(0xFF22C55E);
        vehicleStatusText = 'Active';
    }

    Color driverStatusColor;
    String driverStatusText;
    switch (vehicle.driverStatus) {
      case 'on-trip':
        driverStatusColor = const Color(0xFF3B82F6);
        driverStatusText = 'On Trip';
        break;
      case 'online':
        driverStatusColor = const Color(0xFF22C55E);
        driverStatusText = 'Online';
        break;
      case 'offline':
      default:
        driverStatusColor = Colors.grey;
        driverStatusText = 'Offline';
    }

    String getTimeAgo(DateTime time) {
      final now = DateTime.now();
      final difference = now.difference(time);

      if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top: Vehicle Info + Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      _getVehicleIcon(vehicle.type),
                      size: 40,
                      color: const Color(0xFFFF7A00),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            vehicle.number.toUpperCase(),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${vehicle.type.toUpperCase()} • ${vehicle.model}',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: vehicleStatusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  vehicleStatusText,
                  style: TextStyle(
                    color: vehicleStatusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Driver Info
          if (vehicle.driverName != null)
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage:
                      (vehicle.driverAvatar != null &&
                          vehicle.driverAvatar!.isNotEmpty)
                      ? NetworkImage(vehicle.driverAvatar!)
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
                        vehicle.driverName!,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.badge_outlined,
                            color: Color(0xFFFF7A00),
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            vehicle.driverId ?? 'N/A',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFFFF7A00),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        vehicle.driverPhone ?? '',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: driverStatusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    driverStatusText,
                    style: TextStyle(
                      color: driverStatusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 12),

          // Stats: Trips & Earnings
          Row(
            children: [
              // Trips
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.grey[800]!.withValues(alpha: 0.5)
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Today\'s Trips',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        vehicle.todayTrips.toString(),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3B82F6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Earnings
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.grey[800]!.withValues(alpha: 0.5)
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Today\'s Earnings',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${vehicle.todayEarnings.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFF7A00),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Last Ride
          if (vehicle.lastRide != null)
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 14,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  'Last Ride: ${getTimeAgo(vehicle.lastRide!)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  IconData _getVehicleIcon(String type) {
    switch (type.toLowerCase()) {
      case 'bike':
        return Icons.motorcycle_outlined;
      case 'auto':
        return Icons.directions_transit_outlined;
      case 'suv':
        return Icons.directions_car_filled_outlined;
      case 'mini':
      case 'sedan':
      default:
        return Icons.directions_car_outlined;
    }
  }
}
