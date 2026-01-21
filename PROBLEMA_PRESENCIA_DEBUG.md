# 🐛 Problema de Presencia - Debug Guide

## Problema Identificado

**Síntoma:**
- Usuario conectado: **Camila Arevalo**
- Usuario que aparece online: **Sofía Martínez** ❌
- Usuario que aparece offline: **Camila Arevalo** ❌

## Causa Probable

El backend está emitiendo el evento de presencia con el **ID de usuario incorrecto**.

## 🔍 Verificación Urgente en el Backend

### 1. Revisar el Controlador de Estado

**Archivo:** `app/Http/Controllers/Api/V1/ChatStatusController.php` (o similar)

```php
public function setOnline(Request $request)
{
    // ⚠️ VERIFICAR ESTA LÍNEA
    $user = auth()->user();  // ← ¿Este es el usuario correcto?
    
    // DEBUG: Agregar este log
    Log::info('🟢 Setting user online', [
        'user_id' => $user->id_user,
        'user_name' => $user->name,
        'token_user_id' => auth()->id(),
    ]);
    
    // Actualizar estado
    $user->update([
        'is_online' => true,
        'last_seen' => now(),
    ]);
    
    // ⚠️ VERIFICAR QUE SE EMITA EL ID CORRECTO
    event(new UserStatusChanged(
        $user->id_user,  // ← ¿Es el ID correcto?
        $user->name,     // ← ¿Es el nombre correcto?
        true
    ));
    
    return response()->json(['status' => 'online']);
}
```

### 2. Verificar el Middleware de Autenticación

**Posible problema:** El middleware está usando una sesión cacheada o token incorrecto.

```php
// En config/auth.php
'guards' => [
    'api' => [
        'driver' => 'sanctum', // o 'jwt'
        'provider' => 'users',
    ],
],
```

### 3. Verificar el Evento de Pusher

**Archivo:** `app/Events/UserStatusChanged.php`

```php
class UserStatusChanged implements ShouldBroadcast
{
    public $userId;
    public $userName;
    public $isOnline;
    
    public function __construct($userId, $userName, $isOnline)
    {
        // DEBUG: Agregar log
        Log::info('📤 UserStatusChanged Event', [
            'user_id' => $userId,
            'user_name' => $userName,
            'is_online' => $isOnline,
        ]);
        
        $this->userId = $userId;
        $this->userName = $userName;
        $this->isOnline = $isOnline;
    }
    
    public function broadcastOn()
    {
        return new Channel('users.status');
    }
    
    public function broadcastAs()
    {
        return 'user.status.changed';
    }
    
    public function broadcastWith()
    {
        return [
            'type' => 'user.status.changed',
            'user_id' => $this->userId,
            'user_name' => $this->userName,
            'is_online' => $this->isOnline,
            'last_seen' => now()->toIso8601String(),
        ];
    }
}
```

## 🎯 Solución Rápida

### Opción 1: Limpiar Sesiones y Tokens

1. **Cerrar sesión en ambos dispositivos**
2. **Limpiar caché del backend:**
   ```bash
   php artisan cache:clear
   php artisan config:clear
   php artisan route:clear
   ```
3. **Reiniciar servidor Laravel**
4. **Volver a iniciar sesión**

### Opción 2: Verificar Tokens JWT/Sanctum

Si usas JWT, verifica que no haya tokens cruzados:

```bash
# En el backend
php artisan tinker

# Verificar usuarios y tokens
$camila = User::where('name', 'Camila Arevalo')->first();
echo "Camila ID: " . $camila->id_user . "\n";

$sofia = User::where('name', 'Sofía Martínez')->first();
echo "Sofia ID: " . $sofia->id_user . "\n";

# Verificar tokens activos
DB::table('personal_access_tokens')->latest()->take(5)->get();
```

### Opción 3: Agregar Validación en el Backend

En el controlador de estado, agregar validación adicional:

```php
public function setOnline(Request $request)
{
    $user = auth()->user();
    
    // Validar que el usuario esté correctamente autenticado
    if (!$user) {
        return response()->json(['error' => 'No autenticado'], 401);
    }
    
    // Log detallado
    Log::info('Setting online', [
        'authenticated_user_id' => $user->id_user,
        'authenticated_user_name' => $user->name,
        'token' => substr($request->bearerToken(), 0, 20) . '...',
    ]);
    
    // Forzar recarga del usuario desde DB
    $user = User::find($user->id_user);
    
    if (!$user) {
        return response()->json(['error' => 'Usuario no encontrado'], 404);
    }
    
    // Actualizar estado
    $user->update([
        'is_online' => true,
        'last_seen' => now(),
    ]);
    
    // Emitir evento CON EL ID CORRECTO
    event(new UserStatusChanged(
        $user->id_user,
        $user->name,
        true
    ));
    
    return response()->json([
        'status' => 'online',
        'user_id' => $user->id_user,
        'user_name' => $user->name,
    ]);
}
```

## 🔬 Logs que Debes Revisar

### En el dispositivo de Camila (cuando se conecta):

```
🟢 MARCANDO COMO ONLINE
🟢 🔑 ID Usuario: [BUSCAR ESTE ID]
🟢 📝 Nombre Usuario: Camila Arevalo
```

### En el servidor Laravel (backend):

```bash
# Revisar logs
tail -f storage/logs/laravel.log
```

Buscar:
```
Setting online
authenticated_user_id: [VER QUÉ ID APARECE]
authenticated_user_name: [VER QUÉ NOMBRE APARECE]
```

### En el dispositivo del Monitor (cuando recibe el evento):

```
📨 [UNIFIED] MENSAJE RECIBIDO DE PUSHER
📨 User ID: [VER QUÉ ID LLEGA]
📨 User Name: [VER QUÉ NOMBRE LLEGA]
```

## ✅ Checklist de Verificación

- [ ] Los tokens de sesión son diferentes para cada usuario
- [ ] El backend no tiene caché de sesiones
- [ ] El middleware de autenticación está configurado correctamente
- [ ] Los eventos de Pusher se emiten con el ID correcto
- [ ] No hay sesiones cruzadas en el navegador/app

## 🚨 Solución Temporal (Workaround)

Si necesitas una solución rápida mientras arreglas el backend, puedes:

1. **Cerrar sesión completa** en ambos dispositivos
2. **Limpiar datos de la app** (Settings → Apps → VCOM → Clear Data)
3. **Reiniciar el servidor Laravel**
4. **Iniciar sesión primero con Camila**
5. **Luego iniciar sesión con el Monitor**

## 📞 Siguiente Paso

**Por favor comparte:**

1. Los logs del backend cuando Camila se conecta
2. Los logs de la app cuando Camila se conecta  
3. Los logs de la app del Monitor cuando recibe el evento

Con eso podré darte la solución exacta.
