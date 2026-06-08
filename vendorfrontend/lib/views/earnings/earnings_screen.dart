import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/earning_viewmodel.dart';

class EarningsScreen extends StatelessWidget {
  const EarningsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final earningVM = context.watch<EarningViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Earnings'),
      ),
      body: RefreshIndicator(
        onRefresh: () => earningVM.fetchEarnings(),
        child: _buildEarningsContent(earningVM),
      ),
    );
  }

  Widget _buildEarningsContent(EarningViewModel earningVM) {
    if (earningVM.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (earningVM.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                earningVM.errorMessage!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => earningVM.fetchEarnings(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (earningVM.earnings == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('No earnings data available'),
        ),
      );
    }

    final earnings = earningVM.earnings!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            color: Colors.green[50],
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Text(
                    'Wallet Balance',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '₹${earnings.walletBalance.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: [
              _buildEarningCard(
                'Today',
                '₹${earnings.todayEarnings.toStringAsFixed(0)}',
                Colors.blue,
              ),
              _buildEarningCard(
                'This Week',
                '₹${earnings.weeklyEarnings.toStringAsFixed(0)}',
                Colors.orange,
              ),
              _buildEarningCard(
                'This Month',
                '₹${earnings.monthlyEarnings.toStringAsFixed(0)}',
                Colors.purple,
              ),
              _buildEarningCard(
                'Total',
                '₹${earnings.totalEarnings.toStringAsFixed(0)}',
                Colors.teal,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Commission Summary',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.account_balance_wallet),
                    title: const Text('Your Commission'),
                    trailing: Text(
                      '₹${earnings.vendorCommission.toStringAsFixed(0)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.person),
                    title: const Text('Drivers\' Commission'),
                    trailing: Text(
                      '₹${earnings.driverCommission.toStringAsFixed(0)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEarningCard(String title, String value, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
