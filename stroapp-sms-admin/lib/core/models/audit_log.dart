class AuditLog {
  final String id;
  final String? userId;
  final String action;
  final String? resourceType;
  final String? resourceId;
  final Map<String, dynamic>? details;
  final String? ipAddress;
  final String createdAt;

  AuditLog({
    required this.id,
    this.userId,
    required this.action,
    this.resourceType,
    this.resourceId,
    this.details,
    this.ipAddress,
    required this.createdAt,
  });

  factory AuditLog.fromJson(Map<String, dynamic> json) {
    return AuditLog(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String?,
      action: json['action'] as String? ?? '',
      resourceType: json['resource_type'] as String?,
      resourceId: json['resource_id'] as String?,
      details: json['details'] as Map<String, dynamic>?,
      ipAddress: json['ip_address'] as String?,
      createdAt: json['created_at'] as String? ?? '',
    );
  }
}
