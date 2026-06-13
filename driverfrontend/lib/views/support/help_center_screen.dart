import 'package:flutter/material.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  final List<String> _expandedItems = [];
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, String>> _faqData = [
    {
      'question': 'How do I start a ride?',
      'answer': '1. Go online by toggling the switch on the home screen.\n2. Wait for a ride request.\n3. When you receive a request, tap "Accept".\n4. Navigate to the pickup location.\n5. Once the passenger is in the car, start the ride.',
    },
    {
      'question': 'When will I get paid?',
      'answer': 'Payments are processed weekly on Wednesdays. You will receive your earnings in your registered bank account within 3-5 business days.',
    },
    {
      'question': 'What to do in case of emergency?',
      'answer': 'In case of emergency, tap the emergency button in the app or call the local emergency number immediately. You can also contact our 24/7 support line.',
    },
    {
      'question': 'How to update vehicle documents?',
      'answer': '1. Go to the "More" tab.\n2. Tap on "Documents" or "Vehicle Management".\n3. Select the document you want to update.\n4. Upload the new document and submit for verification.',
    },
    {
      'question': 'How do I change my bank account details?',
      'answer': '1. Go to the "More" tab.\n2. Tap on "Bank Details".\n3. Enter your new bank account information.\n4. Save the changes.',
    },
    {
      'question': 'What if a passenger cancels the ride?',
      'answer': 'If a passenger cancels the ride after you have arrived at the pickup location, you may be eligible for a cancellation fee. The fee will be automatically added to your wallet.',
    },
  ];

  List<Map<String, String>> get _filteredFAQ {
    if (_searchController.text.isEmpty) {
      return _faqData;
    }
    return _faqData
        .where((item) =>
            item['question']!.toLowerCase().contains(_searchController.text.toLowerCase()) ||
            item['answer']!.toLowerCase().contains(_searchController.text.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Help Center',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'How can we help you?',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              children: [
                _buildSearchField(),
                const SizedBox(height: 32),
                _buildCategoryGrid(),
                const SizedBox(height: 32),
                const Text(
                  'Popular Questions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ..._filteredFAQ
                    .asMap()
                    .entries
                    .map((entry) => _buildFAQItem(entry.value, entry.key)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: 'Search for topics...',
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Theme.of(context).cardColor,
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
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Opening $title section...')),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: const Color(0xFFFF6D00), size: 32),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFAQItem(Map<String, String> faq, int index) {
    final isExpanded = _expandedItems.contains(index.toString());
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ExpansionTile(
        title: Text(
          faq['question']!,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        initiallyExpanded: isExpanded,
        onExpansionChanged: (expanded) {
          setState(() {
            if (expanded) {
              _expandedItems.add(index.toString());
            } else {
              _expandedItems.remove(index.toString());
            }
          });
        },
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              faq['answer']!,
              style: TextStyle(color: Colors.grey[600], height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
