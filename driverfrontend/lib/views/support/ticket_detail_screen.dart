import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/driver_models.dart';
import '../../viewmodels/ride_viewmodel.dart';

class TicketDetailScreen extends StatefulWidget {
  final SupportTicketModel ticket;

  const TicketDetailScreen({super.key, required this.ticket});

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  bool _isLoading = false;

  Color getStatusColor(String status) {
    switch (status) {
      case 'Open':
        return Colors.orange;
      case 'In Progress':
        return Colors.blue;
      case 'Resolved':
        return Colors.green;
      case 'Closed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final rideViewModel = Provider.of<RideViewModel>(context, listen: false);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Ticket Details',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          widget.ticket.ticketId ?? widget.ticket.id,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: getStatusColor(
                              widget.ticket.status,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            widget.ticket.status,
                            style: TextStyle(
                              color: getStatusColor(widget.ticket.status),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.ticket.subject,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.category, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Text(
                          widget.ticket.category,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.ticket.description,
                      style: TextStyle(color: Colors.grey[700], fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    if (widget.ticket.createdAt != null)
                      Text(
                        'Created: ${widget.ticket.createdAt!.day}/${widget.ticket.createdAt!.month}/${widget.ticket.createdAt!.year}',
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (widget.ticket.messages.isNotEmpty) ...[
              const Text(
                'Conversation',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ...widget.ticket.messages.map((message) {
                final isAdmin = false; // We'll implement this later
                return Align(
                  alignment: isAdmin
                      ? Alignment.centerLeft
                      : Alignment.centerRight,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isAdmin ? Colors.grey[200] : Colors.orange[100],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: isAdmin
                          ? CrossAxisAlignment.start
                          : CrossAxisAlignment.end,
                      children: [
                        Text(
                          message.message,
                          style: TextStyle(
                            color: Colors.grey[800],
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${message.timestamp.hour}:${message.timestamp.minute}',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
            const SizedBox(height: 24),
            const Text(
              'Send a message',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      maxLines: 3,
                      minLines: 1,
                      decoration: const InputDecoration(
                        hintText: 'Type your message...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: _isLoading
                        ? const CircularProgressIndicator()
                        : Icon(Icons.send, color: Colors.orange[600]),
                    onPressed: () async {
                      if (_messageController.text.trim().isEmpty) return;
                      setState(() => _isLoading = true);
                      try {
                        await rideViewModel.addMessage(
                          widget.ticket.id,
                          _messageController.text,
                        );
                        _messageController.clear();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Message sent!')),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to send: $e')),
                          );
                        }
                      } finally {
                        setState(() => _isLoading = false);
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
