import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/ride_viewmodel.dart';
import 'ticket_detail_screen.dart';
import 'support_screen.dart';

class MyTicketsScreen extends StatefulWidget {
  const MyTicketsScreen({super.key});

  @override
  State<MyTicketsScreen> createState() => _MyTicketsScreenState();
}

class _MyTicketsScreenState extends State<MyTicketsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final rideViewModel = Provider.of<RideViewModel>(context, listen: false);
      rideViewModel.fetchTickets();
      rideViewModel.fetchRideHistory();
    });
  }

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
    final rideViewModel = Provider.of<RideViewModel>(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'My Tickets',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: rideViewModel.ticketsLoading
          ? const Center(child: CircularProgressIndicator())
          : rideViewModel.tickets.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.support_agent_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No support tickets found',
                    style: TextStyle(color: Colors.grey[600], fontSize: 18),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      showRaiseTicketBottomSheet(context, rideViewModel);
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Raise Ticket'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF8A00),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: rideViewModel.tickets.length,
              itemBuilder: (context, index) {
                final ticket = rideViewModel.tickets[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            TicketDetailScreen(ticket: ticket),
                      ),
                    );
                  },
                  child: Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                ticket.ticketId ?? ticket.id,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: getStatusColor(
                                    ticket.status,
                                  ).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  ticket.status,
                                  style: TextStyle(
                                    color: getStatusColor(ticket.status),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            ticket.subject,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            ticket.category,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (ticket.createdAt != null)
                            Text(
                              'Created: ${ticket.createdAt!.day}/${ticket.createdAt!.month}/${ticket.createdAt!.year}',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
