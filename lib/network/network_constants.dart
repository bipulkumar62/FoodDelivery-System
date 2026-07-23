class NetworkConstants {
  static const String baseUrl = 'http://localhost:4000/api/v1';
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 10);
  static const int maxRetries = 2;
}
