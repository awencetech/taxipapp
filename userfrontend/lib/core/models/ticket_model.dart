class TicketModel {
  final String id;
  final String subject;
  final String description;
  final String status; // 'open', 'in_progress', 'resolved', 'closed'
  final String priority; // 'low', 'medium', 'high', 'urgent'
  final String category;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<TicketMessage> messages;

  TicketModel({
    required this.id,
    required this.subject,
    required this.description,
    this.status = 'open',
    this.priority = 'medium',
    required this.category,
    required this.createdAt,
    this.updatedAt,
    this.messages = const [],
  });

  factory TicketModel.fromMap(Map<String, dynamic> map) {
    return TicketModel(
      id: map['_id'] ?? map['id'] ?? '',
      subject: map['subject'] ?? '',
      description: map['description'] ?? '',
      status: map['status'] ?? 'open',
      priority: map['priority'] ?? 'medium',
      category: map['category'] ?? '',
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : DateTime.now(),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
      messages: (map['messages'] as List<dynamic>?)
              ?.map((e) => TicketMessage.fromMap(e))
              .toList() ??
          const [],
    );
  }
}

class TicketMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String message;
  final DateTime timestamp;
  final bool isUser;

  TicketMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.timestamp,
    this.isUser = true,
  });

  factory TicketMessage.fromMap(Map<String, dynamic> map) {
    return TicketMessage(
      id: map['_id'] ?? map['id'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      message: map['message'] ?? '',
      timestamp: map['timestamp'] != null ? DateTime.parse(map['timestamp']) : DateTime.now(),
      isUser: map['isUser'] ?? true,
    );
  }
}
