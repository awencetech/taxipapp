import 'package:flutter/material.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help Center'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'How can we help you?',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          _buildSearchField(),
          const SizedBox(height: 32),
          _buildCategoryGrid(),
          const SizedBox(height: 32),
          const Text(
            'Popular Questions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildFAQItem('How do I start a ride?'),
          _buildFAQItem('When will I get paid?'),
          _buildFAQItem('What to do in case of emergency?'),
          _buildFAQItem('How to update vehicle documents?'),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Search for topics...',
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        filled: true,
        fillColor: Colors.grey[100],
      ),
    );
  }

  Widget _buildCategoryGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildCategoryCard(Icons.local_taxi, 'Rides'),
        _buildCategoryCard(Icons.account_balance_wallet, 'Payments'),
        _buildCategoryCard(Icons.person, 'Account'),
        _buildCategoryCard(Icons.security, 'Security'),
      ],
    );
  }

  Widget _buildCategoryCard(IconData icon, String title) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: const Color(0xFFFF6D00)),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildFAQItem(String question) {
    return ListTile(
      title: Text(question),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {},
    );
  }
}
