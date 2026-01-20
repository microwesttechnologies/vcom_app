# ⚡ Optimización: Estado Sin Bloqueo de la App

## 🐛 Problema Original

La app se quedaba **pausada/congelada** durante:
- ✅ Inicio de la app
- ✅ Cierre de la app
- ✅ Transiciones de ciclo de vida

**Causa:** Las operaciones HTTP en `didChangeAppLifecycleState` bloqueaban el hilo principal.

---

## ✅ Soluciones Implementadas

### 1. **Detección Selectiva de Estados**

**Antes:**
```dart
if (state == AppLifecycleState.paused || 
    state == AppLifecycleState.inactive ||
    state == AppLifecycleState.detached) {
  await _userStatusService.setOffline(); // ❌ BLOQUEABA
}
```

**Después:**
```dart
// Solo detectar cierre COMPLETO de la app
if (state == AppLifecycleState.detached) {
  // Fire-and-forget: NO bloquea
  _userStatusService.setOffline().catchError((e) {
    print('⚠️ Error: $e');
  });
}
```

**Razones:**
- `paused`: Puede ser temporal (cambio de app, notificación)
- `inactive`: Transición muy rápida
- `detached`: Cierre real de la app ✅

---

### 2. **Fire-and-Forget (Sin await)**

**Antes:**
```dart
await _userStatusService.setOffline(); // ❌ Espera 5-10 segundos
```

**Después:**
```dart
_userStatusService.setOffline().catchError((e) {
  print('⚠️ Error: $e');
}); // ✅ Ejecuta en background, no bloquea
```

**Ventajas:**
- ✅ No bloquea el ciclo de vida de la app
- ✅ La UI responde inmediatamente
- ✅ Errores se capturan sin crashear

---

### 3. **Verificación de Token**

**Antes:**
```dart
// Siempre intentaba actualizar estado
_userStatusService.setOffline();
```

**Después:**
```dart
final tokenService = TokenService();
if (!tokenService.hasToken()) {
  return; // No hay usuario logueado, no hacer nada
}
_userStatusService.setOffline().catchError(...);
```

**Ventajas:**
- ✅ Evita llamadas innecesarias si no hay sesión
- ✅ Reduce carga de red
- ✅ Más rápido

---

### 4. **Timeouts Reducidos**

**Antes:**
```dart
await http.post(url, headers: headers)
  .timeout(const Duration(seconds: 10)); // ❌ 10 segundos
```

**Después:**
```dart
await http.post(url, headers: headers)
  .timeout(
    const Duration(seconds: 2), // ✅ 2 segundos
    onTimeout: () {
      print('⚠️ Timeout');
      return http.Response('Timeout', 408);
    },
  );
```

**Ventajas:**
- ✅ Falla rápido si no hay conexión
- ✅ No bloquea la app por mucho tiempo
- ✅ Mejor experiencia de usuario

---

### 5. **Pusher No Bloqueante**

**Antes:**
```dart
// 1. Backend (espera)
await http.post(backendUrl);

// 2. Pusher (espera)
await _sendToPusher(...);
```

**Después:**
```dart
// 1. Backend (espera máximo 2s)
await http.post(backendUrl).timeout(Duration(seconds: 2));

// 2. Pusher (fire-and-forget, no espera)
_sendToPusher(...).catchError((e) {
  print('⚠️ Error Pusher: $e');
});
```

**Ventajas:**
- ✅ Backend se espera (importante para persistencia)
- ✅ Pusher no bloquea (menos crítico)
- ✅ Total máximo: 2 segundos vs 15 segundos antes

---

## 📊 Comparación de Tiempos

### Antes (❌ Bloqueaba la App)
```
App cierre detectado
  ↓
Backend: POST /status/offline (5s timeout)
  ↓ ESPERA 5 segundos
Pusher: POST /events (10s timeout)
  ↓ ESPERA 10 segundos
TOTAL: 15 segundos (APP CONGELADA)
```

### Después (✅ No Bloquea)
```
App cierre detectado
  ↓
Fire-and-forget (0s de bloqueo)
  ↓ NO ESPERA
Backend: POST /status/offline (2s timeout) - en background
Pusher: POST /events (2s timeout) - en background (no espera backend)
  ↓
TOTAL: 0 segundos de bloqueo
```

---

## 🔧 Archivos Modificados

### 1. `lib/main.dart`
**Cambios:**
- ✅ Solo detecta `detached` (no `paused` ni `inactive`)
- ✅ Verifica `hasToken()` antes de actualizar
- ✅ Fire-and-forget con `catchError()`
- ✅ No usa `await` en `didChangeAppLifecycleState`

### 2. `lib/core/common/user_status.service.dart`
**Cambios:**
- ✅ Timeouts reducidos de 5-10s a 2s
- ✅ `onTimeout` callback para fallar rápido
- ✅ `_sendToPusher()` no se espera (fire-and-forget)
- ✅ Todos los errores se capturan sin crashear

---

## 🎯 Comportamiento Actual

### ✅ Escenario 1: Login
```
Usuario inicia sesión
  ↓
UserStatusService.setOnline() (con await)
  ↓ Espera 2s máximo
Backend + Pusher
  ↓
Navegación a Dashboard
```
**Tiempo:** ~2 segundos (aceptable, parte del flujo de login)

### ✅ Escenario 2: Logout
```
Usuario presiona "Cerrar Sesión"
  ↓
UserStatusService.setOffline() (con await)
  ↓ Espera 2s máximo
Backend + Pusher
  ↓
TokenService.clear()
  ↓
Navegación a Login
```
**Tiempo:** ~2 segundos (aceptable, parte del flujo de logout)

### ✅ Escenario 3: App Minimizada
```
Usuario presiona Home
  ↓
AppLifecycleState.paused (IGNORADO)
  ↓
NO SE HACE NADA
  ↓
App sigue respondiendo
```
**Tiempo:** 0 segundos ✅

### ✅ Escenario 4: App Cerrada Completamente
```
Usuario cierra la app
  ↓
AppLifecycleState.detached
  ↓
Fire-and-forget: setOffline().catchError(...)
  ↓ NO ESPERA
App se cierra inmediatamente
  ↓
Backend/Pusher se ejecutan en background (si hay tiempo)
```
**Tiempo:** 0 segundos de bloqueo ✅

### ✅ Escenario 5: App Resumida
```
Usuario vuelve a la app
  ↓
AppLifecycleState.resumed
  ↓
Fire-and-forget: setOnline().catchError(...)
  ↓ NO ESPERA
App responde inmediatamente
  ↓
Estado se actualiza en background
```
**Tiempo:** 0 segundos de bloqueo ✅

---

## 📝 Notas Importantes

### 🟢 Login/Logout SÍ Esperan
- **Login:** Espera `setOnline()` antes de navegar al Dashboard
- **Logout:** Espera `setOffline()` antes de limpiar sesión
- **Razón:** Son flujos críticos donde el usuario espera un momento de carga

### 🔵 Ciclo de Vida NO Espera
- **Detached:** Fire-and-forget, no bloquea
- **Resumed:** Fire-and-forget, no bloquea
- **Razón:** No deben interferir con la responsividad de la app

### 🟡 Timeouts Agresivos
- **2 segundos** para todas las operaciones HTTP
- Si falla, la app continúa normalmente
- Logs de advertencia para debugging

### 🔴 Pusher No Bloqueante
- Se envía en background
- No se espera respuesta
- Errores no afectan el flujo principal

---

## 🧪 Testing

### Prueba 1: Cierre de App
1. ✅ Abrir app y hacer login
2. ✅ Cerrar app completamente (swipe)
3. ✅ Verificar que la app se cierra INMEDIATAMENTE
4. ✅ En otro dispositivo, verificar que aparece offline (después de 1-2s)

### Prueba 2: Minimizar App
1. ✅ Abrir app y hacer login
2. ✅ Presionar botón Home
3. ✅ Verificar que la app NO se congela
4. ✅ Estado online se mantiene (no se marca offline)

### Prueba 3: Volver a App
1. ✅ Con app minimizada, volver a abrirla
2. ✅ Verificar que responde INMEDIATAMENTE
3. ✅ Estado online se confirma en background

### Prueba 4: Login/Logout
1. ✅ Hacer login → espera ~2s (normal)
2. ✅ Hacer logout → espera ~2s (normal)
3. ✅ Ambos flujos completan correctamente

---

## 🚀 Mejoras Futuras (Opcional)

- [ ] Usar WorkManager para garantizar que offline se envíe
- [ ] Implementar retry logic para operaciones fallidas
- [ ] Agregar indicador de "Sincronizando..." en UI
- [ ] Cache de estado para enviar cuando haya conexión

---

**Fecha:** 2026-01-20  
**Problema:** App pausada durante ciclo de vida  
**Estado:** ✅ Resuelto  
**Tiempo de Bloqueo:** 0 segundos
