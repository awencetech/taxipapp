class PaymentModel {
  final String id;
  final String userId;
  final String? userName;
  final double amount;
  final String paymentMethod;
  final String status;
  final String? transactionId;
  final DateTime? createdAt;

  PaymentModel({
    required this.id,
    required this.userId,
    this.userName,
    required this.amount,
    required this.paymentMethod,
    required this.status,
    this.transactionId,
    this.createdAt,
  });

  factory PaymentModel.fromMap(Map<String, dynamic> map) {
    return PaymentModel(
      id: map['_id'] ?? map['id'] ?? '',
      userId: map['user'] is Map ? map['user']['_id'] : (map['user'] ?? ''),
      userName: map['user'] is Map ? map['user']['name'] : null,
      amount: (map['amount'] ?? 0.0).toDouble(),
      paymentMethod: map['paymentMethod'] ?? 'cash',
      status: map['status'] ?? 'pending',
      transactionId: map['transactionId'],
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : null,
    );
  }
}
