class SettingsModel {
  final double baseFare;
  final double pricePerKm;
  final String adminName;
  final String adminEmail;
  final String adminPhone;

  SettingsModel({
    required this.baseFare,
    required this.pricePerKm,
    required this.adminName,
    required this.adminEmail,
    required this.adminPhone,
  });

  factory SettingsModel.fromMap(Map<String, dynamic> map) {
    return SettingsModel(
      baseFare: (map['baseFare'] ?? 0.0).toDouble(),
      pricePerKm: (map['pricePerKm'] ?? 0.0).toDouble(),
      adminName: map['adminName'] ?? '',
      adminEmail: map['adminEmail'] ?? '',
      adminPhone: map['adminPhone'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'baseFare': baseFare,
      'pricePerKm': pricePerKm,
      'adminName': adminName,
      'adminEmail': adminEmail,
      'adminPhone': adminPhone,
    };
  }
}
