import 'package:dio/dio.dart';
import 'network_constants.dart';
import 'api_exception.dart';
import 'logging_interceptor.dart';
import 'error_interceptor.dart';
import 'retry_interceptor.dart';

class ApiClient {
  late final Dio _dio;

  ApiClient._();

  static final ApiClient _instance = ApiClient._();
  static ApiClient get instance => _instance;

  void init() {
    _dio = Dio(
      BaseOptions(
        baseUrl: NetworkConstants.baseUrl,
        connectTimeout: NetworkConstants.connectTimeout,
        receiveTimeout: NetworkConstants.receiveTimeout,
        headers: {'Content-Type': 'application/json'},
      ),
    );

    _dio.interceptors.addAll([
      LoggingInterceptor(),
      ErrorInterceptor(),
      RetryInterceptor(dio: _dio, maxRetries: NetworkConstants.maxRetries),
    ]);
  }

  void setToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  void clearToken() {
    _dio.options.headers.remove('Authorization');
  }

  /// Whether an admin/customer auth header is currently attached.
  /// Used for diagnostics only; never exposes the token value.
  bool get hasAuthToken => _dio.options.headers['Authorization'] != null;

  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParameters);
      return response.data;
    } on DioException catch (e) {
      throw e.error ?? ApiException(message: 'Request failed');
    }
  }

  Future<Map<String, dynamic>> post(
    String path, {
    dynamic data,
  }) async {
    try {
      final response = await _dio.post(path, data: data);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw e.error ?? ApiException(message: 'Request failed');
    }
  }

  Future<Map<String, dynamic>> patch(
    String path, {
    dynamic data,
  }) async {
    try {
      final response = await _dio.patch(path, data: data);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw e.error ?? ApiException(message: 'Request failed');
    }
  }

  Future<Map<String, dynamic>> delete(String path) async {
    try {
      final response = await _dio.delete(path);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw e.error ?? ApiException(message: 'Request failed');
    }
  }
}
