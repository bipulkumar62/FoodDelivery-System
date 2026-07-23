import 'package:dio/dio.dart';

class RetryInterceptor extends Interceptor {
  final Dio dio;
  final int maxRetries;

  RetryInterceptor({required this.dio, this.maxRetries = 2});

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (_shouldRetry(err) && (err.requestOptions.extra['retryCount'] ?? 0) < maxRetries) {
      final retryCount = (err.requestOptions.extra['retryCount'] as int? ?? 0) + 1;
      err.requestOptions.extra['retryCount'] = retryCount;
      dio.fetch(err.requestOptions).then(
        (response) => handler.resolve(response),
        onError: (e) => handler.next(err),
      );
      return;
    }
    handler.next(err);
  }

  bool _shouldRetry(DioException err) {
    return err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError;
  }
}
