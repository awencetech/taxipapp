class ReferralModel {
  final String referralCode;
  final int totalReferrals;
  final double totalEarnings;
  final List<ReferralHistoryItem> history;

  ReferralModel({
    required this.referralCode,
    this.totalReferrals = 0,
    this.totalEarnings = 0.0,
    this.history = const [],
  });

  factory ReferralModel.fromMap(Map<String, dynamic> map) {
    return ReferralModel(
      referralCode: map['referralCode'] ?? '',
      totalReferrals: map['totalReferrals'] ?? 0,
      totalEarnings: (map['totalEarnings'] is num) ? (map['totalEarnings'] as num).toDouble() : 0.0,
      history: (map['history'] as List<dynamic>?)
              ?.map((e) => ReferralHistoryItem.fromMap(e))
              .toList() ??
          const [],
    );
  }
}

class ReferralHistoryItem {
  final String id;
  final String referredUserName;
  final double earnings;
  final DateTime date;
  final String status;

  ReferralHistoryItem({
    required this.id,
    required this.referredUserName,
    required this.earnings,
    required this.date,
    required this.status,
  });

  factory ReferralHistoryItem.fromMap(Map<String, dynamic> map) {
    return ReferralHistoryItem(
      id: map['_id'] ?? map['id'] ?? '',
      referredUserName: map['referredUserName'] ?? '',
      earnings: (map['earnings'] is num) ? (map['earnings'] as num).toDouble() : 0.0,
      date: map['date'] != null ? DateTime.parse(map['date']) : DateTime.now(),
      status: map['status'] ?? 'pending',
    );
  }
}
