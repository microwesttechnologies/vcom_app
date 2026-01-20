# 🟢🔴 Estado Online/Offline Centralizado

## 📋 Resumen de Cambios

Se ha refactorizado completamente la gestión del estado online/offline de los usuarios para que sea **centralizada** y se maneje a nivel de **sesión de la app**, no a nivel de módulo de chat.

---

## 🏗️ Arquitectura Nueva

### **UserStatusService** (Servicio Global)
- **Ubicación:** `lib/core/common/user_status.service.dart`
- **Responsabilidad:** Gestionar el estado online/offline del usuario en toda la app
- **Singleton:** Una única instancia compartida en toda la aplicación

### **Flujo de Estado:**

```
┌─────────────────────────────────────────────────────────────┐
│                    INICIO DE SESIÓN                         │
│                                                             │
│  LoginComponent.performLogin()                              │
│         ↓                                                   │
│  UserStatusService.setOnline()                              │
│         ↓                                                   │
│  ├─ Backend: POST /api/v1/chat/status/online               │
│  └─ Pusher: Emite 'user.status.changed' (online=true)      │
│                                                             │
│  Resultado: Usuario marcado como ONLINE en toda la app     │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                    CIERRE DE SESIÓN                         │
│                                                             │
│  Sidebar → Botón "Cerrar Sesión"                           │
│         ↓                                                   │
│  UserStatusService.setOffline()                             │
│         ↓                                                   │
│  ├─ Backend: POST /api/v1/chat/status/offline              │
│  └─ Pusher: Emite 'user.status.changed' (online=false)     │
│         ↓                                                   │
│  TokenService.clear()                                       │
│         ↓                                                   │
│  Navigator → LoginPage                                      │
│                                                             │
│  Resultado: Usuario marcado como OFFLINE y sesión cerrada  │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                 APP MINIMIZADA/CERRADA                      │
│                                                             │
│  MyApp (WidgetsBindingObserver)                             │
│         ↓                                                   │
│  didChangeAppLifecycleState(paused/inactive/detached)       │
│         ↓                                                   │
│  UserStatusService.setOffline()                             │
│         ↓                                                   │
│  ├─ Backend: POST /api/v1/chat/status/offline              │
│  └─ Pusher: Emite 'user.status.changed' (online=false)     │
│                                                             │
│  Resultado: Usuario marcado como OFFLINE al cerrar app     │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                    APP RESUMIDA                             │
│                                                             │
│  MyApp (WidgetsBindingObserver)                             │
│         ↓                                                   │
│  didChangeAppLifecycleState(resumed)                        │
│         ↓                                                   │
│  UserStatusService.setOnline()                              │
│         ↓                                                   │
│  ├─ Backend: POST /api/v1/chat/status/online               │
│  └─ Pusher: Emite 'user.status.changed' (online=true)      │
│                                                             │
│  Resultado: Usuario marcado como ONLINE al volver          │
└─────────────────────────────────────────────────────────────┘
```

---

## 📁 Archivos Modificados

### 1. **lib/core/common/user_status.service.dart** (NUEVO)
- Servicio singleton para gestionar estado online/offline
- Métodos:
  - `setOnline()`: Marca usuario como online (backend + Pusher)
  - `setOffline()`: Marca usuario como offline (backend + Pusher)
  - `_sendToPusher()`: Envía eventos directamente a Pusher con HMAC
  - `clear()`: Limpia el estado al cerrar sesión

### 2. **lib/pages/auth/login.component.dart**
- **Cambio:** Llama a `UserStatusService.setOnline()` después de login exitoso
- **Línea:** Después de guardar credenciales

### 3. **lib/components/shared/sidebar.component.dart**
- **Cambio:** Llama a `UserStatusService.setOffline()` antes de cerrar sesión
- **Flujo:**
  1. `UserStatusService.setOffline()`
  2. Llamada al backend `/auth/logout`
  3. `TokenService.clear()`
  4. `UserStatusService.clear()`
  5. Navegación a `LoginPage`

### 4. **lib/main.dart**
- **Cambio:** Implementa `WidgetsBindingObserver` para detectar ciclo de vida de la app
- **Detecta:**
  - `paused/inactive/detached`: Marca como offline
  - `resumed`: Marca como online

### 5. **lib/pages/chat/chat.component.dart**
- **Cambio:** Eliminados métodos `_setOnlineStatus()` y `_setOfflineStatus()`
- **Razón:** El estado ahora se maneja en `UserStatusService`
- **Responsabilidad actual:** Solo suscribirse a eventos de Pusher

### 6. **lib/pages/chat/chat.page.dart**
- **Cambio:** Eliminados todos los detectores de desconexión
- **Removido:**
  - `WidgetsBindingObserver`
  - `WillPopScope`
  - `leading` personalizado en AppBar
  - Llamadas a `disconnect()` en dispose

---

## 🎯 Comportamiento Esperado

### ✅ Escenario 1: Login
1. Usuario ingresa credenciales
2. Login exitoso → `UserStatusService.setOnline()`
3. **Resultado:** Usuario aparece ONLINE en toda la app
4. Otros usuarios ven el estado actualizado en tiempo real

### ✅ Escenario 2: Navegación en la App
1. Usuario navega entre módulos (Dashboard, Chat, Productos, etc.)
2. **Resultado:** Estado ONLINE se mantiene
3. No se marca como offline al entrar/salir del chat

### ✅ Escenario 3: Minimizar App
1. Usuario presiona botón Home o cambia de app
2. `didChangeAppLifecycleState(paused)` → `UserStatusService.setOffline()`
3. **Resultado:** Usuario aparece OFFLINE
4. Al volver: `didChangeAppLifecycleState(resumed)` → `UserStatusService.setOnline()`

### ✅ Escenario 4: Cerrar App
1. Usuario cierra la app completamente
2. `didChangeAppLifecycleState(detached)` → `UserStatusService.setOffline()`
3. **Resultado:** Usuario aparece OFFLINE

### ✅ Escenario 5: Cerrar Sesión
1. Usuario presiona "Cerrar Sesión" en sidebar
2. `UserStatusService.setOffline()` → Backend + Pusher
3. `TokenService.clear()` → Limpia datos locales
4. Navegación a `LoginPage`
5. **Resultado:** Usuario aparece OFFLINE y sesión cerrada

---

## 🔧 Detalles Técnicos

### Backend (Laravel)
- **Endpoints:**
  - `POST /api/v1/chat/status/online`: Actualiza `is_online=true` en BD
  - `POST /api/v1/chat/status/offline`: Actualiza `is_online=false` en BD
- **Nota:** Los eventos `broadcast()` en el backend están **comentados** para evitar duplicados

### Pusher (Tiempo Real)
- **Canal:** `users.status` (público)
- **Evento:** `user.status.changed`
- **Datos:**
  ```json
  {
    "user_id": "uuid-del-usuario",
    "user_name": "Nombre Usuario",
    "is_online": true/false
  }
  ```

### Persistencia
- **Backend:** Estado se guarda en `tb_users.is_online`
- **Pusher:** Eventos se emiten en tiempo real
- **Híbrido:** Backend para persistencia + Pusher para tiempo real

---

## 🐛 Problemas Resueltos

### ❌ Problema Anterior:
- Usuario se marcaba como online al **entrar al chat**
- Usuario se marcaba como offline al **salir del chat**
- Si el usuario estaba en el chat y cerraba la app, no se marcaba como offline
- Estado inconsistente entre módulos

### ✅ Solución Actual:
- Usuario se marca como online al **iniciar sesión**
- Usuario se marca como offline al **cerrar sesión** o **cerrar/minimizar app**
- Estado consistente en toda la app
- Detección automática de ciclo de vida de la app

---

## 📊 Flujo de Datos

```
┌─────────────┐
│   Login     │
│  Component  │
└──────┬──────┘
       │ performLogin()
       ↓
┌─────────────┐
│ UserStatus  │ ← Singleton (única instancia)
│   Service   │
└──────┬──────┘
       │
       ├─→ Backend: POST /api/v1/chat/status/online
       │   └─→ UPDATE tb_users SET is_online=true
       │
       └─→ Pusher: POST /apps/{id}/events
           └─→ Evento: user.status.changed
               └─→ Otros usuarios reciben notificación
```

---

## 🧪 Testing

### Prueba 1: Login
1. Iniciar sesión como Monitor
2. Verificar que aparece ONLINE en el dashboard
3. Abrir sesión como Modelo en otro dispositivo
4. Verificar que el Monitor ve a la Modelo ONLINE

### Prueba 2: Navegación
1. Estando logueado, navegar entre módulos
2. Verificar que el estado ONLINE se mantiene
3. Entrar al chat → Verificar que sigue ONLINE
4. Salir del chat → Verificar que sigue ONLINE

### Prueba 3: Minimizar App
1. Estando logueado, minimizar la app
2. En otro dispositivo, verificar que aparece OFFLINE
3. Volver a la app
4. Verificar que aparece ONLINE nuevamente

### Prueba 4: Cerrar Sesión
1. Estando logueado, presionar "Cerrar Sesión"
2. En otro dispositivo, verificar que aparece OFFLINE
3. Verificar que se redirige a LoginPage

---

## 📝 Notas Importantes

1. **UserStatusService es un Singleton:** Una única instancia en toda la app
2. **Estado global:** El estado online/offline es de la sesión, no del módulo
3. **Detección automática:** El ciclo de vida de la app se detecta en `main.dart`
4. **Backend + Pusher:** Persistencia en BD + Notificaciones en tiempo real
5. **Sin duplicados:** Los eventos solo se emiten desde Flutter, no desde Laravel

---

## 🚀 Próximos Pasos (Opcional)

- [ ] Implementar heartbeat para detectar desconexiones inesperadas
- [ ] Agregar timeout para marcar como offline si no hay actividad
- [ ] Implementar reconexión automática de Pusher al volver a la app
- [ ] Agregar indicador visual de "Reconectando..." si falla Pusher

---

**Fecha:** 2026-01-20  
**Autor:** AI Assistant  
**Estado:** ✅ Implementado y Funcional
