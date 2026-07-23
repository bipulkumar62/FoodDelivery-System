class ApiResponse<T> {
  final bool success;
  final String? message;
  final int? count;
  final T? data;

  ApiResponse({
    required this.success,
    this.message,
    this.count,
    this.data,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? parser,
  ) {
    return ApiResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String?,
      count: json['count'] as int?,
      data: json['data'] != null && parser != null ? parser(json['data']) : null,
    );
  }
}
