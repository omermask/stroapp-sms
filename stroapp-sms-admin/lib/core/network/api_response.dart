class ApiResponse<T> {
  final bool success;
  final T? data;
  final ApiError? error;
  final ApiMeta? meta;

  ApiResponse({required this.success, this.data, this.error, this.meta});

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromData,
  ) {
    return ApiResponse(
      success: json['success'] as bool? ?? false,
      data: json['data'] != null && fromData != null
          ? fromData(json['data'])
          : json['data'] as T?,
      error: json['error'] != null ? ApiError.fromJson(json['error']) : null,
      meta: json['meta'] != null ? ApiMeta.fromJson(json['meta']) : null,
    );
  }
}

class ApiError {
  final String code;
  final String message;
  final String? errorId;
  final String? requestId;

  ApiError({
    required this.code,
    required this.message,
    this.errorId,
    this.requestId,
  });

  factory ApiError.fromJson(Map<String, dynamic> json) {
    return ApiError(
      code: json['code'] as String? ?? 'UNKNOWN',
      message: json['message'] as String? ?? 'Unknown error',
      errorId: json['error_id'] as String?,
      requestId: json['request_id'] as String?,
    );
  }
}

class ApiMeta {
  final String requestId;
  final String timestamp;

  ApiMeta({required this.requestId, required this.timestamp});

  factory ApiMeta.fromJson(Map<String, dynamic> json) {
    return ApiMeta(
      requestId: json['request_id'] as String? ?? '',
      timestamp: json['timestamp'] as String? ?? '',
    );
  }
}

class PaginatedData<T> {
  final List<T> items;
  final int total;
  final int page;
  final int perPage;
  final int totalPages;

  PaginatedData({
    required this.items,
    required this.total,
    required this.page,
    required this.perPage,
    required this.totalPages,
  });

  factory PaginatedData.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic) fromItem,
  ) {
    return PaginatedData(
      items:
          (json['items'] as List<dynamic>?)?.map((e) => fromItem(e)).toList() ??
          [],
      total: json['total'] as int? ?? 0,
      page: json['page'] as int? ?? 1,
      perPage: json['per_page'] as int? ?? 20,
      totalPages: json['total_pages'] as int? ?? 1,
    );
  }
}
