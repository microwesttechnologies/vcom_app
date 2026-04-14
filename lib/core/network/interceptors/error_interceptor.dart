import 'package:dio/dio.dart';

/// Interceptor que maneja errores globales
///
/// Responsabilidades:
/// - Mapear excepciones Dio a AppException
/// - Manejar 401 (token expirado)
/// - Manejar 403 (sin permisos)
/// - Manejar 404 (recurso no existe)
/// - Manejar 422 (validación fallida)
/// - Manejar 500 (error servidor)
class ErrorInterceptor extends Interceptor {
  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Mapear error Dio a AppException
    _mapDioException(err);

    // Aquí se pueden agregar lógicas globales, ej:
    // - Mostrar snackbar al usuario
    // - Registrar en sistema de logs
    // - Redirigir a login si 401

    // Propagar el error
    return handler.next(err);
  }

  /// Mapear excepciones Dio a formato estándar
  AppException _mapDioException(DioException dioError) {
    switch (dioError.type) {
      case DioExceptionType.connectionTimeout:
        return AppException(
          message: 'Connection timeout',
          code: 'TIMEOUT',
          statusCode: 408,
        );

      case DioExceptionType.sendTimeout:
        return AppException(
          message: 'Send timeout',
          code: 'SEND_TIMEOUT',
          statusCode: 408,
        );

      case DioExceptionType.receiveTimeout:
        return AppException(
          message: 'Receive timeout',
          code: 'RECEIVE_TIMEOUT',
          statusCode: 408,
        );

      case DioExceptionType.badResponse:
        final statusCode = dioError.response?.statusCode ?? 500;
        final data = dioError.response?.data;
        final message = data?['message'] ?? 'Error';

        switch (statusCode) {
          case 400:
            return AppException(
              message: message,
              code: 'BAD_REQUEST',
              statusCode: 400,
            );
          case 401:
            return AppException(
              message: 'Sesión expirada o no autorizado',
              code: 'UNAUTHORIZED',
              statusCode: 401,
            );
          case 403:
            return AppException(
              message: 'No tienes permisos para esta acción',
              code: 'FORBIDDEN',
              statusCode: 403,
            );
          case 404:
            return AppException(
              message: 'Recurso no encontrado',
              code: 'NOT_FOUND',
              statusCode: 404,
            );
          case 422:
            return AppException(
              message: 'Validación fallida',
              code: 'VALIDATION_ERROR',
              statusCode: 422,
              errors: data?['errors'],
            );
          case 500:
            return AppException(
              message: 'Error del servidor',
              code: 'SERVER_ERROR',
              statusCode: 500,
            );
          default:
            return AppException(
              message: message,
              code: 'UNKNOWN_ERROR',
              statusCode: statusCode,
            );
        }

      case DioExceptionType.cancel:
        return AppException(
          message: 'Request cancelado',
          code: 'REQUEST_CANCELLED',
          statusCode: 0,
        );

      case DioExceptionType.unknown:
        return AppException(
          message: dioError.message ?? 'Error desconocido',
          code: 'UNKNOWN_ERROR',
          statusCode: 0,
        );

      default:
        return AppException(
          message: 'Error inesperado',
          code: 'UNEXPECTED_ERROR',
          statusCode: 0,
        );
    }
  }
}

/// Clase para encapsular excepciones de la app
class AppException implements Exception {
  final String message;
  final String code;
  final int statusCode;
  final dynamic errors;

  AppException({
    required this.message,
    required this.code,
    required this.statusCode,
    this.errors,
  });

  @override
  String toString() =>
      'AppException(code: $code, statusCode: $statusCode, message: $message)';
}
