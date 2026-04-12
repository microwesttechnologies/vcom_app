# Reglas de Funciones

## Firma y responsabilidad
- MUST tener una sola responsabilidad por funcion.
- MUST declarar tipos de retorno explicitos en APIs publicas.
- MUST usar parametros nombrados cuando haya 3+ parametros o baja claridad.
- MUST usar `required` en parametros obligatorios.

## Complejidad
- MUST mantener complejidad ciclomatica baja (objetivo: <= 10).
- MUST extraer subfunciones cuando hay multiples ramas de negocio.
- MUST NOT mezclar validacion, transformacion y acceso a datos en una sola funcion.

## Errores y contratos
- MUST validar precondiciones al inicio de la funcion.
- MUST fallar de forma controlada con errores de dominio, no excepciones genericas.
- MUST documentar invariantes cuando una funcion dependa de condiciones no obvias.

## Asincronia
- MUST usar `async/await` de forma consistente para legibilidad.
- MUST NOT ignorar `Future` sin razon; usar `unawaited` si es intencional.
- MUST manejar timeout/cancelacion en operaciones remotas largas.

## Ejemplo rapido
```dart
Future<UserProfile> loadUserProfile({required UserId id}) async {
  if (id.value.isEmpty) {
    throw InvalidUserIdError();
  }
  final dto = await _api.fetchUserProfile(id.value);
  return UserProfileMapper.fromDto(dto);
}
```
