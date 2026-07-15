import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/dashboard_viewmodel.dart';
import '../../viewmodels/driver_viewmodel.dart';
import '../../viewmodels/vehicle_viewmodel.dart';
import '../../viewmodels/trip_viewmodel.dart';
import '../../viewmodels/earning_viewmodel.dart';
import '../../viewmodels/theme_viewmodel.dart';
import '../../services/profile_service.dart';
import '../../core/theme/app_theme.dart';
import '../drivers/drivers_screen.dart';
import '../earnings/earnings_screen.dart';
import '../notifications/notifications_screen.dart';
import '../profile/profile_screen.dart';
import '../settings/settings_screen.dart';
import '../fleet/fleet_screen.dart';
import '../bookings/bookings_screen.dart';
import '../wallet/wallet_screen.dart';
import '../documents/documents_screen.dart';
import '../cab_performance/cab_performance_screen.dart';
import '../track_cab/track_cab_screen.dart';
import '../vendors/vendors_screen.dart';
import '../auth/login_screen.dart';

// Global key to access the scaffold from DashboardHome
final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

// Enhanced Menu Item with hover and active effects
class _EnhancedMenuItem extends StatefulWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isActive;

  const _EnhancedMenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.isActive = false,
  });

  @override
  State<_EnhancedMenuItem> createState() => _EnhancedMenuItemState();
}

class _EnhancedMenuItemState extends State<_EnhancedMenuItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: InkWell(
        onTap: widget.onTap,
        onHover: (hovering) {
          setState(() {
            _isHovered = hovering;
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: widget.isActive
                ? const Color(0xFF1D2951)
                : _isHovered
                ? const Color(0xFF1D2951).withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            boxShadow: widget.isActive
                ? [
                    BoxShadow(
                      color: const Color(0xFF1D2951).withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Row(
            children: [
              Icon(
                widget.icon,
                color: widget.isActive
                    ? Colors.white
                    : _isHovered
                    ? const Color(0xFF1D2951)
                    : const Color(0xFF64748B),
                size: 22,
              ),
              const SizedBox(width: 16),
              Text(
                widget.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: widget.isActive
                      ? FontWeight.bold
                      : _isHovered
                      ? FontWeight.w600
                      : FontWeight.w500,
                  color: widget.isActive
                      ? Colors.white
                      : _isHovered
                      ? const Color(0xFF1D2951)
                      : const Color(0xFF1F2937),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  String _activeDrawerItem = 'Dashboard';
  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    // Initialize screens ONCE
    _screens = [
      DashboardHome(scaffoldKey: _scaffoldKey),
      const DriversScreen(),
      const EarningsScreen(),
      TrackCabScreen(
        onBackPressed: () {
          setState(() {
            _currentIndex = 0;
          });
        },
      ),
      const FleetScreen(),
    ];

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Fetch data ONCE at app start
      final dashboardVM = context.read<DashboardViewModel>();
      if (dashboardVM.stats == null) {
        dashboardVM.fetchDashboardStats();
      }

      final driverVM = context.read<DriverViewModel>();
      if (driverVM.drivers.isEmpty) {
        driverVM.fetchDrivers();
      }

      final vehicleVM = context.read<VehicleViewModel>();
      if (vehicleVM.vehicles.isEmpty) {
        vehicleVM.fetchVehicles();
      }

      final tripVM = context.read<TripViewModel>();
      if (tripVM.trips.isEmpty) {
        tripVM.fetchTrips();
      }

      final earningVM = context.read<EarningViewModel>();
      if (earningVM.earnings == null) {
        earningVM.fetchEarnings();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeVM = context.watch<ThemeViewModel>();
    final isDark = themeVM.isDarkMode;
    return Scaffold(
      key: _scaffoldKey,
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFF7A00), Color(0xFFFF8A3A)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Consumer<ProfileService>(
                        builder: (context, profileService, child) {
                          final imageProvider = profileService
                              .getImageProvider();
                          return CircleAvatar(
                            radius: 25,
                            backgroundImage:
                                imageProvider ??
                                const NetworkImage(
                                  'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150&auto=format&fit=crop&q=60',
                                ),
                            child: imageProvider == null
                                ? const Icon(Icons.person, size: 28)
                                : null,
                          );
                        },
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Consumer<ProfileService>(
                              builder: (context, profileService, child) {
                                return FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    profileService.userName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              },
                            ),
                            const Text(
                              'Vendor Portal',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            _EnhancedMenuItem(
              icon: Icons.dashboard_outlined,
              title: 'Dashboard',
              isActive: _activeDrawerItem == 'Dashboard',
              onTap: () {
                setState(() {
                  _currentIndex = 0;
                  _activeDrawerItem = 'Dashboard';
                });
                Navigator.pop(context);
              },
            ),
            _EnhancedMenuItem(
              icon: Icons.local_taxi_outlined,
              title: 'Fleet Management',
              isActive: _activeDrawerItem == 'Fleet Management',
              onTap: () {
                setState(() {
                  _activeDrawerItem = 'Fleet Management';
                });
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FleetScreen()),
                );
              },
            ),
            _EnhancedMenuItem(
              icon: Icons.admin_panel_settings_outlined,
              title: 'Vendors',
              isActive: _activeDrawerItem == 'Vendors',
              onTap: () {
                setState(() {
                  _activeDrawerItem = 'Vendors';
                });
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const VendorsScreen()),
                );
              },
            ),
            _EnhancedMenuItem(
              icon: Icons.people_outline,
              title: 'Drivers',
              isActive: _activeDrawerItem == 'Drivers',
              onTap: () {
                setState(() {
                  _currentIndex = 1;
                  _activeDrawerItem = 'Drivers';
                });
                Navigator.pop(context);
              },
            ),
            _EnhancedMenuItem(
              icon: Icons.calendar_today_outlined,
              title: 'Bookings',
              isActive: _activeDrawerItem == 'Bookings',
              onTap: () {
                setState(() {
                  _activeDrawerItem = 'Bookings';
                });
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BookingsScreen()),
                );
              },
            ),
            _EnhancedMenuItem(
              icon: Icons.attach_money_outlined,
              title: 'Revenue',
              isActive: _activeDrawerItem == 'Revenue',
              onTap: () {
                setState(() {
                  _currentIndex = 2;
                  _activeDrawerItem = 'Revenue';
                });
                Navigator.pop(context);
              },
            ),
            _EnhancedMenuItem(
              icon: Icons.payment_outlined,
              title: 'Payments',
              isActive: _activeDrawerItem == 'Payments',
              onTap: () {
                setState(() {
                  _activeDrawerItem = 'Payments';
                });
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const WalletScreen()),
                );
              },
            ),
            _EnhancedMenuItem(
              icon: Icons.description_outlined,
              title: 'Documents',
              isActive: _activeDrawerItem == 'Documents',
              onTap: () {
                setState(() {
                  _activeDrawerItem = 'Documents';
                });
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DocumentsScreen()),
                );
              },
            ),
            _EnhancedMenuItem(
              icon: Icons.notifications_outlined,
              title: 'Notifications',
              isActive: _activeDrawerItem == 'Notifications',
              onTap: () {
                setState(() {
                  _activeDrawerItem = 'Notifications';
                });
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const NotificationsScreen(),
                  ),
                );
              },
            ),
            _EnhancedMenuItem(
              icon: Icons.bar_chart_outlined,
              title: 'Cab Performance',
              isActive: _activeDrawerItem == 'Cab Performance',
              onTap: () {
                setState(() {
                  _activeDrawerItem = 'Cab Performance';
                });
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CabPerformanceScreen(),
                  ),
                );
              },
            ),
            _EnhancedMenuItem(
              icon: Icons.settings_outlined,
              title: 'Settings',
              isActive: _activeDrawerItem == 'Settings',
              onTap: () {
                setState(() {
                  _activeDrawerItem = 'Settings';
                });
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Divider(),
            ),
            _EnhancedMenuItem(
              icon: Icons.person_outline,
              title: 'Profile',
              isActive: _activeDrawerItem == 'Profile',
              onTap: () {
                setState(() {
                  _activeDrawerItem = 'Profile';
                });
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              },
            ),
            _EnhancedMenuItem(
              icon: Icons.logout_outlined,
              title: 'Logout',
              isActive: _activeDrawerItem == 'Logout',
              onTap: () async {
                Navigator.pop(context);
                await context.read<AuthViewModel>().logout();
                if (mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
            ),
          ],
        ),
      ),
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: Colors.grey[500],
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Drivers'),
          BottomNavigationBarItem(
            icon: Icon(Icons.attach_money),
            label: 'Earnings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on_outlined),
            label: 'Track',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_car_outlined),
            label: 'Fleet',
          ),
        ],
      ),
    );
  }
}

class DashboardHome extends StatefulWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;

  const DashboardHome({super.key, required this.scaffoldKey});

  @override
  State<DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<DashboardHome> {
  bool _showCharts = true;

  @override
  Widget build(BuildContext context) {
    final dashboardVM = context.watch<DashboardViewModel>();
    final themeVM = context.watch<ThemeViewModel>();
    final isDark = themeVM.isDarkMode;

    return Container(
      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF0F4FF),
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section (Gradient) - Same as Payment Management
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
                    // Top Bar
                    Row(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        // Hamburger Menu Button
                        IconButton(
                          onPressed: () {
                            widget.scaffoldKey.currentState?.openDrawer();
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(
                            Icons.menu_outlined,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Consumer<ProfileService>(
                          builder: (context, profileService, child) {
                            final imageProvider = profileService
                                .getImageProvider();
                            return CircleAvatar(
                              radius: 22,
                              backgroundImage:
                                  imageProvider ??
                                  const NetworkImage(
                                    'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150&auto=format&fit=crop&q=60',
                                  ),
                              child: imageProvider == null
                                  ? const Icon(Icons.person, size: 24)
                                  : null,
                            );
                          },
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Welcome back,',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                              ),
                              Consumer<ProfileService>(
                                builder: (context, profileService, child) {
                                  return FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      profileService.userName,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Dark Mode Toggle
                        IconButton(
                          onPressed: () {
                            themeVM.toggleTheme();
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: Icon(
                            isDark
                                ? Icons.light_mode_outlined
                                : Icons.dark_mode_outlined,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Stack(
                          children: [
                            IconButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const NotificationsScreen(),
                                  ),
                                );
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: const Icon(
                                Icons.notifications_outlined,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 12,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ProfileScreen(),
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.person_outline,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Dashboard',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Track your fleet and earnings',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Stats Cards - Same as Payment Management (overlapping style)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildNewStatCard(
                        title: 'Active Cabs',
                        value: '0',
                        icon: Icons.directions_car_outlined,
                        bgColor: const Color(0xFFFFECD2),
                        iconColor: const Color(0xFFFF7A00),
                        isDark: isDark,
                      ),
                      const SizedBox(width: 16),
                      _buildNewStatCard(
                        title: 'Inactive Cabs',
                        value: '0',
                        icon: Icons.car_repair_outlined,
                        bgColor: const Color(0xFFFFF3E0),
                        iconColor: const Color(0xFFF59E0B),
                        isDark: isDark,
                      ),
                      const SizedBox(width: 16),
                      _buildNewStatCard(
                        title: 'Booked Cabs',
                        value:
                            (dashboardVM.stats?.recentTrips
                                        .where(
                                          (t) => ![
                                            'completed',
                                            'cancelled',
                                            'canceled',
                                          ].contains(t.status.toLowerCase()),
                                        )
                                        .length ??
                                    0)
                                .toString(),
                        icon: Icons.local_taxi_outlined,
                        bgColor: const Color(0xFFE0F7E9),
                        iconColor: const Color(0xFF10B981),
                        isDark: isDark,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const BookingsScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 16),
                      _buildNewStatCard(
                        title: 'Total Drivers',
                        value: context
                            .watch<DriverViewModel>()
                            .drivers
                            .length
                            .toString(),
                        icon: Icons.people_outlined,
                        bgColor: const Color(0xFFDBEAFE),
                        iconColor: const Color(0xFF3B82F6),
                        isDark: isDark,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const DriversScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Today's Revenue Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  width: double.infinity,
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
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Today's Revenue",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF1F2937),
                            ),
                          ),
                          Text(
                            '26 May',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark
                                  ? Colors.grey[400]
                                  : Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '₹ 0.00',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF1F2937),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF2D2D2D)
                                  : Colors.green[50],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Net Earnings: ₹0.00',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.green[300]
                                    : Colors.green[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildSmallStat(
                              label: 'Cash',
                              value: '₹0.00',
                              color: const Color(0xFFFF7A00),
                              isDark: isDark,
                            ),
                          ),
                          Expanded(
                            child: _buildSmallStat(
                              label: 'Online Payments',
                              value: '₹0.00',
                              color: const Color(0xFFFF7A00),
                              isDark: isDark,
                            ),
                          ),
                          Expanded(
                            child: _buildSmallStat(
                              label: 'Discount',
                              value: '₹0.00',
                              color: isDark
                                  ? Colors.grey[400]!
                                  : const Color(0xFF6B7280),
                              isDark: isDark,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Show Charts Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _showCharts = !_showCharts;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF7A00),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _showCharts
                            ? Icons.hide_source
                            : Icons.bar_chart_outlined,
                      ),
                      const SizedBox(width: 8),
                      Text(_showCharts ? 'Hide Charts' : 'Show Charts'),
                    ],
                  ),
                ),
              ),

              if (_showCharts) ...[
                const SizedBox(height: 16),
                // Today's Revenue Analytics Chart
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildChartCard(
                    title: "Today's Revenue Analytics",
                    subtitle: "Hourly revenue breakdown",
                    isDark: isDark,
                    child: Container(
                      height: 200,
                      padding: const EdgeInsets.only(top: 16),
                      child: LineChart(
                        LineChartData(
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            getDrawingHorizontalLine: (value) {
                              return FlLine(
                                color: isDark
                                    ? Colors.grey[700]
                                    : Colors.grey[200],
                                strokeWidth: 1,
                              );
                            },
                          ),
                          titlesData: FlTitlesData(
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 30,
                                getTitlesWidget: (value, meta) {
                                  const hours = [
                                    '6AM',
                                    '9AM',
                                    '12PM',
                                    '3PM',
                                    '6PM',
                                    '9PM',
                                  ];
                                  if (value.toInt() >= 0 &&
                                      value.toInt() < hours.length) {
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text(
                                        hours[value.toInt()],
                                        style: TextStyle(
                                          color: isDark
                                              ? Colors.grey[400]
                                              : Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                    );
                                  }
                                  return const Text('');
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 40,
                                getTitlesWidget: (value, meta) {
                                  return Text(
                                    '₹${value.toInt()}',
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.grey[400]
                                          : Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  );
                                },
                              ),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          borderData: FlBorderData(
                            show: true,
                            border: Border(
                              bottom: BorderSide(
                                color: isDark
                                    ? Colors.grey[600]!
                                    : Colors.grey[300]!,
                                width: 1,
                              ),
                              left: BorderSide(
                                color: isDark
                                    ? Colors.grey[600]!
                                    : Colors.grey[300]!,
                                width: 1,
                              ),
                            ),
                          ),
                          lineBarsData: [
                            LineChartBarData(
                              spots: const [
                                FlSpot(0, 0),
                                FlSpot(1, 500),
                                FlSpot(2, 1200),
                                FlSpot(3, 800),
                                FlSpot(4, 1500),
                                FlSpot(5, 1000),
                              ],
                              isCurved: true,
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFFFF7A00),
                                  const Color(0xFFFFA726),
                                ],
                              ),
                              barWidth: 4,
                              dotData: FlDotData(
                                show: true,
                                getDotPainter: (spot, percent, barData, index) {
                                  return FlDotCirclePainter(
                                    radius: 5,
                                    color: const Color(0xFFFF7A00),
                                    strokeWidth: 2,
                                    strokeColor: Colors.white,
                                  );
                                },
                              ),
                              belowBarData: BarAreaData(
                                show: true,
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(
                                      0xFFFF7A00,
                                    ).withValues(alpha: 0.4),
                                    const Color(
                                      0xFFFF7A00,
                                    ).withValues(alpha: 0.1),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                // Weekly Revenue Chart
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildChartCard(
                    title: "Weekly Revenue",
                    subtitle: "Revenue vs target comparison",
                    isDark: isDark,
                    child: Container(
                      height: 200,
                      padding: const EdgeInsets.only(top: 16),
                      child: BarChart(
                        BarChartData(
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            getDrawingHorizontalLine: (value) {
                              return FlLine(
                                color: isDark
                                    ? Colors.grey[700]
                                    : Colors.grey[200],
                                strokeWidth: 1,
                              );
                            },
                          ),
                          titlesData: FlTitlesData(
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 30,
                                getTitlesWidget: (value, meta) {
                                  const days = [
                                    'Mon',
                                    'Tue',
                                    'Wed',
                                    'Thu',
                                    'Fri',
                                    'Sat',
                                    'Sun',
                                  ];
                                  if (value.toInt() >= 0 &&
                                      value.toInt() < days.length) {
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text(
                                        days[value.toInt()],
                                        style: TextStyle(
                                          color: isDark
                                              ? Colors.grey[400]
                                              : Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                    );
                                  }
                                  return const Text('');
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 40,
                                getTitlesWidget: (value, meta) {
                                  return Text(
                                    '₹${value.toInt()}',
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.grey[400]
                                          : Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  );
                                },
                              ),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          borderData: FlBorderData(
                            show: true,
                            border: Border(
                              bottom: BorderSide(
                                color: isDark
                                    ? Colors.grey[600]!
                                    : Colors.grey[300]!,
                                width: 1,
                              ),
                              left: BorderSide(
                                color: isDark
                                    ? Colors.grey[600]!
                                    : Colors.grey[300]!,
                                width: 1,
                              ),
                            ),
                          ),
                          barGroups: [
                            BarChartGroupData(
                              x: 0,
                              barRods: [
                                BarChartRodData(
                                  toY: 2500,
                                  color: const Color(0xFFFF7A00),
                                ),
                              ],
                            ),
                            BarChartGroupData(
                              x: 1,
                              barRods: [
                                BarChartRodData(
                                  toY: 3200,
                                  color: const Color(0xFFFFA726),
                                ),
                              ],
                            ),
                            BarChartGroupData(
                              x: 2,
                              barRods: [
                                BarChartRodData(
                                  toY: 2800,
                                  color: const Color(0xFFFF7043),
                                ),
                              ],
                            ),
                            BarChartGroupData(
                              x: 3,
                              barRods: [
                                BarChartRodData(
                                  toY: 4500,
                                  color: const Color(0xFFFF5722),
                                ),
                              ],
                            ),
                            BarChartGroupData(
                              x: 4,
                              barRods: [
                                BarChartRodData(
                                  toY: 3800,
                                  color: const Color(0x00e91e63),
                                ),
                              ],
                            ),
                            BarChartGroupData(
                              x: 5,
                              barRods: [
                                BarChartRodData(
                                  toY: 5200,
                                  color: const Color(0x009c27b0),
                                ),
                              ],
                            ),
                            BarChartGroupData(
                              x: 6,
                              barRods: [
                                BarChartRodData(
                                  toY: 3500,
                                  color: const Color(0xFF06B6D4),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                // Driver Login Hours Chart
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildChartCard(
                    title: "Driver Login Hours",
                    subtitle: "Average daily login hours this week",
                    isDark: isDark,
                    child: Container(
                      height: 200,
                      padding: const EdgeInsets.only(top: 16),
                      child: BarChart(
                        BarChartData(
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            getDrawingHorizontalLine: (value) {
                              return FlLine(
                                color: isDark
                                    ? Colors.grey[700]
                                    : Colors.grey[200],
                                strokeWidth: 1,
                              );
                            },
                          ),
                          titlesData: FlTitlesData(
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 30,
                                getTitlesWidget: (value, meta) {
                                  const days = [
                                    'Mon',
                                    'Tue',
                                    'Wed',
                                    'Thu',
                                    'Fri',
                                    'Sat',
                                    'Sun',
                                  ];
                                  if (value.toInt() >= 0 &&
                                      value.toInt() < days.length) {
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text(
                                        days[value.toInt()],
                                        style: TextStyle(
                                          color: isDark
                                              ? Colors.grey[400]
                                              : Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                    );
                                  }
                                  return const Text('');
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 40,
                                getTitlesWidget: (value, meta) {
                                  return Text(
                                    '${value.toInt()}h',
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.grey[400]
                                          : Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  );
                                },
                              ),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          borderData: FlBorderData(
                            show: true,
                            border: Border(
                              bottom: BorderSide(
                                color: isDark
                                    ? Colors.grey[600]!
                                    : Colors.grey[300]!,
                                width: 1,
                              ),
                              left: BorderSide(
                                color: isDark
                                    ? Colors.grey[600]!
                                    : Colors.grey[300]!,
                                width: 1,
                              ),
                            ),
                          ),
                          barGroups: [
                            BarChartGroupData(
                              x: 0,
                              barRods: [
                                BarChartRodData(
                                  toY: 8,
                                  color: const Color(0xFF3B82F6),
                                ),
                              ],
                            ),
                            BarChartGroupData(
                              x: 1,
                              barRods: [
                                BarChartRodData(
                                  toY: 10,
                                  color: const Color(0xFF10B981),
                                ),
                              ],
                            ),
                            BarChartGroupData(
                              x: 2,
                              barRods: [
                                BarChartRodData(
                                  toY: 7,
                                  color: const Color(0xFFF59E0B),
                                ),
                              ],
                            ),
                            BarChartGroupData(
                              x: 3,
                              barRods: [
                                BarChartRodData(
                                  toY: 12,
                                  color: const Color(0xFFFF7A00),
                                ),
                              ],
                            ),
                            BarChartGroupData(
                              x: 4,
                              barRods: [
                                BarChartRodData(
                                  toY: 9,
                                  color: const Color(0xFF8B5CF6),
                                ),
                              ],
                            ),
                            BarChartGroupData(
                              x: 5,
                              barRods: [
                                BarChartRodData(
                                  toY: 11,
                                  color: const Color(0xFFEC4899),
                                ),
                              ],
                            ),
                            BarChartGroupData(
                              x: 6,
                              barRods: [
                                BarChartRodData(
                                  toY: 8,
                                  color: const Color(0xFF06B6D4),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Cab Performance
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  width: double.infinity,
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
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Cab Performance',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF1F2937),
                            ),
                          ),
                          Text(
                            '26 May',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark
                                  ? Colors.grey[400]
                                  : Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFFFF7A00,
                              ).withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.directions_car_outlined,
                              color: Color(0xFFFF7A00),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'TN 58 CX 4321',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF1F2937),
                                  ),
                                ),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.star,
                                      color: Color(0xFFFFC107),
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '4.86',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: isDark
                                            ? Colors.grey[400]
                                            : Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Rides: 0',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: isDark
                                            ? Colors.grey[400]
                                            : Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFFFF7A00,
                              ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              '₹ 0',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFFF7A00),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Divider(
                        color: isDark ? Colors.grey[700] : Colors.grey[200],
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {},
                        child: const Text(
                          'View all',
                          style: TextStyle(
                            color: Color(0xFFFF7A00),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Driver Performance
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  width: double.infinity,
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
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Driver Performance',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF1F2937),
                            ),
                          ),
                          TextButton(
                            onPressed: () {},
                            child: const Text(
                              'View all',
                              style: TextStyle(
                                color: Color(0xFFFF7A00),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${DateTime.now().day} ${_getMonthName(DateTime.now().month)}',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.grey[400] : Colors.grey[500],
                        ),
                      ),
                      const SizedBox(height: 16),

                      Consumer<DriverViewModel>(
                        builder: (context, driverVM, child) {
                          if (driverVM.isLoading) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          if (driverVM.errorMessage != null) {
                            return Text('Error: ${driverVM.errorMessage}');
                          }
                          if (driverVM.drivers.isEmpty) {
                            return const Text('No drivers yet');
                          }

                          // Take top 2 drivers (or all if less than 2)
                          final topDrivers = driverVM.drivers.take(2).toList();

                          return Column(
                            children: topDrivers.asMap().entries.map((entry) {
                              final index = entry.key;
                              final driver = entry.value;
                              return Column(
                                children: [
                                  _buildDriverCard(
                                    name: driver.name,
                                    rating: driver.rating.toStringAsFixed(2),
                                    rides: (driver.todayTrips ?? 0).toString(),
                                    earnings:
                                        '₹ ${(driver.todayEarnings ?? 0).toStringAsFixed(0)}',
                                    profilePic:
                                        driver.profilePicture ??
                                        'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100&auto=format&fit=crop&q=60',
                                    isDark: isDark,
                                  ),
                                  if (index != topDrivers.length - 1)
                                    const SizedBox(height: 12),
                                ],
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNewStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color bgColor,
    required Color iconColor,
    required bool isDark,
    VoidCallback? onTap,
  }) {
    final Widget child = Container(
      width: 170,
      padding: const EdgeInsets.all(16),
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
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? iconColor.withValues(alpha: 0.2) : bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF1F2937),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: child,
      );
    }
    return child;
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
    required bool isDark,
  }) {
    return Container(
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
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 28, color: color),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallStat({
    required String label,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.grey[400] : Colors.grey[500],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildChartCard({
    required String title,
    required String subtitle,
    required Widget child,
    required bool isDark,
  }) {
    return Container(
      width: double.infinity,
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
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[400] : Colors.grey[500],
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  Widget _buildDriverCard({
    required String name,
    required String rating,
    required String rides,
    required String earnings,
    required String profilePic,
    required bool isDark,
  }) {
    return Row(
      children: [
        CircleAvatar(radius: 28, backgroundImage: NetworkImage(profilePic)),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.star, color: Color(0xFFFFC107), size: 16),
                  const SizedBox(width: 4),
                  Text(
                    rating,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '$rides rides',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              earnings,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFF7A00),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
