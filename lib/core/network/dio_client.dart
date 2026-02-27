import 'package:dio/dio.dart';
import '../constants/app_constants.dart';
import '../errors/app_exception.dart';

class DioClient {
  DioClient._() : _dio = _buildDio();

  static final DioClient instance = DioClient._();
  final Dio _dio;

  static Dio _buildDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'apikey': AppConstants.apiKey,
          'Content-Type': 'application/json',
        },
      ),
    );

    dio.interceptors.add(_LoggingInterceptor());
    return dio;
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParams}) async {
    try {
      return await _dio.get(path, queryParameters: queryParams);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  AppException _mapDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
        return const NetworkException();
      case DioExceptionType.badResponse:
        return ServerException(
          statusCode: e.response?.statusCode,
          message: _parseErrorMessage(e.response) ?? 'Server error occurred.',
        );
      default:
        return const ServerException();
    }
  }

  String? _parseErrorMessage(Response? response) {
    try {
      final data = response?.data;
      if (data is Map) return data['message']?.toString();
      return null;
    } catch (_) {
      return null;
    }
  }
}

class _LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Uncomment for debugging
    // debugPrint('[API] ${options.method} ${options.path}');
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // debugPrint('[API] Error ${err.response?.statusCode}: ${err.message}');
    handler.next(err);
  }
}
