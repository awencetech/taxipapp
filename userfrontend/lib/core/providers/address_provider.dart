import 'package:flutter/material.dart';
import '../models/address_model.dart';
import '../services/api_service.dart';

class AddressProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<AddressModel> _addresses = [];
  bool _isLoading = false;
  String? _error;

  List<AddressModel> get addresses => _addresses;
  bool get isLoading => _isLoading;
  String? get error => _error;

  AddressModel? get defaultAddress {
    try {
      return _addresses.firstWhere((a) => a.isDefault);
    } catch (e) {
      return null;
    }
  }

  Future<void> fetchAddresses() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.getAddresses();
      if (response.data['success'] == true && response.data['data'] != null) {
        _addresses = (response.data['data'] as List)
            .map((e) => AddressModel.fromMap(e))
            .toList();
      }
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addAddress(AddressModel address) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.addAddress(address.toMap());
      if (response.data['success'] == true) {
        await fetchAddresses();
        return true;
      } else {
        _error = response.data['message'] ?? 'Failed to add address';
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

  Future<bool> updateAddress(AddressModel address) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.updateAddress(address.id, address.toMap());
      if (response.data['success'] == true) {
        await fetchAddresses();
        return true;
      } else {
        _error = response.data['message'] ?? 'Failed to update address';
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

  Future<bool> deleteAddress(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.deleteAddress(id);
      if (response.data['success'] == true) {
        await fetchAddresses();
        return true;
      } else {
        _error = response.data['message'] ?? 'Failed to delete address';
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

  Future<bool> setDefaultAddress(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.setDefaultAddress(id);
      if (response.data['success'] == true) {
        await fetchAddresses();
        return true;
      } else {
        _error = response.data['message'] ?? 'Failed to set default address';
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
