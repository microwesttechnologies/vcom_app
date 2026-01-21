# Solución de Presencia en Tiempo Real

## 📋 Problema Identificado

El sistema de estado en tiempo real presentaba los siguientes problemas:

1. **Monitor se mostraba online permanentemente**: Cuando el monitor se conectaba, aparecía como "en línea", pero al desconectarse seguía mostrándose online.
2. **Modelos con estado inconsistente**: Algunas modelos siempre se mostraban online y otras siempre offline, sin reflejar su estado real.
3. **No se actualizaba el estado**: El estado no se actualizaba correctamente al entrar/salir del módulo de chat.
4. **Falta de gestión del ciclo de vida**: No se manejaban correctamente los eventos de la aplicación (pausa, resume, etc.).

## ✅ Solución Implementada

Se creó una solución completa y reutilizable basada en un **servicio de presencia centralizado** que gestiona el estado de todos los usuarios en tiempo real.

### Arquitectura de la Solución

```
┌─────────────────────────────────────────────────────────┐
│                   ChatPage (UI Layer)                    │
│  - Observa ciclo de vida de la app                      │
│  - Activa/desactiva presencia según estado              │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│              ChatComponent (Logic Layer)                 │
│  - Gestiona conversaciones y mensajes                   │
│  - Escucha cambios de presencia                         │
│  - Actualiza UI cuando cambia estado                    │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│           PresenceService (Core Service)                 │
│  - Servicio singleton centralizado                      │
│  - Gestiona estado online/offline                       │
│  - Heartbeat cada 30 segundos                           │
│  - Sincroniza estados con backend                       │
│  - Emite/escucha eventos de Pusher                      │
└────────────────────┬────────────────────────────────────┘
                     │
         ┌───────────┴──────────┐
         ▼                      ▼
┌──────────────────┐   ┌──────────────────┐
│  Backend API     │   │  Pusher Events   │
│  /status/online  │   │  users.status    │
│  /status/offline │   │  channel         │
└──────────────────┘   └──────────────────┘
```

## 🎯 Componentes Creados/Modificados

### 1. **PresenceService** (NUEVO)
`lib/core/realtime/presence.service.dart`

**Responsabilidades:**
- Gestionar el estado online/offline del usuario actual
- Escuchar cambios de estado de otros usuarios vía Pusher
- Mantener un mapa actualizado de estados de usuarios
- Enviar heartbeats periódicos cada 30 segundos
- Sincronizar estados con el backend
- Proporcionar API para consultar estados

**Características clave:**
```dart
class PresenceService extends ChangeNotifier {
  // Singleton pattern
  static final PresenceService _instance = PresenceService._internal();
  factory PresenceService() => _instance;
  
  // Estado de usuarios en memoria
  Map<String, UserPresenceState> _userStates = {};
  
  // Métodos principales
  Future<void> initialize();      // Inicializa Pusher y suscribe al canal
  Future<void> activate();        // Marca como online y activa heartbeat
  Future<void> deactivate();      // Marca como offline y detiene heartbeat
  bool isUserOnline(String userId); // Consulta si un usuario está online
  String getUserStatusText(String userId); // Obtiene texto descriptivo
}
```

### 2. **UserStatusService** (ACTUALIZADO)
`lib/core/common/user_status.service.dart`

**Cambios:**
- Ahora usa `PresenceService` internamente
- Mantiene compatibilidad con código existente
- Actúa como wrapper para mantener la API anterior

### 3. **ChatComponent** (ACTUALIZADO)
`lib/pages/chat/chat.component.dart`

**Cambios principales:**
- Integrado con `PresenceService`
- Escucha cambios de presencia vía `addListener`
- Actualiza estados de conversaciones automáticamente
- Sincroniza estados al cargar conversaciones
- Limpia recursos correctamente en dispose

**Código clave:**
```dart
// Inicialización
await _presence.initialize();
await _presence.activate();
_presence.addListener(_onPresenceChanged);

// Listener de cambios
void _onPresenceChanged() {
  // Actualizar conversaciones con nuevos estados
  _conversations = _conversations.map((conv) {
    final isOnline = _presence.isUserOnline(conv.idOtherUser);
    return conv.copyWith(
      userStatus: isOnline ? 'online' : 'offline',
    );
  }).toList();
  notifyListeners();
}
```

### 4. **ChatPage** (ACTUALIZADO)
`lib/pages/chat/chat.page.dart`

**Cambios principales:**
- Implementa `WidgetsBindingObserver` para observar ciclo de vida
- Maneja eventos `resumed` y `paused` de la aplicación
- Activa/desactiva presencia según el estado de la app
- Usa `PresenceService` directamente para consultar estados en UI

**Código clave:**
```dart
class _ChatPageState extends State<ChatPage> with WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _presence.activate(); // App volvió al primer plano
        break;
      case AppLifecycleState.paused:
        _presence.deactivate(); // App en segundo plano
        break;
    }
  }
}
```

### 5. **ConversationModel** (ACTUALIZADO)
`lib/core/models/chat/conversation.model.dart`

**Cambios:**
- Agregado campo `lastSeen` (DateTime?)
- Actualizado `fromJson` para parsear `last_seen`
- Actualizado `copyWith` para incluir `lastSeen`
- Actualizado `toJson` para serializar `lastSeen`

### 6. **EnvironmentDev** (ACTUALIZADO)
`lib/core/common/envirotment.dev.dart`

**Cambios:**
- Agregado endpoint `chatUsersStatus` para obtener estados en batch

## 🔄 Flujo de Funcionamiento

### Al Entrar al Chat

1. **Usuario abre ChatPage**
   ```
   ChatPage.initState()
   └─> ChatComponent.initialize()
       └─> PresenceService.initialize()
           └─> Conecta a Pusher
           └─> Suscribe a canal 'users.status'
       └─> PresenceService.activate()
           └─> POST /api/v1/chat/status/online (Backend)
           └─> Emite evento 'user.status.changed' (Pusher)
           └─> Inicia heartbeat (cada 30s)
   ```

2. **Carga de conversaciones**
   ```
   ChatComponent.fetchConversations()
   └─> GET /api/v1/chat/conversations
   └─> Recolecta IDs de usuarios
   └─> PresenceService.syncUserStates(userIds)
       └─> POST /api/v1/chat/users/status
       └─> Actualiza estados locales
   └─> Actualiza conversaciones con estados
   ```

### Durante el Chat

1. **Heartbeat periódico (cada 30s)**
   ```
   PresenceService._heartbeatTimer
   └─> POST /api/v1/chat/status/online
   └─> Emite evento 'user.status.changed'
   └─> Actualiza estado local
   ```

2. **Otro usuario cambia de estado**
   ```
   Pusher recibe evento 'user.status.changed'
   └─> PresenceService._handlePresenceEvent()
       └─> Actualiza _userStates[userId]
       └─> notifyListeners()
           └─> ChatComponent._onPresenceChanged()
               └─> Actualiza conversaciones
               └─> notifyListeners()
                   └─> ChatPage se reconstruye con nuevo estado
   ```

### Al Salir del Chat

1. **Usuario cierra ChatPage**
   ```
   ChatPage.dispose()
   └─> ChatComponent.dispose()
       └─> PresenceService.deactivate()
           └─> Detiene heartbeat
           └─> POST /api/v1/chat/status/offline
           └─> Emite evento 'user.status.changed' (offline)
   ```

2. **App pasa a segundo plano**
   ```
   ChatPage.didChangeAppLifecycleState(AppLifecycleState.paused)
   └─> PresenceService.deactivate()
       └─> Marca como offline
   ```

## 🎨 Mejoras en la UI

### Lista de Conversaciones

```dart
// Indicador visual de estado online
if (isOnline)
  Positioned(
    right: 0,
    bottom: 0,
    child: Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: VcomColors.success,  // Verde
        shape: BoxShape.circle,
      ),
    ),
  ),

// Texto de última vez visto (solo si offline)
if (!isOnline)
  Text(
    statusText,  // "Hace 5 min", "Hace 2h", etc.
    style: TextStyle(
      fontSize: 10,
      color: VcomColors.blancoCrema.withOpacity(0.4),
    ),
  ),
```

### Header de Chat

```dart
// Estado dinámico del usuario
Text(
  _presence.getUserStatusText(conversation.idOtherUser),
  // "En línea" o "Hace X min/h/d"
  style: TextStyle(
    fontSize: 12,
    color: _presence.isUserOnline(userId)
        ? VcomColors.success  // Verde si online
        : VcomColors.blancoCrema.withOpacity(0.5),  // Gris si offline
  ),
),
```

## 📊 Gestión de Estado

### Estados de Presencia

```dart
class UserPresenceState {
  final String userId;
  final String userName;
  final bool isOnline;
  final DateTime lastSeen;
}
```

### Detección de Offline

El servicio considera a un usuario **offline** si:
1. `isOnline == false`, O
2. Hace más de 2 minutos desde `lastSeen`

```dart
bool isUserOnline(String userId) {
  final state = _userStates[userId];
  if (state == null) return false;
  
  final now = DateTime.now();
  final diff = now.difference(state.lastSeen);
  
  return state.isOnline && diff < Duration(minutes: 2);
}
```

## 🔧 Configuración Requerida

### Backend (Laravel)

El backend debe implementar los siguientes endpoints:

```php
// Marcar como online
POST /api/v1/chat/status/online
Headers: Authorization: Bearer {token}
Response: { "status": "success" }

// Marcar como offline
POST /api/v1/chat/status/offline
Headers: Authorization: Bearer {token}
Response: { "status": "success" }

// Obtener estados de múltiples usuarios (NUEVO)
POST /api/v1/chat/users/status
Headers: Authorization: Bearer {token}
Body: { "user_ids": ["uuid1", "uuid2", ...] }
Response: {
  "statuses": [
    {
      "user_id": "uuid1",
      "user_name": "Usuario 1",
      "is_online": true,
      "last_seen": "2026-01-21T10:30:00Z"
    },
    ...
  ]
}
```

### Pusher

Canal: `users.status`
Evento: `user.status.changed`

```json
{
  "type": "user.status.changed",
  "user_id": "uuid",
  "user_name": "Nombre Usuario",
  "is_online": true,
  "last_seen": "2026-01-21T10:30:00Z"
}
```

## ✨ Ventajas de la Solución

1. **Centralizada**: Un solo servicio gestiona toda la presencia
2. **Reutilizable**: Se puede usar en cualquier parte de la app
3. **Eficiente**: 
   - Heartbeat cada 30s (no sobrecarga)
   - Sincronización batch de estados
   - Cache local de estados
4. **Confiable**:
   - Maneja ciclo de vida de la app
   - Timeout de 2 minutos para detectar offline
   - Limpieza correcta de recursos
5. **Tiempo real**: 
   - Eventos instantáneos vía Pusher
   - UI se actualiza automáticamente
6. **Mantenible**: 
   - Código organizado y documentado
   - Separación de responsabilidades
   - Fácil de extender

## 🧪 Pruebas Recomendadas

### Caso 1: Usuario se conecta
- [ ] Abrir app y entrar al chat
- [ ] Verificar que aparece como "En línea"
- [ ] Verificar indicador verde

### Caso 2: Usuario se desconecta
- [ ] Salir del chat
- [ ] Esperar 2-3 segundos
- [ ] Otro usuario debería ver "Desconectado"

### Caso 3: App en segundo plano
- [ ] Minimizar la app (presionar botón Home)
- [ ] Otro usuario debería ver "Desconectado" después de 2-3s
- [ ] Volver a la app
- [ ] Debería volver a "En línea"

### Caso 4: Múltiples usuarios
- [ ] 3+ usuarios en chat simultáneamente
- [ ] Uno se desconecta
- [ ] Los demás deberían ver su cambio de estado
- [ ] Estados independientes para cada usuario

### Caso 5: Última vez visto
- [ ] Usuario A se desconecta
- [ ] Usuario B debería ver "Hace X min"
- [ ] Esperar 1 hora
- [ ] Debería actualizarse a "Hace 1h"

## 🚀 Uso en Otros Módulos

El servicio es completamente reutilizable. Para usarlo en otros módulos:

```dart
import 'package:vcom_app/core/realtime/presence.service.dart';

class OtroModulo extends StatefulWidget {
  @override
  State<OtroModulo> createState() => _OtroModuloState();
}

class _OtroModuloState extends State<OtroModulo> {
  final PresenceService _presence = PresenceService();
  
  @override
  void initState() {
    super.initState();
    _presence.addListener(_onPresenceChanged);
    
    // El servicio ya está inicializado por ChatComponent
    // Solo necesitas escuchar cambios
  }
  
  void _onPresenceChanged() {
    setState(() {
      // Actualizar UI con nuevos estados
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: usuarios.map((user) {
        final isOnline = _presence.isUserOnline(user.id);
        final statusText = _presence.getUserStatusText(user.id);
        
        return ListTile(
          title: Text(user.name),
          subtitle: Text(statusText),
          leading: CircleAvatar(
            backgroundColor: isOnline ? Colors.green : Colors.grey,
          ),
        );
      }).toList(),
    );
  }
  
  @override
  void dispose() {
    _presence.removeListener(_onPresenceChanged);
    super.dispose();
  }
}
```

## 📝 Notas Finales

- **Heartbeat**: Se envía cada 30 segundos para mantener el estado online
- **Timeout offline**: 2 minutos sin heartbeat = offline automático
- **Singleton**: `PresenceService` es un singleton, todos comparten la misma instancia
- **Performance**: Los estados se cachean localmente, consultas son O(1)
- **Escalabilidad**: Sincronización batch permite manejar muchos usuarios eficientemente

## 🔍 Debug y Logs

El servicio incluye logs detallados para debugging:

```
👤 INICIALIZANDO PRESENCE SERVICE
🟢 Marcando como online...
✅ Backend: Usuario marcado como online
💓 Heartbeat iniciado (cada 30 segundos)
👤 Cambio de estado: Usuario ABC (uuid) -> OFFLINE
🔴 Desactivando PresenceService...
💓 Heartbeat detenido
```

Buscar por estos emojis en los logs para rastrear el flujo de presencia.
