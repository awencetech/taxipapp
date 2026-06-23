class NotificationModel {
  final String id;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final Map<String, dynamic>? data;
  final DateTime? createdAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    this.data,
    this.createdAt,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['_id'] ?? map['id'] ?? '',
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      type: map['type'] ?? 'system',
      isRead: map['isRead'] ?? false,
      data: map['data'] != null ? Map<String, dynamic>.from(map['data']) : null,
      createdAt: map['createdAt'] != null ? DateTime.tryParse(map['createdAt']) : null,
    );
  }
}
