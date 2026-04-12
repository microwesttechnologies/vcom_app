# Reglas de Datos, Errores y Logging

## Modelo de errores
- MUST clasificar errores: validacion, negocio, infraestructura, desconocido.
- MUST mapear errores tecnicos a mensajes/estados accionables para UI.
- MUST NOT mostrar stack traces al usuario final.

## Logging
- MUST usar logger estructurado con contexto (`feature`, `action`, `requestId`).
- MUST evitar logging de datos sensibles.
- SHOULD usar niveles (`debug`, `info`, `warn`, `error`) consistentes.

## Red y persistencia
- MUST manejar timeout, retry acotado y fallback cuando aplique.
- MUST validar payloads externos antes de mapear al dominio.
- MUST versionar cambios de almacenamiento local cuando rompan compatibilidad.

## Seguridad minima
- MUST NOT guardar secretos en codigo fuente.
- MUST NOT persistir tokens en texto plano.
- MUST sanitizar entradas externas en fronteras del sistema.
