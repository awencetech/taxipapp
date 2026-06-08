import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/ticket_provider.dart';
import '../../core/models/ticket_model.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          title: const Text('Support Center',
              style: TextStyle(color: AppColors.black)),
          bottom: const TabBar(
            labelColor: AppColors.secondary,
            unselectedLabelColor: AppColors.grey600,
            indicatorColor: AppColors.secondary,
            tabs: [
              Tab(text: 'Get Help'),
              Tab(text: 'My Tickets'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            GetHelpTab(),
            MyTicketsTab(),
          ],
        ),
      ),
    );
  }
}

class GetHelpTab extends StatelessWidget {
  const GetHelpTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Support options grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 0.85,
            children: [
              _buildSupportOption(
                context,
                icon: Icons.chat,
                iconColor: const Color(0xFF4CD964),
                title: 'Live Chat',
                subtitle: 'team',
                onTap: () {},
              ),
              _buildSupportOption(
                context,
                icon: Icons.call,
                iconColor: const Color(0xFFFF9500),
                title: 'Call Support',
                subtitle: '1800-123-4567\n(Toll Free)',
                onTap: () {},
              ),
              _buildSupportOption(
                context,
                icon: Icons.email,
                iconColor: const Color(0xFF4A90E2),
                title: 'Email Support',
                subtitle: 'om',
                onTap: () {},
              ),
              _buildSupportOption(
                context,
                icon: Icons.feedback,
                iconColor: const Color(0xFF9B59B6),
                title: 'Raise a Ticket',
                subtitle: 'request',
                onTap: () => _showRaiseTicketDialog(context),
              ),
            ],
          ),
          const SizedBox(height: 32),
          // FAQ section
          const Row(
            children: [
              Icon(Icons.help_outline, color: Color(0xFFFF9500), size: 28),
              SizedBox(width: 10),
              Text(
                'Frequently Asked Questions',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildFAQItem(
            question: 'How do I cancel a ride?',
            answer:
                'You can cancel your ride from the ride details screen before the driver arrives.',
          ),
          const SizedBox(height: 12),
          _buildFAQItem(
            question: 'How to add a payment method?',
            answer:
                'Go to Profile > Payment Methods to add your preferred payment method.',
          ),
        ],
      ),
    );
  }

  Widget _buildSupportOption(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
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
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 26),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Flexible(
              child: Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.grey600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem({
    required String question,
    required String answer,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              answer,
              style: const TextStyle(color: AppColors.grey600),
            ),
          ),
        ],
      ),
    );
  }

  void _showRaiseTicketDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const RaiseTicketDialog(),
    );
  }
}

class MyTicketsTab extends StatefulWidget {
  const MyTicketsTab({super.key});

  @override
  State<MyTicketsTab> createState() => _MyTicketsTabState();
}

class _MyTicketsTabState extends State<MyTicketsTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TicketProvider>(context, listen: false).fetchTickets();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ticketProvider = Provider.of<TicketProvider>(context);
    return ticketProvider.isLoading
        ? const Center(child: CircularProgressIndicator())
        : ticketProvider.tickets.isEmpty
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.feedback_outlined,
                        size: 80, color: AppColors.grey400),
                    SizedBox(height: 16),
                    Text('No tickets yet',
                        style: TextStyle(color: AppColors.grey600)),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: ticketProvider.tickets.length,
                itemBuilder: (context, index) {
                  final ticket = ticketProvider.tickets[index];
                  return _buildTicketCard(ticket, context);
                },
              );
  }

  Widget _buildTicketCard(TicketModel ticket, BuildContext context) {
    Color statusColor;
    switch (ticket.status) {
      case 'open':
        statusColor = Colors.blue;
        break;
      case 'in_progress':
        statusColor = Colors.orange;
        break;
      case 'resolved':
        statusColor = Colors.green;
        break;
      case 'closed':
        statusColor = Colors.grey;
        break;
      default:
        statusColor = Colors.blue;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        title: Text(ticket.subject,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
            '${ticket.category} • ${ticket.createdAt.day}/${ticket.createdAt.month}'),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(ticket.status,
              style:
                  TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
        ),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => TicketDetailScreen(ticket: ticket),
            ),
          );
        },
      ),
    );
  }
}

class RaiseTicketDialog extends StatefulWidget {
  const RaiseTicketDialog({super.key});

  @override
  State<RaiseTicketDialog> createState() => _RaiseTicketDialogState();
}

class _RaiseTicketDialogState extends State<RaiseTicketDialog> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedCategory = 'General';
  String _selectedPriority = 'Medium';

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitTicket() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = Provider.of<TicketProvider>(context, listen: false);
    final newTicket = TicketModel(
      id: '',
      subject: _subjectController.text,
      description: _descriptionController.text,
      category: _selectedCategory,
      priority: _selectedPriority.toLowerCase(),
      createdAt: DateTime.now(),
      messages: const [],
    );

    bool success = await provider.createTicket(newTicket);
    if (mounted) {
      if (success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Ticket raised successfully!'),
              backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.error ?? 'Failed to raise ticket')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TicketProvider>(context);
    return AlertDialog(
      title: const Text('Raise a Ticket'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12))),
                items: const [
                  DropdownMenuItem(value: 'General', child: Text('General')),
                  DropdownMenuItem(value: 'Rides', child: Text('Rides')),
                  DropdownMenuItem(value: 'Payments', child: Text('Payments')),
                  DropdownMenuItem(value: 'Account', child: Text('Account')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value!;
                  });
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _selectedPriority,
                decoration: InputDecoration(
                    labelText: 'Priority',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12))),
                items: const [
                  DropdownMenuItem(value: 'Low', child: Text('Low')),
                  DropdownMenuItem(value: 'Medium', child: Text('Medium')),
                  DropdownMenuItem(value: 'High', child: Text('High')),
                  DropdownMenuItem(value: 'Urgent', child: Text('Urgent')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedPriority = value!;
                  });
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _subjectController,
                decoration: InputDecoration(
                    labelText: 'Subject',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12))),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12))),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel')),
        TextButton(
            onPressed: provider.isLoading ? null : _submitTicket,
            child: provider.isLoading
                ? const CircularProgressIndicator()
                : const Text('Submit')),
      ],
    );
  }
}

class TicketDetailScreen extends StatefulWidget {
  final TicketModel ticket;

  const TicketDetailScreen({super.key, required this.ticket});

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  final TextEditingController _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final provider = Provider.of<TicketProvider>(context, listen: false);
    await provider.sendMessage(widget.ticket.id, _messageController.text);
    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TicketProvider>(context);
    final ticket = provider.currentTicket ?? widget.ticket;

    Color statusColor;
    switch (ticket.status) {
      case 'open':
        statusColor = Colors.blue;
        break;
      case 'in_progress':
        statusColor = Colors.orange;
        break;
      case 'resolved':
        statusColor = Colors.green;
        break;
      case 'closed':
        statusColor = Colors.grey;
        break;
      default:
        statusColor = Colors.blue;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Ticket #${ticket.id.substring(0, 8)}'),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: AppColors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ticket.subject,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(ticket.status,
                          style: TextStyle(
                              color: statusColor, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 8),
                    Text(ticket.category,
                        style: const TextStyle(color: AppColors.grey600)),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: ticket.messages.length,
              itemBuilder: (context, index) {
                final message = ticket.messages[index];
                return Align(
                  alignment: message.isUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: message.isUser
                          ? AppColors.secondary
                          : AppColors.grey200,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      message.message,
                      style: TextStyle(
                          color:
                              message.isUser ? Colors.white : AppColors.black),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _sendMessage,
                  icon: const Icon(Icons.send),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
