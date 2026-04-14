import 'package:dio/dio.dart';
import 'package:vcom_app/core/common/envirotment.dev.dart';

import 'interceptors/error_interceptor.dart';
import 'interceptors/token_interceptor.dart';

/// Configuracion global de Dio para consumir API.
class DioInstance {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: EnvironmentDev.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 10),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  );

  static Dio getInstance() {
    _dio.interceptors.clear();
    _dio.interceptors.add(TokenInterceptor());
    _dio.interceptors.add(ErrorInterceptor());
    return _dio;
  }

  static void setBaseUrl(String baseUrl) {
    _dio.options.baseUrl = baseUrl;
  }
}
