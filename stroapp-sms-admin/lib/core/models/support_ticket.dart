class TicketReply {
  final String id;
  final String userId;
  final String message;
  final bool isAdmin;
  final String? createdAt;

  TicketReply({
    required this.id,
    required this.userId,
    required this.message,
    required this.isAdmin,
    this.createdAt,
  });

  factory TicketReply.fromJson(Map<String, dynamic> json) {
    return TicketReply(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      message: json['message'] as String? ?? '',
      isAdmin: json['is_admin'] as bool? ?? false,
      createdAt: json['created_at'] as String?,
    );
  }
}

class SupportTicket {
  final String id;
  final String userId;
  final String subject;
  final String message;
  final String category;
  final String priority;
  final String status;
  final String? assignedTo;
  final String? createdAt;
  final String? updatedAt;
  final List<TicketReply> replies;

  SupportTicket({
    required this.id,
    required this.userId,
    required this.subject,
    required this.message,
    required this.category,
    required this.priority,
    required this.status,
    this.assignedTo,
    this.createdAt,
    this.updatedAt,
    this.replies = const [],
  });

  factory SupportTicket.fromJson(Map<String, dynamic> json) {
    return SupportTicket(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      subject: json['subject'] as String? ?? '',
      message: json['message'] as String? ?? '',
      category: json['category'] as String? ?? '',
      priority: json['priority'] as String? ?? '',
      status: json['status'] as String? ?? 'open',
      assignedTo: json['assigned_to'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      replies: (json['replies'] as List<dynamic>?)
              ?.map((e) => TicketReply.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  String get shortId => id.length >= 8 ? id.substring(0, 8) : id;
}
