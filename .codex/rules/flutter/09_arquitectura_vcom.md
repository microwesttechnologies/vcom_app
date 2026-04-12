# Reglas de Arquitectura VCOM (Especificas del Proyecto)

Objetivo: estandarizar como crecen los modulos en `lib/` sin romper mantenibilidad.

## 1) Estructura oficial del proyecto
- MUST mantener esta responsabilidad por directorio:
  - `lib/pages`: pantallas y controladores de presentacion.
  - `lib/components`: widgets reutilizables transversales.
  - `lib/core`: servicios de infraestructura, modelos, gateways, utilidades de sesion/autenticacion.
  - `lib/style`: tema, paleta y tokens visuales.
- MUST crear nuevos features dentro de `lib/pages/<feature>/`.
- MUST NOT poner widgets de pantalla en `lib/components`.

## 2) Convencion de archivos por feature
Para cada feature en `lib/pages/<feature>/`:
- MUST usar `<feature>.page.dart` para la pantalla.
- MUST usar `<feature>.component.dart` para estado y logica de presentacion.
- SHOULD usar archivos adicionales por subpantalla (`<subfeature>.page.dart`) cuando el flujo crece.
- MUST NOT mezclar en un mismo archivo clases de UI y clases de acceso a datos.

## 3) Contrato `.page.dart` (capa UI)
- MUST encargarse solo de:
  - render,
  - eventos de UI,
  - navegacion,
  - ciclo de vida visual.
- MUST delegar reglas de negocio al `.component.dart`.
- MUST NOT llamar APIs HTTP, storage, sockets o plugins directamente.
- MUST NOT construir JSON, mapear DTOs o aplicar reglas de dominio.

## 4) Contrato `.component.dart` (presentacion)
- MUST centralizar estado observable de la pantalla (por ejemplo `ChangeNotifier`).
- MUST exponer metodos de intencion (`loadData`, `submitForm`, `refresh`).
- MUST depender de servicios/gateways de `lib/core` para IO.
- MUST devolver errores de forma controlada para que la UI decida como mostrarlos.
- MUST liberar recursos (`dispose`) de controllers/listeners/timers.

## 5) Contrato `lib/core`
- MUST separar infraestructura por area (`auth`, `chat`, `common`, `models`, etc.).
- MUST ubicar acceso remoto/local en `*.service.dart` o `*.gateway.dart`.
- MUST mantener modelos de datos en `core/models`.
- MUST mapear respuestas externas a modelos internos antes de entregarlas a presentacion.
- MUST NOT importar archivos de `lib/pages` dentro de `lib/core`.

## 6) Matriz de dependencias permitidas
- `pages` -> puede importar `components`, `core`, `style`.
- `components` -> puede importar `core`, `style`.
- `core` -> NO puede importar `pages` ni `components`.
- `style` -> NO puede importar `pages` ni `components` ni `core`.

Regla global:
- MUST mantener direccion de dependencia desde UI hacia infraestructura, nunca al reves.

## 7) Navegacion
- MUST declarar rutas principales de app en un punto central (`main.dart` o router dedicado).
- SHOULD mover rutas a `AppRouter` cuando el numero de pantallas crezca.
- MUST NOT duplicar nombres de rutas hardcodeadas en multiples archivos sin constante compartida.

## 8) Estado de sesion y servicios globales
- MUST encapsular estado global (token, sesion, presencia, push) en `lib/core/common`.
- MUST inicializar servicios globales una sola vez en bootstrap.
- MUST evitar inicializaciones redundantes dispersas por multiples pantallas.
- SHOULD envolver servicios globales con interfaces para facilitar pruebas.

## 9) Reglas de escalamiento por feature nueva
Cuando se cree una feature nueva:
1. MUST crear carpeta `lib/pages/<feature>/`.
2. MUST crear `feature.page.dart` y `feature.component.dart`.
3. MUST crear/usar servicios en `lib/core/<feature>/` para IO.
4. MUST definir modelo(s) en `lib/core/models` si hay entidades nuevas.
5. MUST agregar pruebas minimas de componente y flujo principal.

## 10) Anti-patrones prohibidos
- MUST NOT hacer `setState` para estado de negocio que vive en componente.
- MUST NOT llamar `TokenService`, `LoginService`, `ChatApiService` directo desde widgets reutilizables de `lib/components`.
- MUST NOT compartir mutable state entre features por variables globales sueltas.
- MUST NOT acoplar una feature con otra mediante imports directos de componentes internos.

## 11) Checklist arquitectonico para PR
- [ ] La UI no contiene logica de negocio.
- [ ] No hay acceso a red/storage/plugins desde `.page.dart`.
- [ ] `core` no importa `pages` ni `components`.
- [ ] Recursos con ciclo de vida se liberan en `dispose`.
- [ ] Dependencias nuevas estan justificadas y encapsuladas.
