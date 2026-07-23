import 'package:dio/dio.dart';
import 'api_exception.dart';

class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout) {
      return handler.reject(
        DioException(
          requestOptions: err.requestOptions,
          error: ApiException(message: 'Connection timeout'),
          type: err.type,
        ),
      );
    }

    if (err.type == DioExceptionType.connectionError) {
      return handler.reject(
        DioException(
          requestOptions: err.requestOptions,
          error: ApiException(message: 'No internet connection'),
          type: err.type,
        ),
      );
    }

    if (err.response != null) {
      final statusCode = err.response!.statusCode ?? 0;
      final data = err.response!.data;
      final message = data is Map ? data['message'] as String? : null;
      return handler.reject(
        DioException(
          requestOptions: err.requestOptions,
          error: ApiException(
            message: message ?? 'Request failed',
            statusCode: statusCode,
            data: data,
          ),
          response: err.response,
          type: err.type,
        ),
      );
    }

    handler.next(err);
  }
}
