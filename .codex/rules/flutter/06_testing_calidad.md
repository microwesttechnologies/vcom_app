# Reglas de Testing y Calidad

## Cobertura por tipo
- MUST escribir unit tests para reglas de dominio y transformaciones.
- MUST escribir widget tests para estados de UI criticos.
- MUST escribir integration tests para flujos de negocio clave.

## Criterio de test
- MUST cubrir caso feliz, error esperado y borde relevante.
- MUST hacer tests deterministas (sin dependencias de red real o tiempo real).
- MUST usar dobles (mocks/fakes) en limites de infraestructura.

## Calidad automatizada
- MUST ejecutar `dart format`.
- MUST ejecutar `flutter analyze`.
- MUST ejecutar `flutter test`.
- MUST mantener el proyecto en estado `0 warnings, 0 info, 0 errors` en analyzer.
- MUST NOT fusionar cambios con checks en rojo.

## Regresiones
- MUST agregar test cuando se corrige bug para evitar reintroduccion.
- SHOULD agregar test de snapshot visual solo en componentes estables.
