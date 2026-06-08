import 'package:flutter/material.dart';
import '../models/payment_method_model.dart';
import '../services/api_service.dart';

class PaymentProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<PaymentMethodModel> _paymentMethods = [];
  bool _isLoading = false;
  String? _error;

  List<PaymentMethodModel> get paymentMethods => _paymentMethods;
  bool get isLoading => _isLoading;
  String? get error => _error;

  PaymentMethodModel? get defaultPaymentMethod {
    try {
      return _paymentMethods.firstWhere((p) => p.isDefault);
    } catch (e) {
      return null;
    }
  }

  Future<void> fetchPaymentMethods() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.getUserPayments();
      if (response.data['success'] == true && response.data['data'] != null) {
        _paymentMethods = (response.data['data'] as List)
            .map((e) => PaymentMethodModel.fromMap(e))
            .toList();
      }
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addPaymentMethod(PaymentMethodModel method) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.addPaymentMethod(method.toMap());
      if (response.data['success'] == true) {
        await fetchPaymentMethods();
        return true;
      } else {
        _error = response.data['message'] ?? 'Failed to add payment method';
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

  Future<bool> deletePaymentMethod(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.deletePaymentMethod(id);
      if (response.data['success'] == true) {
        await fetchPaymentMethods();
        return true;
      } else {
        _error = response.data['message'] ?? 'Failed to delete payment method';
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

  Future<bool> setDefaultPaymentMethod(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.setDefaultPaymentMethod(id);
      if (response.data['success'] == true) {
        await fetchPaymentMethods();
        return true;
      } else {
        _error = response.data['message'] ?? 'Failed to set default payment method';
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
}
