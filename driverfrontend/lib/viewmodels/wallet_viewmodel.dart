import 'package:flutter/material.dart';
import '../services/api_service.dart';

class WalletTransaction {
  final String id;
  final double amount;
  final String type; // 'credit' | 'debit'
  final String description;
  final String? reference;
  final DateTime date;

  WalletTransaction({
    required this.id,
    required this.amount,
    required this.type,
    required this.description,
    this.reference,
    required this.date,
  });

  bool get isCredit => type == 'credit';

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      id: json['_id'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      type: json['type'] ?? 'credit',
      description: json['description'] ?? '',
      reference: json['reference'],
      date: json['date'] != null
          ? DateTime.tryParse(json['date'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class WalletViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  double _balance = 0;
  List<WalletTransaction> _transactions = [];
  bool _isLoading = false;
  bool _isWithdrawing = false;
  String? _error;

  double get balance => _balance;
  List<WalletTransaction> get transactions => _transactions;
  bool get isLoading => _isLoading;
  bool get isWithdrawing => _isWithdrawing;
  String? get error => _error;

  /// Fetches real wallet balance + transaction history from backend
  Future<void> fetchWallet() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.get('/api/wallets/my-wallet');
      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'] as Map<String, dynamic>;
        _balance = (data['balance'] ?? 0).toDouble();

        final rawTx = data['transactions'] as List<dynamic>? ?? [];
        _transactions = rawTx
            .map((tx) => WalletTransaction.fromJson(tx as Map<String, dynamic>))
            .toList();

        // Sort newest first
        _transactions.sort((a, b) => b.date.compareTo(a.date));
      } else {
        _error = response.data['message'] ?? 'Failed to load wallet';
      }
    } catch (e) {
      _error = 'Could not load wallet. Please check your connection.';
      debugPrint('WalletViewModel fetchWallet error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Submit a withdrawal request (deducts from wallet via backend)
  Future<bool> withdraw({
    required double amount,
    required String method,
    String? upiId,
  }) async {
    _isWithdrawing = true;
    _error = null;
    notifyListeners();

    try {
      final desc = switch (method) {
        'UPI' => 'Withdrawal via UPI${upiId != null ? " ($upiId)" : ""}',
        'Cash' => 'Cash withdrawal request',
        _ => 'Withdrawal to Bank',
      };

      final response = await _apiService.post(
        '/api/wallets/deduct',
        data: {
          'amount': amount,
          'description': desc,
          'reference': 'WITHDRAW_${DateTime.now().millisecondsSinceEpoch}',
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        // Refresh wallet after successful withdrawal
        await fetchWallet();
        return true;
      } else {
        _error = response.data['message'] ?? 'Withdrawal failed';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      debugPrint('WalletViewModel withdraw error: $e');
      notifyListeners();
      return false;
    } finally {
      _isWithdrawing = false;
      notifyListeners();
    }
  }
}
