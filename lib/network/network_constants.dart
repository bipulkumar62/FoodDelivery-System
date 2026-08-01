class NetworkConstants {
  /// Override for local testing, e.g.:
  ///   flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:4000/api/v1
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://pawan-backend-2.onrender.com/api/v1',
  );
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
  static const int maxRetries = 3;
}
