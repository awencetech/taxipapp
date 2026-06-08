class NotificationSettingsModel {
  bool rideUpdates;
  bool promotionalOffers;
  bool walletNotifications;
  bool referralNotifications;
  bool smsAlerts;
  bool emailAlerts;
  bool pushNotifications;

  NotificationSettingsModel({
    this.rideUpdates = true,
    this.promotionalOffers = true,
    this.walletNotifications = true,
    this.referralNotifications = true,
    this.smsAlerts = true,
    this.emailAlerts = true,
    this.pushNotifications = true,
  });

  factory NotificationSettingsModel.fromMap(Map<String, dynamic> map) {
    return NotificationSettingsModel(
      rideUpdates: map['rideUpdates'] ?? true,
      promotionalOffers: map['promotionalOffers'] ?? true,
      walletNotifications: map['walletNotifications'] ?? true,
      referralNotifications: map['referralNotifications'] ?? true,
      smsAlerts: map['smsAlerts'] ?? true,
      emailAlerts: map['emailAlerts'] ?? true,
      pushNotifications: map['pushNotifications'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'rideUpdates': rideUpdates,
      'promotionalOffers': promotionalOffers,
      'walletNotifications': walletNotifications,
      'referralNotifications': referralNotifications,
      'smsAlerts': smsAlerts,
      'emailAlerts': emailAlerts,
      'pushNotifications': pushNotifications,
    };
  }
}
