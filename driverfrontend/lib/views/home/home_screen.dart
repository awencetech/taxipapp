import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/ride_viewmodel.dart';
import '../../providers/location_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/map_layers_control.dart';
import '../../widgets/ride_request_popup.dart';
import '../earnings/earnings_screen.dart';
import '../profile/profile_screen.dart';
import '../profile/bank_details_screen.dart';
import '../rides/rides_screen.dart';
import '../notifications/notifications_screen.dart';
import '../settings/settings_screen.dart';
import '../auth/login_screen.dart';
import '../wallet/wallet_screen.dart';
import '../incentives/incentives_screen.dart';
import '../support/support_screen.dart';
import './recent_activity_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static HomeScreenState? of(BuildContext context) =>
      context.findAncestorStateOfType<HomeScreenState>();

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  void setSelectedIndex(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  final List<Widget> _screens = [
    const HomeDashboard(),
    const RidesScreen(),
    const EarningsScreen(),
    const ProfileScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    debugPrint('HomeScreen: Building with selectedIndex=$_selectedIndex');
    try {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: _screens[_selectedIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppTheme.primaryColor,
          unselectedItemColor: Colors.grey,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.navigation_outlined),
              activeIcon: Icon(Icons.navigation),
              label: 'Rides',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet_outlined),
              activeIcon: Icon(Icons.account_balance_wallet),
              label: 'Earnings',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.menu),
              label: 'More',
            ),
          ],
        ),
      );
    } catch (e, stack) {
      debugPrint('HomeScreen: Build Error: $e');
      debugPrint('HomeScreen: Stack Trace: $stack');
      return Scaffold(
        body: Center(
          child: Text('Error rendering Home: $e'),
        ),
      );
    }
  }
}

class HomeDashboard extends StatefulWidget {
  const HomeDashboard({super.key});

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        final authViewModel = context.read<AuthViewModel>();
        if (authViewModel.driver != null) {
          context.read<RideViewModel>().initialize(authViewModel.driver!.id);
          context.read<RideViewModel>().fetchNotifications();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    try {
      final rideViewModel = context.watch<RideViewModel>();
      debugPrint('HomeDashboard: Building. isOnline=${rideViewModel.isOnline}');
      
      return rideViewModel.isOnline ? _buildOnlineUI() : _buildOfflineUI();
    } catch (e, stack) {
      debugPrint('HomeDashboard: Build Error: $e');
      debugPrint('HomeDashboard: Stack Trace: $stack');
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text('Dashboard Error: $e'),
        ),
      );
    }
  }

  Widget _buildOfflineUI() {
    final authViewModel = context.watch<AuthViewModel>();
    final rideViewModel = context.watch<RideViewModel>();
    final driver = authViewModel.driver;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Header with Gradient
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 60, left: 24, right: 24, bottom: 40),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2D2D2D), Color(0xFFE65100)],
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                        onPressed: () {
                          if (Navigator.canPop(context)) {
                            Navigator.pop(context);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      backgroundImage: (driver?.profilePic != null && driver!.profilePic!.isNotEmpty)
                          ? (driver.profilePic!.startsWith('http')
                              ? CachedNetworkImageProvider(driver.profilePic!)
                              : FileImage(File(driver.profilePic!)) as ImageProvider)
                          : null,
                      child: (driver?.profilePic == null || driver!.profilePic!.isEmpty)
                          ? const Icon(Icons.person, size: 35, color: Colors.grey)
                          : null,
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            driver?.name ?? 'Driver Name',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(Icons.star, color: Colors.yellow, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                '${driver?.rating ?? 4.8} • ${driver?.vehicleNumber ?? "KA 05 MX 1234"}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Stack(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.notifications_none, color: Colors.white),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                              );
                            },
                          ),
                          Positioned(
                            right: 12,
                            top: 12,
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
                    ),
                    const SizedBox(width: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.settings_outlined, color: Colors.white),
                        onPressed: () {
                          HomeScreen.of(context)?.setSelectedIndex(4); // Index for More (SettingsScreen)
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                // Online/Offline Switcher Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "You're Offline",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text(
                              "Go online to start earning",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: rideViewModel.isOnline,
                        onChanged: (value) => rideViewModel.toggleOnlineOffline(),
                        activeThumbColor: Colors.white,
                        activeTrackColor: Colors.green,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Earnings Summary Card
          Transform.translate(
            offset: const Offset(0, -30),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFFF8A00),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Today's Earnings",
                            style: TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                          Text(
                            "₹2850",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.attach_money, color: Colors.white, size: 30),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(color: Colors.white24),
                  const SizedBox(height: 20),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("This Week", style: TextStyle(color: Colors.white70, fontSize: 12)),
                          Text("₹15420", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("This Month", style: TextStyle(color: Colors.white70, fontSize: 12)),
                          Text("₹58900", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      HomeScreen.of(context)?.setSelectedIndex(2);
                    },
                    icon: const Icon(Icons.analytics_outlined, size: 18),
                    label: const Text("View Detailed Earnings"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 45),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),
          
          if (driver != null && driver.bankAccounts.isNotEmpty)
            // Show saved bank details
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => BankDetailsScreen()),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.teal[50]!,
                        Colors.teal[100]!,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.teal[200]!),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.teal[600],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.account_balance, color: Colors.white),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              driver.bankAccounts[0].bankName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              () {
                                final accNo = driver.bankAccounts[0].accountNumber;
                                if (accNo.length >= 4) {
                                  return '**** **** **** ${accNo.substring(accNo.length - 4)}';
                                }
                                return '';
                              }(),
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.edit, color: Colors.teal[600], size: 20),
                    ],
                  ),
                ),
              ),
            ),

          // Performance Metrics
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Performance Metrics",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
                ),
                const SizedBox(height: 16),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.5,
                  children: [
                    _buildMetricCard(
                      "127",
                      "Trips Completed",
                      Icons.directions_car_filled_outlined,
                      Colors.green.shade50,
                      Colors.green,
                    ),
                    _buildMetricCard(
                      "94%",
                      "Acceptance Rate",
                      Icons.track_changes,
                      Colors.blue.shade50,
                      Colors.blue,
                    ),
                    _buildMetricCard(
                      "8.5h",
                      "Online Hours",
                      Icons.access_time,
                      Colors.orange.shade50,
                      Colors.orange,
                    ),
                    _buildMetricCard(
                      "4.8",
                      "Driver Rating",
                      Icons.star_outline,
                      Colors.yellow.shade50,
                      Colors.orange,
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),
          // Quick Actions Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Quick Actions",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildQuickAction(
                      Icons.send, 
                      "Go Online", 
                      Colors.green,
                      onTap: () => rideViewModel.toggleOnlineOffline(),
                    ),
                    const SizedBox(width: 12),
                    _buildQuickAction(
                      Icons.account_balance_wallet, 
                      "Wallet", 
                      Colors.blue,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const WalletScreen()),
                        );
                      },
                    ),
                    const SizedBox(width: 12),
                    _buildQuickAction(
                      Icons.card_membership, 
                      "Incentives", 
                      Colors.purple,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const IncentivesScreen()),
                        );
                      },
                    ),
                    const SizedBox(width: 12),
                    _buildQuickAction(
                      Icons.support_agent, 
                      "Support", 
                      Colors.red,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SupportScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),
          // Recent Activity Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Recent Activity",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const RecentActivityScreen()),
                        );
                      },
                      child: const Text("View All", style: TextStyle(color: Color(0xFFFF6D00))),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildActivityItem(
                  "Priya Sharma",
                  "2 hours ago",
                  "MG Road → Koramangala",
                  "₹285",
                  "5",
                  Colors.amber,
                ),
                const SizedBox(height: 12),
                _buildActivityItem(
                  "Amit Patel",
                  "4 hours ago",
                  "HSR Layout → Electronic City",
                  "₹420",
                  "4",
                  Colors.orange,
                ),
              ],
            ),
          ),
          const SizedBox(height: 100), // Space for bottom bar
        ],
      ),
    );
  }

  Widget _buildOnlineUI() {
    final rideViewModel = context.watch<RideViewModel>();

    return Container(
      color: const Color(0xFFF8F9FA), // Light grey body background
      child: Column(
        children: [
          // Green Header Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 50, bottom: 40),
            decoration: const BoxDecoration(
              color: Color(0xFF2EBD59), // Solid green from image
            ),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned(
                        left: 20,
                        child: GestureDetector(
                          onTap: () {
                            if (rideViewModel.isOnline) {
                              rideViewModel.toggleOnlineOffline();
                            } else if (Navigator.canPop(context)) {
                              Navigator.pop(context);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
                          ),
                        ),
                      ),
                      Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Transform.rotate(
                            angle: -0.5, // Slight tilt like in navigation icons
                            child: const Icon(Icons.navigation, color: Colors.white, size: 55),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 20,
                        child: GestureDetector(
                          onTap: () {
                            rideViewModel.toggleOnlineOffline();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.power_settings_new, color: Colors.white, size: 16),
                                SizedBox(width: 6),
                                Text(
                                  "Go Offline",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "You're Online",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  "Waiting for ride requests...",
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 24),
                // Timer Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        rideViewModel.onlineDuration,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace', // Better for timers
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Background with subtle pattern or gradient if needed
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFFF8F9FA),
                          Colors.white.withValues(alpha: 0.5),
                          Colors.white,
                        ],
                      ),
                    ),
                  ),
                ),
                // Content under header
                Column(
                  children: [
                    const SizedBox(height: 100), // Space for the overlapping card
                    // Live Map View Pulse
                    Center(
                      child: Column(
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              // Pulsing effect
                              ...List.generate(3, (index) => 
                                Container(
                                  width: 80.0 + (index * 20),
                                  height: 80.0 + (index * 20),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2EBD59).withValues(alpha: 0.1 / (index + 1)),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                              Container(
                                width: 50,
                                height: 50,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF2EBD59),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Color(0x402EBD59),
                                      blurRadius: 15,
                                      spreadRadius: 8,
                                    )
                                  ],
                                ),
                                child: const Icon(Icons.my_location, color: Colors.white, size: 24),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            "Live Map View",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF444444),
                            ),
                          ),
                          const Text(
                            "Your current location",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    // Bottom Stats and Actions
                    Container(
                      padding: const EdgeInsets.only(left: 24, right: 24, top: 30, bottom: 40),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(35)),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x0A000000),
                            blurRadius: 20,
                            offset: Offset(0, -10),
                          )
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildOnlineStat("₹0", "Today's Earnings", const Color(0xFF2EBD59)),
                              _buildOnlineStat("0", "Trips", const Color(0xFF1A1A1A)),
                              _buildOnlineStat(rideViewModel.onlineDuration, "Online Time", const Color(0xFF1A1A1A)),
                            ],
                          ),
                          const SizedBox(height: 30),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: OutlinedButton(
                              onPressed: () => rideViewModel.toggleOnlineOffline(),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFFE53935), width: 1.5),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                elevation: 0,
                              ),
                              child: const Text(
                                "Go Offline",
                                style: TextStyle(
                                  color: Color(0xFFE53935), 
                                  fontSize: 18, 
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Earning Tip Card
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0F7FF),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.bolt, color: Color(0xFF2196F3), size: 20),
                                ),
                                const SizedBox(width: 15),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Earning Tip",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold, 
                                          fontSize: 15,
                                          color: Color(0xFF1A1A1A),
                                        ),
                                      ),
                                      Text(
                                        "Head to MG Road for higher demand and better earnings!",
                                        style: TextStyle(
                                          fontSize: 13, 
                                          color: Color(0xFF666666),
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Offline Shortcut
                          GestureDetector(
                            onTap: () => rideViewModel.toggleOnlineOffline(),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.power_settings_new, color: Colors.grey[400], size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    "SWITCH TO OFFLINE MODE",
                                    style: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                // High Demand Areas Overlapping Card
                Positioned(
                  top: -45,
                  left: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 25,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.trending_up, color: Color(0xFFFF8A00), size: 22),
                            SizedBox(width: 10),
                            Text(
                              "High Demand Areas",
                              style: TextStyle(
                                fontWeight: FontWeight.bold, 
                                fontSize: 17,
                                color: Color(0xFF1A1A1A),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            children: [
                              _buildDemandArea("MG Road", "2.3 km", const Color(0xFFE53935)),
                              const SizedBox(width: 14),
                              _buildDemandArea("Koramangala", "3.5 km", const Color(0xFFFFB300)),
                              const SizedBox(width: 14),
                              _buildDemandArea("Indiranagar", "4.1 km", const Color(0xFFE53935)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDemandArea(String name, String distance, Color statusColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3F5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: statusColor.withValues(alpha: 0.3),
                  blurRadius: 4,
                  spreadRadius: 1,
                )
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name, 
                style: const TextStyle(
                  fontWeight: FontWeight.bold, 
                  fontSize: 14,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                distance, 
                style: const TextStyle(
                  color: Color(0xFF757575), 
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOnlineStat(String value, String label, Color valueColor) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 26, 
            fontWeight: FontWeight.bold, 
            color: valueColor,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13, 
            color: Color(0xFF757575),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAction(IconData icon, String label, Color color, {VoidCallback? onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
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
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityItem(String name, String time, String route, String amount, String rating, Color avatarColor) {
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
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: avatarColor.withValues(alpha: 0.2),
            child: Icon(Icons.person, color: avatarColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Text(
                      amount,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      time,
                      style: TextStyle(color: Colors.grey[500], fontSize: 11),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 12),
                        Text(
                          " $rating",
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  route,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String value, String label, IconData icon, Color bgColor, Color iconColor) {
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
                ),
                Text(
                  label,
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MapView extends StatefulWidget {
  const MapView({super.key});

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  GoogleMapController? _mapController;
  MapLayerType _selectedMapLayer = MapLayerType.normal;
  bool _isTrafficEnabled = false;
  LatLng? _lastKnownPosition;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        context.read<LocationProvider>().getCurrentLocation();
        final authViewModel = context.read<AuthViewModel>();
        if (authViewModel.driver != null) {
          context.read<RideViewModel>().initialize(authViewModel.driver!.id);
          context.read<RideViewModel>().fetchNotifications();
        }
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locationProvider = context.watch<LocationProvider>();
    final currentPosition = locationProvider.currentPosition;

    if (currentPosition != null && _mapController != null) {
      final newLatLng = LatLng(
        currentPosition.latitude,
        currentPosition.longitude,
      );
      if (_lastKnownPosition == null ||
          _lastKnownPosition!.latitude != newLatLng.latitude ||
          _lastKnownPosition!.longitude != newLatLng.longitude) {
        _lastKnownPosition = newLatLng;
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(newLatLng, 16),
        );
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    final locationProvider = context.read<LocationProvider>();

    final coords = await locationProvider.getCurrentLocation();

    if (coords != null) {
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(coords, 16));
    } else if (locationProvider.error != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(locationProvider.error!),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Settings',
              textColor: Colors.white,
              onPressed: () {
                Geolocator.openLocationSettings();
              },
            ),
          ),
        );
        locationProvider.clearError();
      }
    }
  }

  MapType _getMapType() {
    switch (_selectedMapLayer) {
      case MapLayerType.satellite:
        return MapType.satellite;
      case MapLayerType.terrain:
        return MapType.terrain;
      case MapLayerType.hybrid:
        return MapType.hybrid;
      default:
        return MapType.normal;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();
    final rideViewModel = context.watch<RideViewModel>();
    final locationProvider = context.watch<LocationProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Taxi Nanban Driver"),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final navigator = Navigator.of(context);
              await authViewModel.logout();
              navigator.pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: locationProvider.currentPosition != null
                  ? LatLng(
                      locationProvider.currentPosition!.latitude,
                      locationProvider.currentPosition!.longitude,
                    )
                  : const LatLng(
                      11.0168,
                      76.9558,
                    ), // Coimbatore as fallback default
              zoom: 15,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            mapType: _getMapType(),
            trafficEnabled: _isTrafficEnabled,
            onMapCreated: (controller) {
              _mapController = controller;
              final locationProvider = context.read<LocationProvider>();
              if (locationProvider.currentPosition != null) {
                _mapController!.animateCamera(
                  CameraUpdate.newLatLngZoom(
                    LatLng(
                      locationProvider.currentPosition!.latitude,
                      locationProvider.currentPosition!.longitude,
                    ),
                    16,
                  ),
                );
              }
            },
            markers: rideViewModel.nearbyRides.map((ride) {
              return Marker(
                markerId: MarkerId(ride.id),
                position: LatLng(ride.pickupCoords[1], ride.pickupCoords[0]),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueOrange,
                ),
                infoWindow: InfoWindow(title: 'Ride Request'),
              );
            }).toSet(),
          ),
          // Floating Map Layers Control
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            right: 16,
            child: MapLayersControl(
              selectedLayer: _selectedMapLayer,
              isDarkMode: Theme.of(context).brightness == Brightness.dark,
              onLayerSelected: (layer) {
                setState(() {
                  _selectedMapLayer = layer;
                  _isTrafficEnabled = (layer == MapLayerType.traffic);
                });
              },
            ),
          ),
          // Go to current location FAB
          Positioned(
            right: 16,
            bottom: 280,
            child: FloatingActionButton.small(
              heroTag: "location_fab",
              onPressed: _getCurrentLocation,
              backgroundColor: Colors.white,
              child: locationProvider.isFetchingLocation
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location, color: Colors.blue),
            ),
          ),
          // Top Online/Offline Toggle
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 10.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () => rideViewModel.toggleOnlineOffline(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: rideViewModel.isOnline
                            ? Colors.green
                            : Colors.red,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            rideViewModel.isOnline
                                ? Icons.online_prediction
                                : Icons.offline_bolt,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            rideViewModel.isOnline ? 'ONLINE' : 'OFFLINE',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Earnings Summary Card
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black12)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (locationProvider.error != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              locationProvider.error!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: Colors.red,
                              size: 18,
                            ),
                            onPressed: () => locationProvider.clearError(),
                          ),
                        ],
                      ),
                    ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatColumn('Earnings', '₹1,250'),
                      const VerticalDivider(thickness: 1),
                      _buildStatColumn('Rides', '12'),
                      const VerticalDivider(thickness: 1),
                      _buildStatColumn('Rating', '4.8 ★'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Ride Request Popup
          if (rideViewModel.incomingRequest != null) const RideRequestPopup(),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}


