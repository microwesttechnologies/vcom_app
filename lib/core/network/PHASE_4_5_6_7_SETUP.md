// PHASE 4: Configurar cliente HTTP con Dio

// FASE 4: Frontend Network Layer
// Ubicación: lib/core/network/dio_instance.dart
// 
// Este archivo configura la instancia de Dio con:
// - Base URL
// - Interceptors (token, errores)
// - Timeouts
// - Headers

// TODO en esta fase:
// 1. Instalar dependency: flutter pub add dio
// 2. Crear archivo dio_instance.dart
// 3. Configurar base URL desde .env o config
// 4. Agregar TokenInterceptor
// 5. Agregar ErrorInterceptor
// 6. Configurar timeouts

// Modelo esperado:

/*
import 'package:dio/dio.dart';
import 'token_interceptor.dart';
import 'error_interceptor.dart';

class DioInstance {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://api.vcom.local/api',
      connectTimeout: Duration(seconds: 10),
      receiveTimeout: Duration(seconds: 10),
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
}
*/

// FASE 5: Modelado de Datos
// Ubicación: lib/features/hub/data/models/
//
// Crear modelos con:
// - fromJson constructor
// - toJson method
// - Equatable para comparación
// - Freezed (opcional)

/*
post_model.dart
comment_model.dart
user_model.dart
reaction_model.dart
api_response_model.dart
*/

// FASE 6: Data Access Layer
// Ubicación: lib/features/hub/data/datasources/

/*
hub_remote_datasource.dart → Consumir API HTTP
*/

// FASE 7: State Management
// Ubicación: lib/features/hub/presentation/providers/

/*
hub_posts_provider.dart (Riverpod)
hub_post_detail_provider.dart
hub_mutation_provider.dart (create/update/delete)
*/

void setupPhase4() {
  print('''
  ╔════════════════════════════════════════════════════════╗
  ║ FASE 4 — Frontend Network Layer (PHASE 4)             ║
  ╠════════════════════════════════════════════════════════╣
  ║                                                        ║
  ║ 1. Crear: lib/core/network/dio_instance.dart          ║
  ║    - Configurar Dio con base URL                      ║
  ║                                                        ║
  ║ 2. Crear: lib/core/network/interceptors/              ║
  ║    - token_interceptor.dart                           ║
  ║    - error_interceptor.dart                           ║
  ║                                                        ║
  ║ 3. Crear: lib/core/network/models/                    ║
  ║    - api_response.dart                                ║
  ║                                                        ║
  ║ Criterios de éxito:                                   ║
  ║ ✓ Request lleva token automáticamente                 ║
  ║ ✓ Errores normalizados                                ║
  ║ ✓ Manejo de reconexión                                ║
  ║                                                        ║
  ╚════════════════════════════════════════════════════════╝
  ''');
}
