import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../models/payment_model.dart';
import 'package:intl/intl.dart';

class AdminPaymentsScreen extends StatefulWidget {
  const AdminPaymentsScreen({super.key});

  @override
  State<AdminPaymentsScreen> createState() => _AdminPaymentsScreenState();
}

class _AdminPaymentsScreenState extends State<AdminPaymentsScreen> {
  String _statusFilter = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().fetchPayments();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.payments.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null && provider.payments.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: ${provider.error}', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => provider.fetchPayments(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final filteredPayments = provider.payments.where((p) {
          return _statusFilter == 'all' || p.status == _statusFilter;
        }).toList();

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildEarningsCard(provider.totalEarnings),
              const SizedBox(height: 20),
              _buildFilterRow(),
              const SizedBox(height: 16),
              Expanded(
                child: filteredPayments.isEmpty
                    ? const Center(child: Text('No transactions found'))
                    : ListView.builder(
                        itemCount: filteredPayments.length,
                        itemBuilder: (context, index) {
                          final payment = filteredPayments[index];
                          return _buildPaymentCard(payment);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEarningsCard(double total) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient:
            const LinearGradient(colors: [Colors.red, Colors.orangeAccent]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.red.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 5))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Total Earnings',
              style: TextStyle(color: Colors.white70, fontSize: 16)),
          const SizedBox(height: 8),
          Text(
            '₹${NumberFormat('#,##,###').format(total)}',
            style: const TextStyle(
                color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Transactions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        DropdownButton<String>(
          value: _statusFilter,
          items: ['all', 'completed', 'pending', 'failed']
              .map((s) => DropdownMenuItem(
                  value: s,
                  child: Text(s.toUpperCase(),
                      style: const TextStyle(fontSize: 12))))
              .toList(),
          onChanged: (val) => setState(() => _statusFilter = val!),
        ),
      ],
    );
  }

  Widget _buildPaymentCard(PaymentModel payment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: Colors.red.withValues(alpha: 0.1),
          child: const Icon(Icons.account_balance_wallet, color: Colors.red),
        ),
        title: Text(payment.userName ?? 'Unknown User',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('ID: ${payment.transactionId ?? 'N/A'}',
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
            Text(
                payment.createdAt != null
                    ? DateFormat('dd MMM yyyy, hh:mm a')
                        .format(payment.createdAt!)
                    : '-',
                style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('₹${payment.amount}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.green)),
            const SizedBox(height: 4),
            Text(
              payment.status.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: payment.status == 'completed'
                    ? Colors.green
                    : (payment.status == 'failed' ? Colors.red : Colors.orange),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
