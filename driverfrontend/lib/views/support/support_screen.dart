import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/ride_viewmodel.dart';
import 'my_tickets_screen.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

void showRaiseTicketBottomSheet(
  BuildContext context,
  RideViewModel rideViewModel,
) {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final List<String> categories = [
    'Ride Issue',
    'Driver Complaint',
    'Payment Problem',
    'Refund Issue',
    'Account Problem',
    'Safety Issue',
    'Other',
  ];
  final List<String> priorities = ['Low', 'Medium', 'High'];
  String selectedCategory = categories.first;
  String selectedPriority = priorities.first;
  String? selectedRideId;
  bool isSubmitting = false;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
    ),
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 24,
              right: 24,
              top: 24,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Raise Support Ticket',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Category Dropdown
                  const Text(
                    'Issue Category',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedCategory,
                        isExpanded: true,
                        items: categories.map((category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setModalState(() => selectedCategory = value!);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Ride Selection
                  const Text(
                    'Select a Ride (Optional)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  if (rideViewModel.rideHistory.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedRideId,
                          isExpanded: true,
                          hint: const Text('Select a ride'),
                          items: rideViewModel.rideHistory.map((ride) {
                            return DropdownMenuItem(
                              value: ride.id,
                              child: Text(
                                '${ride.pickupAddress.split(',').first}...',
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setModalState(() => selectedRideId = value);
                          },
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Title
                  const Text(
                    'Issue Title',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      hintText: 'Brief title of the issue',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFFF8A00)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Description
                  const Text(
                    'Description',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: descriptionController,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: 'Describe your issue in detail',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFFF8A00)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Priority
                  const Text(
                    'Priority',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedPriority,
                        isExpanded: true,
                        items: priorities.map((priority) {
                          return DropdownMenuItem(
                            value: priority,
                            child: Text(priority),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setModalState(() => selectedPriority = value!);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              if (titleController.text.trim().isEmpty ||
                                  descriptionController.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Please fill in all required fields',
                                    ),
                                  ),
                                );
                                return;
                              }
                              setModalState(() => isSubmitting = true);
                              try {
                                final ticket = await rideViewModel.createTicket(
                                  category: selectedCategory,
                                  title: titleController.text.trim(),
                                  description: descriptionController.text
                                      .trim(),
                                  rideId: selectedRideId,
                                  priority: selectedPriority,
                                );
                                if (ticket != null) {
                                  if (context.mounted) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Ticket created successfully!',
                                        ),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Failed to create ticket: $e',
                                      ),
                                    ),
                                  );
                                }
                              } finally {
                                setModalState(() => isSubmitting = false);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF8A00),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: isSubmitting
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Submit Ticket',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

class _SupportScreenState extends State<SupportScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final rideViewModel = Provider.of<RideViewModel>(context, listen: false);
      rideViewModel.fetchRideHistory();
      rideViewModel.fetchTickets();
    });
  }

  @override
  Widget build(BuildContext context) {
    final rideViewModel = Provider.of<RideViewModel>(context, listen: false);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Dark Gradient Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(
                top: 60,
                left: 24,
                right: 24,
                bottom: 40,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF1A1A1A),
                    Color(0xFFFF8A00),
                  ], // Dark to Orange
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.support_agent_outlined,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Support Center',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'How can we help you today?',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
              ),
            ),

            // Action Buttons
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Row(
                    children: [
                      _buildActionButton(
                        'Get Help',
                        Icons.help_outline,
                        const Color(0xFF2EBD59), // Green
                        () {},
                      ),
                      const SizedBox(width: 16),
                      _buildActionButton(
                        'My Tickets',
                        Icons.receipt_long_outlined,
                        const Color(0xFFFF8A00), // Orange
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const MyTicketsScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // FAQ Section
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Frequently Asked Questions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildFAQItem(
                    'How do I withdraw my earnings?',
                    'Go to Wallet → Withdraw Money',
                  ),
                  _buildFAQItem(
                    'How to update vehicle documents?',
                    'Go to Vehicle Management → Update Documents',
                  ),
                  _buildFAQItem(
                    'What if passenger cancels?',
                    'You\'ll receive a cancellation fee',
                  ),

                  const SizedBox(height: 24),

                  // Raise Ticket Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          showRaiseTicketBottomSheet(context, rideViewModel),
                      icon: const Icon(Icons.support_agent, size: 20),
                      label: const Text('Raise Ticket'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF8A00),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(icon, color: Colors.white, size: 28),
              const SizedBox(height: 12),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 8),
          Text(answer, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
        ],
      ),
    );
  }
}
