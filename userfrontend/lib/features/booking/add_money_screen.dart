import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class AddMoneyScreen extends StatefulWidget {
  const AddMoneyScreen({super.key});

  @override
  State<AddMoneyScreen> createState() => _AddMoneyScreenState();
}

class _AddMoneyScreenState extends State<AddMoneyScreen> {
  final TextEditingController _amountController = TextEditingController(text: '₹500');
  int? _selectedPaymentMethod;

  final List<Map<String, dynamic>> paymentMethods = const [
    {
      'icon': Icons.payment,
      'name': 'Credit / Debit Card',
      'color': Color(0xFF4A90E2),
    },
    {
      'icon': Icons.account_balance_wallet,
      'name': 'UPI',
      'color': Color(0xFF4CD964),
    },
    {
      'icon': Icons.account_balance,
      'name': 'Net Banking',
      'color': Color(0xFF9B59B6),
    },
    {
      'icon': Icons.phone_iphone,
      'name': 'PhonePe',
      'color': Color(0xFF5C6BC0),
    },
    {
      'icon': Icons.phone_iphone,
      'name': 'Google Pay',
      'color': Color(0xFF4285F4),
    },
    {
      'icon': Icons.phone_iphone,
      'name': 'Paytm',
      'color': Color(0xFF00AAEA),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, size: 30),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Add Money',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Enter Amount
                    const Text(
                      'Enter Amount',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        hintText: '₹0',
                        filled: true,
                        fillColor: AppColors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.all(20),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Quick Amounts
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ...['₹100', '₹250', '₹500', '₹1000'].map((amount) {
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _amountController.text = amount;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: _amountController.text == amount
                                    ? AppColors.secondary
                                    : AppColors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                amount,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: _amountController.text == amount
                                      ? AppColors.white
                                      : AppColors.black,
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                    const SizedBox(height: 32),
                    // Payment Methods
                    const Text(
                      'Payment Methods',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...List.generate(paymentMethods.length, (index) {
                      final method = paymentMethods[index];
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedPaymentMethod = index;
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                            border: _selectedPaymentMethod == index
                                ? Border.all(color: AppColors.secondary, width: 2)
                                : null,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: method['color'].withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  method['icon'],
                                  color: method['color'],
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  method['name'],
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _selectedPaymentMethod == index
                                      ? AppColors.secondary
                                      : AppColors.grey300,
                                ),
                                child: _selectedPaymentMethod == index
                                    ? const Icon(
                                        Icons.check,
                                        color: AppColors.white,
                                        size: 16,
                                      )
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 32),
                    // Promo Code
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.local_offer,
                            color: AppColors.secondary,
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Have a promo code?',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {},
                            child: const Text(
                              'Apply',
                              style: TextStyle(
                                color: AppColors.secondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Proceed Button
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: _selectedPaymentMethod != null
                    ? () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Money added successfully!'),
                            backgroundColor: Color(0xFF4CD964),
                          ),
                        );
                        Navigator.pop(context);
                      }
                    : null,
                child: const Text(
                  'Proceed to Pay',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}