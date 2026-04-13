# Plan de Trabajo Optimizado - Modulo Hub (VCOM)

## 1. Objetivo
Implementar el modulo social tipo Facebook bajo el nombre `Hub` en App VCOM, con backend Laravel + MySQL y frontend Flutter, incluyendo:
- Feed paginado con lazy load (10 por pagina)
- Posts con texto, imagenes, videos, o combinacion
- Tags obligatorios por post
- Comentarios paginados
- UI fiel al diseno de referencia
- Alto rendimiento y escalabilidad

## 2. Ajustes estrategicos basados en el estado actual del proyecto
1. Mantener autenticacion actual y no introducir una tabla `users` nueva para este modulo.
2. Resolver identidad social con `author_type` + `author_id` para soportar usuarios de tablas existentes.
3. Ejecutar una fase de saneamiento previo: permisos y endpoint de perfil (`/auth/me`) antes de integrar Hub en App.
4. Aislar modulo en API con prefijo dedicado para evitar acoplamiento con modulos actuales.
5. Implementar Hub en App como feature separada sin romper arquitectura existente.

## 3. Reglas de negocio y permisos
| Accion | admin | monitor | modelo | otros autenticados |
|---|---|---|---|---|
| Crear tag | SI | SI | NO | NO |
| Ver tags | SI | SI | SI | SI |
| Crear post | SI | SI | NO | NO |
| Ver feed | SI | SI | SI | SI |
| Comentar | SI | SI | SI | SI |

Reglas obligatorias:
1. Todo post debe tener exactamente 1 tag.
2. Un post debe tener al menos `content` o al menos 1 media.
3. Comentarios siempre ligados a post y autor autenticado.

## 4. Modelo de datos (MySQL)
### 4.1 Tablas
1. `hub_tags`
- `id`, `name`, `slug`, `description`, `created_by_type`, `created_by_id`, `is_active`, timestamps
2. `hub_posts`
- `id`, `author_type`, `author_id`, `tag_id`, `content`, `comments_count`, `media_count`, timestamps, soft delete
3. `hub_post_media`
- `id`, `post_id`, `type` (`image`|`video`), `file_url`, `thumbnail_url`, `mime_type`, `file_size`, `duration`, `sort_order`, timestamps
4. `hub_comments`
- `id`, `post_id`, `author_type`, `author_id`, `content`, timestamps, soft delete

### 4.2 Indices obligatorios
1. `hub_posts(tag_id, created_at desc, id desc)`
2. `hub_posts(author_type, author_id, created_at desc)`
3. `hub_comments(post_id, created_at asc, id asc)`
4. `hub_post_media(post_id, sort_order)`
5. `hub_tags(slug)` unico

## 5. API Backend (Laravel)
Prefijo recomendado: `/api/v1/hub`

### 5.1 Tags
1. `GET /api/v1/hub/tags`
2. `POST /api/v1/hub/tags` (solo admin/monitor)
3. `GET /api/v1/hub/tags/{id}/posts?page=1&per_page=10`

### 5.2 Posts
1. `GET /api/v1/hub/posts?page=1&per_page=10`
2. `GET /api/v1/hub/posts/{id}`
3. `POST /api/v1/hub/posts` (solo admin/monitor)
4. `DELETE /api/v1/hub/posts/{id}` (policy)

### 5.3 Comments
1. `GET /api/v1/hub/posts/{id}/comments?page=1&per_page=10`
2. `POST /api/v1/hub/posts/{id}/comments` (todos autenticados)

### 5.4 Contrato feed estable
```json
{
  "data": [
    {
      "id": 1,
      "author": {
        "id": "123",
        "type": "employee",
        "name": "User",
        "role": "monitor"
      },
      "tag": {
        "id": 2,
        "name": "Tecnologia"
      },
      "content": "Texto",
      "media": [],
      "comments_count": 5,
      "created_at": "2026-04-13T12:00:00Z"
    }
  ],
  "meta": {
    "current_page": 1,
    "per_page": 10,
    "has_more": true
  }
}
```

## 6. Cumplimiento obligatorio de reglas Flutter (`.codex/rules/flutter`)
Este plan adopta de forma explicita los `MUST` del ruleset:

### 6.1 Arquitectura por capas
1. `presentation -> domain -> data` obligatorio.
2. Widgets no importan `data` directamente.
3. Regla de negocio en dominio/componente, no en `build()`.

### 6.2 Estructura VCOM del modulo Hub
1. `lib/pages/hub/hub.page.dart` (UI y navegacion)
2. `lib/pages/hub/hub.component.dart` (estado y orquestacion)
3. `lib/pages/hub/create_post.page.dart`
4. `lib/pages/hub/create_post.component.dart`
5. `lib/core/hub/hub_posts.service.dart` o `*.gateway.dart`
6. `lib/core/hub/hub_comments.service.dart`
7. `lib/core/hub/hub_tags.service.dart`
8. `lib/core/models/hub_post.model.dart`, `hub_comment.model.dart`, `hub_tag.model.dart`

### 6.3 Contratos `.page.dart` y `.component.dart`
1. `.page.dart` NO llama HTTP/storage/socket directamente.
2. `.component.dart` expone intenciones (`loadFeed`, `loadMore`, `createPost`, `loadComments`, `addComment`).
3. Estado inmutable con tipos claros: `loading`, `success`, `error`.
4. Recursos con ciclo de vida liberados en `dispose`.

### 6.4 SOLID y DI
1. Inyeccion por constructor/provider para servicios de Hub.
2. Evitar clases monoliticas en feature Hub.
3. Separar interfaces pequenas por caso de uso (feed, tags, comments, media upload).

### 6.5 Performance Flutter
1. Feed y comentarios con `ListView.builder`.
2. Evitar rebuild global; separar subwidgets (`PostCard`, `MediaViewer`, `CommentList`).
3. Lock de paginacion para impedir requests duplicados.
4. Medicion antes/despues en flujos criticos.

### 6.6 Testing y DoD Flutter
1. Ejecutar `dart format`, `flutter analyze`, `flutter test`.
2. Mantener analyzer limpio: 0 warnings, 0 info, 0 errors.
3. Agregar tests de componente/flujo principal de Hub.

## 7. Plan multiagente por fases
| Fase | Backend-vcom | App_Vcom (Hub) | Entregable |
|---|---|---|---|
| F0 Saneamiento | Ajustar permisos/perfil y contrato auth para integracion social | Alinear consumo de sesion/permisos en app | Base estable |
| F1 Schema Hub | Migraciones, modelos, indices, resources base | Mocks de Hub y modelos | DB + contrato inicial |
| F2 Tags | Endpoints + policies + validaciones + pruebas | `TagSelector` + cache de tags | Tags funcionales |
| F3 Feed Posts | Crear/listar/detalle/eliminar + eager loading + conteos | `hub.page` + feed infinito + `PostCard` | Feed completo |
| F4 Multimedia | Upload, thumbnails, validacion mime/size, colas | `MediaViewer`, carga diferida, no autoplay feed | Media estable |
| F5 Comments | Listado/creacion paginada + consistencia de conteo | `CommentList` lazy + composer | Comentarios listos |
| F6 UI fidelity | Ajustes finos payload/UI | Replica visual fiel a diseno | UI validada |
| F7 Hardening | Perfilado, pruebas, docs API | Perfilado de scroll/rebuild/memoria | Release candidate |

## 8. Estrategia de rendimiento distribuida
1. DB: indices correctos, queries paginadas, orden estable por fecha+id.
2. Backend: eager loading, sin N+1, sin comentarios embebidos en feed.
3. Frontend: lazy load real, cache en memoria, render incremental, skeletons.
4. Media: thumbnails, compresion, carga diferida.
5. Meta objetivo: respuesta feed p95 < 300 ms en dataset medio.

## 9. Riesgos y mitigaciones
1. Inconsistencia de identidad/roles: resolver en F0 antes de Hub.
2. Regresiones por acoplamiento: mantener prefijo API Hub y feature aislada.
3. Degradacion en scroll: medir y aplicar optimizaciones con evidencia.
4. Deriva visual: checklist de comparacion contra diseno de referencia.

## 10. Criterios de aceptacion finales
1. Solo admin/monitor crean tags y posts.
2. Todos los autenticados pueden comentar.
3. Feed y comentarios paginados a 10 items con lazy load real.
4. Posts soportan texto, media multiple o combinacion.
5. Hub cumple reglas de arquitectura y calidad de `.codex/rules/flutter`.
6. UI final es fiel al diseno de referencia.
7. Rendimiento estable, sin bloqueos ni payloads excesivos.
