class PaymentMethodModel {
  final String id;
  final String type; // 'upi', 'card', 'wallet'
  final String? upiId;
  final String? cardNumber;
  final String? cardHolderName;
  final String? expiryDate;
  final String? cvv;
  final String? cardType; // 'credit', 'debit'
  final bool isDefault;
  final bool isActive;

  PaymentMethodModel({
    required this.id,
    required this.type,
    this.upiId,
    this.cardNumber,
    this.cardHolderName,
    this.expiryDate,
    this.cvv,
    this.cardType,
    this.isDefault = false,
    this.isActive = true,
  });

  factory PaymentMethodModel.fromMap(Map<String, dynamic> map) {
    return PaymentMethodModel(
      id: map['_id'] ?? map['id'] ?? '',
      type: map['type'] ?? 'card',
      upiId: map['upiId'],
      cardNumber: map['cardNumber'],
      cardHolderName: map['cardHolderName'],
      expiryDate: map['expiryDate'],
      cvv: map['cvv'],
      cardType: map['cardType'],
      isDefault: map['isDefault'] ?? false,
      isActive: map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'upiId': upiId,
      'cardNumber': cardNumber,
      'cardHolderName': cardHolderName,
      'expiryDate': expiryDate,
      'cvv': cvv,
      'cardType': cardType,
      'isDefault': isDefault,
      'isActive': isActive,
    };
  }

  String get maskedCardNumber {
    if (cardNumber == null || cardNumber!.length < 4) return '';
    return '**** **** **** ${cardNumber!.substring(cardNumber!.length - 4)}';
  }
}
