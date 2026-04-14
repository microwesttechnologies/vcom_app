/// Modelo genérico para envolver respuestas del API
///
/// Todas las respuestas del backend siguen este formato:
/// {
///   "status": "success|error",
///   "data": {...} o [...],
///   "message": "opcional",
///   "meta": {"pagination": {...}}
/// }
class ApiResponse<T> {
  final String status;
  final T? data;
  final String? message;
  final Map<String, dynamic>? meta;

  ApiResponse({required this.status, this.data, this.message, this.meta});

  /// Verificar si es exitosa (status == 'success')
  bool get isSuccess => status == 'success';

  /// Verificar si es error (status == 'error')
  bool get isError => status == 'error';

  /// Factory para parsear JSON del backend
  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? dataParser,
  ) {
    return ApiResponse(
      status: json['status'] as String,
      data: json['data'] != null && dataParser != null
          ? dataParser(json['data'])
          : null,
      message: json['message'] as String?,
      meta: json['meta'] as Map<String, dynamic>?,
    );
  }

  /// Convertir a JSON
  Map<String, dynamic> toJson() {
    return {'status': status, 'data': data, 'message': message, 'meta': meta};
  }
}
