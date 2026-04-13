# Plan de Trabajo de Pruebas Unitarias (Backend-vcom + App_Vcom)

## 1. Objetivo
Cubrir con pruebas unitarias todas las funcionalidades activas (incluyendo `Hub`) para detectar regresiones temprano y dejar el proyecto con una base de calidad mantenible.

## 2. Metas de calidad
1. `flutter analyze` y `php artisan test` en verde.
2. Cobertura mínima:
- Backend: 80% en UseCases/Services/Policies.
- Flutter: 75% en `component`, `service`, `model`.
3. Cada bug corregido debe incluir test de regresión.
4. CI bloquea merge si falla lint, tests o cobertura mínima.

## 3. Fase 0 (bloqueante): estabilizar entorno de testing
1. Backend:
- Corregir estrategia de DB de test (evitar fallos por `fullText` en SQLite).
- Opción recomendada: tests unitarios con MySQL de prueba en CI.
- Actualizar factories/tests desalineados (UUID vs integer en `id_model`).
2. Flutter:
- Corregir/retirar tests template obsoletos (counter test).
- Establecer estructura de tests por feature y mocks compartidos.

## 4. Inventario funcional y cobertura mínima por módulo

| Módulo | Backend (unitario) | Flutter (unitario) |
|---|---|---|
| Auth | LoginUseCase, AuthRepository, validaciones, claims JWT | TokenService, login gateway parsing, expiración de sesión |
| Roles/Permisos | Policies, Role/Permission use cases, reglas por rol | PermissionService, gating de módulos visibles |
| Dashboard | Cálculos/transformaciones de datos | `dashboard.component` y `dashboard_modelo.component` |
| Shop (categorías/marcas/productos) | Use cases CRUD, validaciones, mapeo resources | Componentes de estado y parseo de respuestas |
| Events | Reglas de creación/edición, filtros | `events.component` filtros, búsquedas, estado |
| Training/Videos | Reglas de listado/estado | Parsing de videos y estado de pantalla |
| Wallet/Producción | Cálculo de pagos, liquidaciones, deducciones | `wallet.component` agregaciones, filtros, cache |
| Chat | Reglas de autorización y casos de uso activos | servicios chat API/socket y estado UI |
| Hub Tags | creación/listado con permisos admin/monitor | `hub_tags.service` + filtros |
| Hub Posts | creación/listado/paginación/filtros/reacciones | `hub.component` (`initialize`, `refresh`, `loadMore`, `toggleReaction`) |
| Hub Comments | crear/listar paginado (todos autenticados) | `hub.component.addComment/loadComments` |
| Hub Create Post | validación de tag obligatorio + contenido/media | `create_post.component` (`canPublish`, publish, manejo media) |

## 5. Plan de ejecución por semanas

## Semana 1
1. Fase 0 completa (infra de test estable).
2. Backend unit tests de `Auth`, `Roles/Permisos`, `Policies`.
3. Flutter unit tests de `TokenService`, `PermissionService`, login.

## Semana 2
1. Backend unit tests de `Wallet/Producción`, `Events`, `Shop`.
2. Flutter unit tests de `dashboard`, `wallet`, `events`, `shop`.
3. Integrar cobertura en CI y reporte automático.

## Semana 3
1. Backend unit tests completos de `Hub` (tags/posts/comments).
2. Flutter unit tests completos de `Hub` (`hub.component`, services, create post).
3. Hardening: regresiones, refactor de tests duplicados, documentación final.

## 6. Estándar de diseño de test
1. Patrón obligatorio: `Given / When / Then`.
2. Un test = una regla de negocio verificable.
3. Aislar dependencias con mocks/fakes.
4. No usar red real, tiempo real ni storage real en unit tests.
5. Nombres explícitos: `should_<resultado>_when_<condicion>`.

## 7. Criterio de “Done” por funcionalidad
1. Casos felices cubiertos.
2. Casos de error esperados cubiertos.
3. Casos borde cubiertos.
4. Tests pasan en local y CI.
5. Cobertura del módulo alcanza meta.

## 8. Entregables
1. Suite de pruebas unitarias por feature.
2. Reporte de cobertura por módulo.
3. Checklist de calidad por PR:
- `dart format`
- `flutter analyze`
- `flutter test`
- `php artisan test`
- cobertura mínima validada
