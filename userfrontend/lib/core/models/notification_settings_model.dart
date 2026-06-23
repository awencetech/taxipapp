class NotificationSettingsModel {
  bool rideUpdates;
  bool walletNotifications;
  bool smsAlerts;

  NotificationSettingsModel({
    this.rideUpdates = true,
    this.walletNotifications = true,
    this.smsAlerts = true,
  });

  factory NotificationSettingsModel.fromMap(Map<String, dynamic> map) {
    return NotificationSettingsModel(
      rideUpdates: map['rideUpdates'] ?? true,
      walletNotifications: map['walletNotifications'] ?? true,
      smsAlerts: map['smsAlerts'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'rideUpdates': rideUpdates,
      'walletNotifications': walletNotifications,
      'smsAlerts': smsAlerts,
    };
  }
}
