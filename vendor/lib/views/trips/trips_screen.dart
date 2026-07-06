import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/theme_viewmodel.dart';
import '../dashboard/dashboard_screen.dart';

class TripsScreen extends StatefulWidget {
  const TripsScreen({super.key});

  @override
  State<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends State<TripsScreen> {
  String _activeTab = 'All Drivers';
  final TextEditingController _searchController = TextEditingController();
  final List<String> _tabs = ['All Drivers', 'Active', 'Pending Approval', 'Deactivated'];

  List<Map<String, dynamic>> drivers = [
    {'name': 'Rajesh Kumar', 'id': 'DR001', 'rating': 4.9, 'phone': '+91 98765 43210', 'city': 'Mumbai', 'trips': 234, 'earnings': 12450, 'status': 'Active'},
    {'name': 'Amit Singh', 'id': 'DR002', 'rating': 4.8, 'phone': '+91 98765 43211', 'city': 'Mumbai', 'trips': 198, 'earnings': 10230, 'status': 'Active'},
    {'name': 'Mohammed Ali', 'id': 'DR003', 'rating': 4.7, 'phone': '+91 98765 43212', 'city': 'Mumbai', 'trips': 187, 'earnings': 9870, 'status': 'Active'},
    {'name': 'Suresh Patel', 'id': 'DR004', 'rating': 4.6, 'phone': '+91 98765 43213', 'city': 'Mumbai', 'trips': 123, 'earnings': 6540, 'status': 'Pending Approval'},
    {'name': 'Vijay Sharma', 'id': 'DR005', 'rating': 4.5, 'phone': '+91 98765 43214', 'city': 'Mumbai', 'trips': 78, 'earnings': 4320, 'status': 'Deactivated'},
  ];

  List<Map<String, dynamic>> _filteredDrivers() {
    String query = _searchController.text.toLowerCase();
    return drivers.where((driver) {
      bool matchesTab = _activeTab == 'All Drivers' || driver['status'] == _activeTab;
      bool matchesSearch = query.isEmpty ||
          driver['name'].toString().toLowerCase().contains(query) ||
          driver['phone'].toString().toLowerCase().contains(query) ||
          driver['city'].toString().toLowerCase().contains(query);
      return matchesTab && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final themeVM = context.watch<ThemeViewModel>();
    final isDark = themeVM.isDarkMode;
    final filteredDrivers = _filteredDrivers();

    int totalDrivers = drivers.length;
    int activeDrivers = drivers.where((d) => d['status'] == 'Active').length;
    int pendingDrivers = drivers.where((d) => d['status'] == 'Pending Approval').length;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF0F4FF),
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
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      isDark ? const Color(0xFF0D1B2A) : const Color(0xFF1D2951),
                      isDark ? const Color(0xFF1B263B) : const Color(0xFF2D4A6D),
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
                          MaterialPageRoute(builder: (_) => const DashboardScreen()),
                          (route) => false,
                        );
                      },
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 26),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Driver Management',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Manage your driver network and approvals',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),

              // Stats Cards
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    _buildStatCard(
                      title: 'Total Drivers',
                      value: totalDrivers.toString(),
                      icon: Icons.people_outline,
                      color: const Color(0xFFFF7A00),
                      isDark: isDark,
                    ),
                    const SizedBox(height: 16),
                    _buildStatCard(
                      title: 'Active Drivers',
                      value: activeDrivers.toString(),
                      icon: Icons.people_outline,
                      color: const Color(0xFF10B981),
                      isDark: isDark,
                    ),
                    const SizedBox(height: 16),
                    _buildStatCard(
                      title: 'Pending Approval',
                      value: pendingDrivers.toString(),
                      icon: Icons.people_outline,
                      color: const Color(0xFFF59E0B),
                      isDark: isDark,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.search,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (value) {
                            setState(() {});
                          },
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search by name, phone, or city...',
                            hintStyle: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 16,
                            ),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Filter & Add Driver Buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.filter_alt_outlined),
                      label: const Text('Filter'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.add),
                        label: const Text('Add Driver'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF7A00),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Driver Status Tabs
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _tabs.map((tab) {
                      final isSelected = _activeTab == tab;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _activeTab = tab;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected ? (isDark ? const Color(0xFFFF7A00) : const Color(0xFFFF7A00)) : (isDark ? Colors.grey[800] : Colors.grey[200]),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Text(
                              tab,
                              style: TextStyle(
                                color: isSelected ? Colors.white : (isDark ? Colors.grey[300] : Colors.grey[800]),
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Driver Cards Grid
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.70,
                  ),
                  itemCount: filteredDrivers.length,
                  itemBuilder: (context, index) {
                    final driver = filteredDrivers[index];
                    return _buildDriverCard(driver, isDark);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[500],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverCard(Map<String, dynamic> driver, bool isDark) {
    Color statusColor;
    Color bgColor;
    switch (driver['status']) {
      case 'Active':
        statusColor = const Color(0xFF10B981);
        bgColor = const Color(0xFFE0F7E9);
        break;
      case 'Pending Approval':
        statusColor = const Color(0xFFF59E0B);
        bgColor = const Color(0xFFFFF3E0);
        break;
      case 'Deactivated':
        statusColor = Colors.red;
        bgColor = const Color(0xFFFFEBEE);
        break;
      default:
        statusColor = Colors.grey;
        bgColor = Colors.grey[100]!;
    }

    return Container(
      padding: const EdgeInsets.all(12),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top Row with Avatar, Name, Menu
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  const CircleAvatar(
                    radius: 24,
                    backgroundImage: NetworkImage(
                      'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&auto=format&fit=crop&q=60',
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      driver['name'],
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF1F2937),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      driver['id'],
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, color: Color(0xFFFFC107), size: 12),
                        const SizedBox(width: 3),
                        Text(
                          driver['rating'].toString(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF1F2937),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 24,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {},
                  icon: const Icon(Icons.more_vert_outlined, size: 16),
                  color: isDark ? Colors.grey[400] : Colors.grey[500],
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Contact Info
          Row(
            children: [
              Icon(Icons.phone_outlined, size: 14, color: isDark ? Colors.grey[400] : Colors.grey[600]),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  driver['phone'],
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.grey[300] : const Color(0xFF475569),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.location_on_outlined, size: 14, color: isDark ? Colors.grey[400] : Colors.grey[600]),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  driver['city'],
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.grey[300] : const Color(0xFF475569),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Divider(
            color: isDark ? Colors.grey[700] : Colors.grey[200],
            height: 1,
          ),

          const SizedBox(height: 8),

          // Trips & Earnings
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Trips',
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    driver['trips'].toString(),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF1F2937),
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Earnings',
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '₹${driver['earnings'].toString()}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFF7A00),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 6),

          // Status Chip
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? statusColor.withValues(alpha: 0.2) : bgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                driver['status'],
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
