import 'package:flutter/material.dart';
import '../models/ticket_model.dart';
import '../services/api_service.dart';

class TicketProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<TicketModel> _tickets = [];
  TicketModel? _currentTicket;
  bool _isLoading = false;
  String? _error;

  List<TicketModel> get tickets => _tickets;
  TicketModel? get currentTicket => _currentTicket;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchTickets() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.getTickets();
      if (response.data['success'] == true && response.data['data'] != null) {
        _tickets = (response.data['data'] as List)
            .map((e) => TicketModel.fromMap(e))
            .toList();
      }
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createTicket(TicketModel ticket) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final Map<String, dynamic> data = {
        'subject': ticket.subject,
        'description': ticket.description,
        'category': ticket.category,
        'priority': ticket.priority,
      };
      if (ticket.rideId != null && ticket.rideId!.isNotEmpty) {
        data['ride'] = ticket.rideId;
      }
      final response = await _apiService.createTicket(data);
      if (response.data['success'] == true) {
        await fetchTickets();
        return true;
      } else {
        _error = response.data['message'] ?? 'Failed to create ticket';
        return false;
      }
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchTicketDetails(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.getTicketDetails(id);
      if (response.data['success'] == true && response.data['data'] != null) {
        _currentTicket = TicketModel.fromMap(response.data['data']);
      }
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> sendMessage(String ticketId, String message) async {
    try {
      final response = await _apiService.sendTicketMessage(ticketId, {
        'message': message,
      });
      if (response.data['success'] == true) {
        await fetchTicketDetails(ticketId);
        return true;
      } else {
        _error = response.data['message'] ?? 'Failed to send message';
        return false;
      }
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      return false;
    }
  }
}
