import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/theme_viewmodel.dart';
import '../../viewmodels/earning_viewmodel.dart';
import '../dashboard/dashboard_screen.dart';

class EarningsScreen extends StatefulWidget {
  final bool isActive;
  const EarningsScreen({super.key, this.isActive = true});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  String _activeTab = 'All Transactions';
  final List<String> _tabs = ['All Transactions', 'Settled', 'Pending'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final earningVM = context.read<EarningViewModel>();
        if (earningVM.earnings == null) {
          earningVM.fetchEarnings();
        }
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  List<Map<String, dynamic>> _filteredTransactions(List<Map<String, dynamic>> txns) {
    if (_activeTab == 'All Transactions') return txns;
    return txns.where((txn) => txn['status'] == _activeTab).toList();
  }

  @override
  Widget build(BuildContext context) {
    final themeVM = context.watch<ThemeViewModel>();
    final isDark = themeVM.isDarkMode;
    final earningVM = context.watch<EarningViewModel>();
    final earnings = earningVM.earnings;
    final txns = earnings?.transactions ?? [];
    final filteredTxns = _filteredTransactions(txns);

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
                      'Payment Management',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Manage wallets, payouts, and transaction history',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Stats Cards Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildStatCard(
                        title: 'Wallet Balance',
                        value: earnings != null ? '₹${earnings.walletBalance.toStringAsFixed(0)}' : '₹0',
                        icon: Icons.wallet_outlined,
                        bgColor: const Color(0xFFFFECD2),
                        iconColor: const Color(0xFFFF7A00),
                        isDark: isDark,
                      ),
                      const SizedBox(width: 16),
                      _buildStatCard(
                        title: 'Pending Payments',
                        value: earnings != null ? '₹${earnings.pendingPayments.toStringAsFixed(0)}' : '₹0',
                        icon: Icons.access_time_outlined,
                        bgColor: const Color(0xFFFFF3E0),
                        iconColor: const Color(0xFFF59E0B),
                        isDark: isDark,
                      ),
                      const SizedBox(width: 16),
                      _buildStatCard(
                        title: 'Settled Payments',
                        value: earnings != null ? '₹${earnings.settledPayments.toStringAsFixed(0)}' : '₹0',
                        icon: Icons.check_circle_outline,
                        bgColor: const Color(0xFFE0F7E9),
                        iconColor: const Color(0xFF10B981),
                        isDark: isDark,
                      ),
                      const SizedBox(width: 16),
                      _buildStatCard(
                        title: 'Driver Payouts',
                        value: earnings != null ? '₹${earnings.driverPayouts.toStringAsFixed(0)}' : '₹0',
                        icon: Icons.account_balance_wallet_outlined,
                        bgColor: const Color(0xFFDBEAFE),
                        iconColor: const Color(0xFF3B82F6),
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Payment Methods Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isSmallScreen = constraints.maxWidth < 400;
                    return GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: isSmallScreen ? 1 : 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: isSmallScreen ? 3 : 2.5,
                      children: [
                        _buildPaymentMethodCard(
                          title: 'Bank Transfer',
                          subtitle: 'Direct transfer to bank account',
                          details: 'Account: ****1234',
                          icon: Icons.account_balance_outlined,
                          bgColor: const Color(0xFFDBEAFE),
                          iconColor: const Color(0xFF3B82F6),
                          isDark: isDark,
                        ),
                        _buildPaymentMethodCard(
                          title: 'UPI Payment',
                          subtitle: 'Instant UPI transfers',
                          details: 'UPI: vendor@paytm',
                          icon: Icons.account_balance_wallet_outlined,
                          bgColor: const Color(0xFFEDE7F6),
                          iconColor: const Color(0xFF8B5CF6),
                          isDark: isDark,
                        ),
                        _buildPaymentMethodCard(
                          title: 'Wallet Balance',
                          subtitle: 'Available balance',
                          details: earnings != null ? '₹${earnings.walletBalance.toStringAsFixed(0)}' : '₹0',
                          icon: Icons.wallet_outlined,
                          bgColor: const Color(0xFFE0F7E9),
                          iconColor: const Color(0xFF10B981),
                          isDark: isDark,
                          highlightText: true,
                        ),
                      ],
                    );
                  },
                ),
              ),

              const SizedBox(height: 32),

              // Transaction History Container
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Transaction History',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'All payment transactions and settlements',
                        style: TextStyle(
                          fontSize: 16,
                          color: isDark
                              ? Colors.grey[400]
                              : const Color(0xFF64748B),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Transaction Tabs
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.grey[800]
                                : const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Row(
                            children: _tabs.map((tab) {
                              final isSelected = _activeTab == tab;
                              return Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _activeTab = tab;
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(0xFFFF7A00)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: isSelected
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
                                    child: Text(
                                      tab,
                                      style: TextStyle(
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.w600,
                                        fontSize: 15,
                                        color: isSelected
                                            ? Colors.white
                                            : (isDark
                                                  ? Colors.grey[300]
                                                  : Colors.grey[800]),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Transactions - responsive
                      LayoutBuilder(
                        builder: (context, constraints) {
                          if (filteredTxns.isEmpty) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 40),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.history,
                                      size: 56,
                                      color: isDark ? Colors.grey[700] : Colors.grey[300],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No transactions found',
                                      style: TextStyle(
                                        color: isDark ? Colors.grey[500] : Colors.grey[400],
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          final isSmallScreen = constraints.maxWidth < 600;

                          if (isSmallScreen) {
                            // Card-based view for small screens
                            return Column(
                              children: filteredTxns.asMap().entries.map((
                                entry,
                              ) {
                                final txn = entry.value;
                                Color statusColor;
                                switch (txn['status']) {
                                  case 'Settled':
                                    statusColor = const Color(0xFF10B981);
                                    break;
                                  case 'Pending':
                                    statusColor = const Color(0xFFF59E0B);
                                    break;
                                  default:
                                    statusColor = Colors.grey;
                                }

                                return Container(
                                  width: double.infinity,
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: entry.key.isOdd
                                        ? (isDark
                                              ? Colors.grey[800]!.withValues(
                                                  alpha: 0.5,
                                                )
                                              : const Color(0xFFF8FAFC))
                                        : (isDark
                                              ? const Color(0xFF1E1E1E)
                                              : Colors.white),
                                    border: Border.all(
                                      color: isDark
                                          ? Colors.grey[700]!
                                          : const Color(0xFFE2E8F0),
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              txn['id'],
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                                color: isDark
                                                    ? Colors.white
                                                    : const Color(0xFF1F2937),
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            onPressed: () {},
                                            icon: const Icon(
                                              Icons.download_outlined,
                                              size: 20,
                                            ),
                                            color: isDark
                                                ? Colors.grey[300]
                                                : const Color(0xFF64748B),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      _buildMobileDetailRow(
                                        'Date',
                                        txn['date'],
                                        isDark,
                                      ),
                                      const SizedBox(height: 8),
                                      _buildMobileDetailRow(
                                        'Driver',
                                        txn['driver'],
                                        isDark,
                                      ),
                                      const SizedBox(height: 8),
                                      _buildMobileDetailRow(
                                        'User',
                                        txn['user'],
                                        isDark,
                                      ),
                                      const SizedBox(height: 8),
                                      _buildMobileDetailRow(
                                        'Type',
                                        txn['type'],
                                        isDark,
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            '₹${txn['amount'].toString()}',
                                            style: TextStyle(
                                              fontSize: 20,
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
                                              color: statusColor.withValues(
                                                alpha: 0.1,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              txn['status'],
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                                color: statusColor,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            );
                          } else {
                            // Table view for larger screens
                            return SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Container(
                                width: 850,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: isDark
                                        ? Colors.grey[700]!
                                        : const Color(0xFFE2E8F0),
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Table Header
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? Colors.grey[800]
                                            : const Color(0xFFF8FAFC),
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(20),
                                          topRight: Radius.circular(20),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              'Transaction ID',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                                color: isDark
                                                    ? Colors.white
                                                    : const Color(0xFF1F2937),
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: Text(
                                              'Date',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                                color: isDark
                                                    ? Colors.white
                                                    : const Color(0xFF1F2937),
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: Text(
                                              'Driver',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                                color: isDark
                                                    ? Colors.white
                                                    : const Color(0xFF1F2937),
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: Text(
                                              'User',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                                color: isDark
                                                    ? Colors.white
                                                    : const Color(0xFF1F2937),
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: Text(
                                              'Type',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                                color: isDark
                                                    ? Colors.white
                                                    : const Color(0xFF1F2937),
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: Text(
                                              'Amount',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                                color: isDark
                                                    ? Colors.white
                                                    : const Color(0xFF1F2937),
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: Text(
                                              'Status',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                                color: isDark
                                                    ? Colors.white
                                                    : const Color(0xFF1F2937),
                                              ),
                                            ),
                                          ),
                                          SizedBox(
                                            width: 50,
                                            child: Text(
                                              'Actions',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                                color: isDark
                                                    ? Colors.white
                                                    : const Color(0xFF1F2937),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    Divider(
                                      height: 1,
                                      color: isDark
                                          ? Colors.grey[600]
                                          : Colors.grey[300],
                                    ),

                                    // Table Rows
                                    ...filteredTxns.asMap().entries.map((
                                      entry,
                                    ) {
                                      final txn = entry.value;
                                      Color statusColor;
                                      switch (txn['status']) {
                                        case 'Settled':
                                          statusColor = const Color(0xFF10B981);
                                          break;
                                        case 'Pending':
                                          statusColor = const Color(0xFFF59E0B);
                                          break;
                                        default:
                                          statusColor = Colors.grey;
                                      }

                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: entry.key.isOdd
                                              ? (isDark
                                                    ? Colors.grey[800]!
                                                          .withValues(
                                                            alpha: 0.5,
                                                          )
                                                    : const Color(0xFFF8FAFC))
                                              : Colors.transparent,
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                txn['id'],
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 13,
                                                  color: isDark
                                                      ? Colors.white
                                                      : const Color(0xFF1F2937),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: Text(
                                                txn['date'],
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: isDark
                                                      ? Colors.grey[300]
                                                      : const Color(0xFF64748B),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: Text(
                                                txn['driver'],
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: isDark
                                                      ? Colors.white
                                                      : const Color(0xFF1F2937),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: Text(
                                                txn['user'],
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: isDark
                                                      ? Colors.white
                                                      : const Color(0xFF1F2937),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: Text(
                                                txn['type'],
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: isDark
                                                      ? Colors.grey[300]
                                                      : const Color(0xFF64748B),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: Text(
                                                '₹${txn['amount'].toString()}',
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.bold,
                                                  color: isDark
                                                      ? Colors.white
                                                      : const Color(0xFF1F2937),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: statusColor.withValues(
                                                    alpha: 0.1,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                child: Text(
                                                  txn['status'],
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: statusColor,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            SizedBox(
                                              width: 50,
                                              child: IconButton(
                                                padding: EdgeInsets.zero,
                                                constraints:
                                                    const BoxConstraints(),
                                                onPressed: () {},
                                                icon: const Icon(
                                                  Icons.download_outlined,
                                                  size: 18,
                                                ),
                                                color: isDark
                                                    ? Colors.grey[300]
                                                    : const Color(0xFF64748B),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              ),
                            );
                          }
                        },
                      ),
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

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color bgColor,
    required Color iconColor,
    required bool isDark,
  }) {
    return Container(
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
  }

  Widget _buildPaymentMethodCard({
    required String title,
    required String subtitle,
    required String details,
    required IconData icon,
    required Color bgColor,
    required Color iconColor,
    required bool isDark,
    bool highlightText = false,
  }) {
    return Container(
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? iconColor.withValues(alpha: 0.2) : bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 26),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1F2937),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  details,
                  style: TextStyle(
                    fontSize: 13,
                    color: highlightText
                        ? const Color(0xFFFF7A00)
                        : (isDark ? Colors.grey[400] : const Color(0xFF64748B)),
                    fontWeight: highlightText
                        ? FontWeight.bold
                        : FontWeight.w500,
                  ),
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

  Widget _buildMobileDetailRow(String label, String value, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '$label:',
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF1F2937),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
