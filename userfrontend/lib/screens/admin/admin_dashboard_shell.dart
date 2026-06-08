import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'admin_stats_screen.dart';
import 'admin_rides_screen.dart';
import 'admin_payments_screen.dart';
import 'admin_settings_screen.dart';
import '../../providers/auth_provider.dart';
import '../../providers/admin_provider.dart';

class AdminDashboardShell extends StatefulWidget {
  const AdminDashboardShell({super.key});

  @override
  State<AdminDashboardShell> createState() => _AdminDashboardShellState();
}

class _AdminDashboardShellState extends State<AdminDashboardShell> {
  int _selectedIndex = 0;

  final List<String> _titles = [
    'Dashboard',
    'Ride History',
    'Payments',
    'Settings',
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // Trigger data fetch for the selected screen
    final provider = context.read<AdminProvider>();
    if (index == 0) {
      provider.fetchStats();
    } else if (index == 1) {
      provider.fetchRides();
    } else if (index == 2) {
      provider.fetchPayments();
    } else if (index == 3) {
      provider.fetchSettings();
    }
  }

  @override
  void initState() {
    super.initState();
    // Initial fetch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().fetchStats();
    });
  }

  Widget _getScreen(int index) {
    switch (index) {
      case 0:
        return const AdminStatsScreen();
      case 1:
        return const AdminRidesScreen();
      case 2:
        return const AdminPaymentsScreen();
      case 3:
        return const AdminSettingsScreen();
      default:
        return const AdminStatsScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final bool isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              authProvider.logout();
              Navigator.of(context).pushReplacementNamed('/login');
            },
          ),
        ],
      ),
      drawer: isDesktop ? null : _buildDrawer(),
      body: Row(
        children: [
          if (isDesktop) _buildNavigationRail(),
          Expanded(child: _getScreen(_selectedIndex)),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.red),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.admin_panel_settings,
                        color: Colors.red, size: 40),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Admin Panel',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          _buildDrawerItem(0, 'Dashboard', Icons.dashboard),
          _buildDrawerItem(1, 'Ride History', Icons.history),
          _buildDrawerItem(2, 'Payments', Icons.payment),
          _buildDrawerItem(3, 'Settings', Icons.settings),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(int index, String title, IconData icon) {
    return ListTile(
      leading:
          Icon(icon, color: _selectedIndex == index ? Colors.red : Colors.grey),
      title: Text(
        title,
        style: TextStyle(
          color: _selectedIndex == index ? Colors.red : Colors.black87,
          fontWeight:
              _selectedIndex == index ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: _selectedIndex == index,
      onTap: () {
        _onItemTapped(index);
        Navigator.pop(context);
      },
    );
  }

  Widget _buildNavigationRail() {
    return NavigationRail(
      selectedIndex: _selectedIndex,
      onDestinationSelected: _onItemTapped,
      labelType: NavigationRailLabelType.all,
      selectedIconTheme: const IconThemeData(color: Colors.red),
      selectedLabelTextStyle:
          const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard),
          label: Text('Stats'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.history_outlined),
          selectedIcon: Icon(Icons.history),
          label: Text('Rides'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.payment_outlined),
          selectedIcon: Icon(Icons.payment),
          label: Text('Payments'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings),
          label: Text('Settings'),
        ),
      ],
    );
  }
}
