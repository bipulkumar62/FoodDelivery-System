class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  ApiException({
    required this.message,
    this.statusCode,
    this.data,
  });

  @override
  String toString() => 'ApiException($statusCode): $message';

  factory ApiException.fromStatusCode(int code, [dynamic data]) {
    switch (code) {
      case 400:
        return ApiException(message: 'Bad request', statusCode: code, data: data);
      case 404:
        return ApiException(message: 'Not found', statusCode: code, data: data);
      case 409:
        return ApiException(message: 'Conflict', statusCode: code, data: data);
      case 500:
        return ApiException(message: 'Server error', statusCode: code, data: data);
      default:
        return ApiException(message: 'Request failed', statusCode: code, data: data);
    }
  }
}
