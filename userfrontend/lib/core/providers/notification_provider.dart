import 'package:flutter/material.dart';
import '../models/notification_settings_model.dart';
import '../services/api_service.dart';

class NotificationProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  NotificationSettingsModel _settings = NotificationSettingsModel();
  bool _isLoading = false;
  String? _error;

  NotificationSettingsModel get settings => _settings;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchSettings() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.getNotificationSettings();
      if (response.data['success'] == true && response.data['data'] != null) {
        _settings = NotificationSettingsModel.fromMap(response.data['data']);
      }
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateSettings() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.updateNotificationSettings(_settings.toMap());
      if (response.data['success'] == true) {
        return true;
      } else {
        _error = response.data['message'] ?? 'Failed to update settings';
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

  void updateSetting(String key, bool value) {
    switch (key) {
      case 'rideUpdates':
        _settings.rideUpdates = value;
        break;
      case 'promotionalOffers':
        _settings.promotionalOffers = value;
        break;
      case 'walletNotifications':
        _settings.walletNotifications = value;
        break;
      case 'referralNotifications':
        _settings.referralNotifications = value;
        break;
      case 'smsAlerts':
        _settings.smsAlerts = value;
        break;
      case 'emailAlerts':
        _settings.emailAlerts = value;
        break;
      case 'pushNotifications':
        _settings.pushNotifications = value;
        break;
    }
    notifyListeners();
  }
}
