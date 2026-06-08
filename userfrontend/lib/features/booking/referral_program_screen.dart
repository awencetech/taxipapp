import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/referral_provider.dart';
import '../../core/theme/app_colors.dart';

class ReferralProgramScreen extends StatefulWidget {
  const ReferralProgramScreen({super.key});

  @override
  State<ReferralProgramScreen> createState() => _ReferralProgramScreenState();
}

class _ReferralProgramScreenState extends State<ReferralProgramScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ReferralProvider>(context, listen: false).fetchReferralData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final referralProvider = Provider.of<ReferralProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Referral Program',
            style: TextStyle(color: AppColors.black)),
      ),
      body: referralProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Referral Code Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF6B35), Color(0xFFEC4400)],
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Your Referral Code',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            referralProvider.referralData?.referralCode ??
                                'TAXI123',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 4,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  // Copy to clipboard
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Referral code copied!')),
                                  );
                                },
                                icon: const Icon(Icons.copy),
                                label: const Text('Copy'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: const Color(0xFFFF6B35),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {},
                                icon: const Icon(Icons.share),
                                label: const Text('Share'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      Colors.white.withValues(alpha: 0.2),
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Stats
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          title: 'Total Referrals',
                          value:
                              '${referralProvider.referralData?.totalReferrals ?? 0}',
                          icon: Icons.people_outline,
                          color: AppColors.secondary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          title: 'Total Earnings',
                          value:
                              '₹${referralProvider.referralData?.totalEarnings ?? 0}',
                          icon: Icons.account_balance_wallet_outlined,
                          color: const Color(0xFF4CD964),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // How it works
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('How it works',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 16),
                  _buildHowItWorks(),
                  const SizedBox(height: 24),
                  // Referral History
                  if ((referralProvider.referralData?.history ?? []).isNotEmpty)
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Referral History',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  if ((referralProvider.referralData?.history ?? []).isNotEmpty)
                    const SizedBox(height: 16),
                  ...(referralProvider.referralData?.history ?? []).map((item) {
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(item.referredUserName[0]),
                      ),
                      title: Text(item.referredUserName),
                      subtitle: Text(
                          '${item.date.day}/${item.date.month}/${item.date.year}'),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: item.status == 'credited'
                              ? Colors.green.withValues(alpha: 0.1)
                              : Colors.yellow.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          item.status == 'credited'
                              ? '₹${item.earnings}'
                              : 'Pending',
                          style: TextStyle(
                            color: item.status == 'credited'
                                ? Colors.green
                                : Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Text(title,
              style: const TextStyle(color: AppColors.grey600, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildHowItWorks() {
    return Column(
      children: [
        _buildHowItWorksStep('1', 'Share your referral code',
            'Share your referral code with friends and family'),
        const SizedBox(height: 16),
        _buildHowItWorksStep('2', 'They sign up using your code',
            'When they sign up using your referral code'),
        const SizedBox(height: 16),
        _buildHowItWorksStep('3', 'You both get rewarded',
            'Both of you get exciting rewards on their first ride'),
      ],
    );
  }

  Widget _buildHowItWorksStep(String number, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.secondary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: AppColors.secondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(description,
                  style:
                      const TextStyle(color: AppColors.grey600, fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }
}
