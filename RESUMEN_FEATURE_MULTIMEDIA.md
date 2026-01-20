# 📸🎥 Feature: Envío de Imágenes y Videos en Chat

## ✅ Implementado en Flutter

### **1. Servicio de Upload de Medios**
📁 `lib/core/common/media_upload.service.dart`

**Funcionalidades:**
- ✅ Seleccionar imagen de galería o cámara
- ✅ Seleccionar video de galería o cámara
- ✅ Validar tamaño de imagen (máx 10MB)
- ✅ Validar tamaño de video (máx 50MB)
- ✅ Validar duración de video (máx 60 segundos)
- ✅ Subir archivos al servidor con multipart/form-data
- ✅ Métodos combinados: `selectAndUploadImage()` y `selectAndUploadVideo()`

---

### **2. Widget para Mostrar Contenido Multimedia**
📁 `lib/pages/chat/widgets/message_content.widget.dart`

**Características:**
- ✅ Muestra texto, imágenes o videos según el tipo de mensaje
- ✅ Imágenes con loading indicator
- ✅ Videos con controls básicos (play/pause)
- ✅ Click en imagen → vista fullscreen con zoom
- ✅ Click en video → vista fullscreen
- ✅ Error handling con placeholders

---

### **3. Modificaciones en Chat UI**
📁 `lib/pages/chat/chat.page.dart`

**Botones agregados:**
- ✅ 📷 Botón de imagen (IconButton con ícono `Icons.image`)
- ✅ 🎥 Botón de video (IconButton con ícono `Icons.videocam`)

**Flujo:**
1. Usuario presiona botón de imagen/video
2. Se muestra diálogo de "Subiendo..."
3. Se selecciona archivo de galería/cámara
4. Se valida tamaño y duración
5. Se sube al servidor
6. Se envía mensaje con URL del archivo
7. Se muestra en el chat

---

### **4. Modificaciones en Chat Component**
📁 `lib/pages/chat/chat.component.dart`

**Cambios:**
- ✅ Método `sendMessage()` acepta parámetro `messageType`
- ✅ Soporta tipos: `'text'`, `'image'`, `'video'`
- ✅ Se envía el tipo correcto a Pusher y al backend

---

### **5. Permisos de Android**
📁 `android/app/src/main/AndroidManifest.xml`

**Permisos agregados:**
- ✅ `CAMERA` - Acceso a cámara
- ✅ `READ_EXTERNAL_STORAGE` - Leer galería (Android ≤ 32)
- ✅ `WRITE_EXTERNAL_STORAGE` - Guardar archivos (Android ≤ 29)
- ✅ `READ_MEDIA_IMAGES` - Leer imágenes (Android ≥ 33)
- ✅ `READ_MEDIA_VIDEO` - Leer videos (Android ≥ 33)

**Queries agregados:**
- ✅ `IMAGE_CAPTURE` - Captura de fotos
- ✅ `VIDEO_CAPTURE` - Grabación de videos
- ✅ `PICK` image/* y video/* - Selección de galería
- ✅ `GET_CONTENT` image/* y video/* - Obtención de contenido

---

## ⏳ Pendiente en Backend

### **1. Crear Endpoint de Upload**
📁 `app/Presentation/Http/Controllers/ChatController.php`

**Método:** `uploadMedia(Request $request)`

**Responsabilidades:**
1. Validar archivo (tipo, tamaño, extensión)
2. Generar nombre único (UUID)
3. Guardar en storage: `storage/app/public/chat/YYYY/MM/DD/{images|videos}/`
4. Retornar URL completa del archivo

**Ver:** `BACKEND_MEDIA_UPLOAD_ENDPOINT.md` para implementación completa.

---

### **2. Agregar Ruta en API**
📁 `routes/api.php`

```php
Route::middleware('auth:sanctum')->group(function () {
    Route::post('/chat/upload-media', [ChatController::class, 'uploadMedia']);
});
```

---

### **3. Crear Symlink de Storage**

```bash
php artisan storage:link
```

---

### **4. Modificar Tabla de Mensajes (si es necesario)**

Si la columna `message_type` no existe en `tb_messages`:

```sql
ALTER TABLE tb_messages 
ADD COLUMN message_type ENUM('text', 'image', 'video') DEFAULT 'text' AFTER content;
```

---

## 🎯 Flujo Completo

```
┌─────────────────────────────────────────────────────────────┐
│                    USUARIO PRESIONA 📷                       │
└─────────────────┬───────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────┐
│               Flutter: MediaUploadService                    │
│  1. Abre galería/cámara (image_picker)                      │
│  2. Usuario selecciona imagen                                │
│  3. Valida tamaño (max 10MB)                                │
└─────────────────┬───────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────┐
│               Flutter → Backend: POST /upload-media          │
│  Headers: Authorization: Bearer {token}                      │
│  Body: file=... & type=image                                 │
└─────────────────┬───────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────┐
│               Backend: ChatController@uploadMedia            │
│  1. Valida archivo                                           │
│  2. Guarda en storage/app/public/chat/2026/01/20/images/     │
│  3. Retorna: {url: "http://.../storage/chat/.../abc.jpg"}   │
└─────────────────┬───────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────┐
│            Flutter: ChatComponent.sendMessage()              │
│  content: "http://.../storage/chat/.../abc.jpg"              │
│  messageType: "image"                                         │
└─────────────────┬───────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────┐
│            Pusher: Evento message.sent                       │
│  data: { content: "url", message_type: "image" }             │
└─────────────────┬───────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────┐
│         Receptor: MessageContentWidget                       │
│  1. Detecta messageType = "image"                            │
│  2. Muestra Image.network(url)                               │
│  3. Click → Fullscreen con zoom                              │
└─────────────────────────────────────────────────────────────┘
```

---

## 📋 Testing Checklist

### **Imágenes:**
- [ ] Seleccionar imagen de galería
- [ ] Tomar foto con cámara
- [ ] Validar tamaño máximo (10MB)
- [ ] Subir imagen correctamente
- [ ] Mostrar imagen en el chat
- [ ] Click en imagen → Vista fullscreen
- [ ] Zoom en imagen funciona

### **Videos:**
- [ ] Seleccionar video de galería
- [ ] Grabar video con cámara
- [ ] Validar duración máxima (60 segundos)
- [ ] Validar tamaño máximo (50MB)
- [ ] Subir video correctamente
- [ ] Mostrar video en el chat con thumbnail
- [ ] Play/Pause funciona
- [ ] Click en video → Vista fullscreen

### **Error Handling:**
- [ ] Archivo muy grande → Mensaje de error
- [ ] Video muy largo → Mensaje de error
- [ ] Sin conexión → Mensaje de error
- [ ] Backend no responde → Timeout y mensaje de error
- [ ] Usuario cancela selección → No hace nada

---

## 🎨 UI/UX

### **Mensajes de Texto:**
```
┌─────────────────────────┐
│ Usuario                 │
│ Hola, ¿cómo estás?      │
│ 14:30                   │
└─────────────────────────┘
```

### **Mensajes con Imagen:**
```
┌─────────────────────────┐
│ Usuario                 │
│ ┌───────────────────┐   │
│ │   [IMAGEN]        │   │
│ │   250x300px       │   │
│ └───────────────────┘   │
│ 14:31                   │
└─────────────────────────┘
```

### **Mensajes con Video:**
```
┌─────────────────────────┐
│ Usuario                 │
│ ┌───────────────────┐   │
│ │   [THUMBNAIL]     │   │
│ │      ▶️ Play      │   │
│ │      00:45         │   │
│ └───────────────────┘   │
│ 14:32                   │
└─────────────────────────┘
```

---

## 📦 Dependencias Usadas

```yaml
dependencies:
  image_picker: ^1.1.2      # Seleccionar imágenes/videos
  video_player: ^2.8.2      # Reproducir videos
  http: ^1.2.0              # Upload de archivos
```

---

## 🚀 Próximos Pasos

1. ✅ **Implementar endpoint en backend** (ver `BACKEND_MEDIA_UPLOAD_ENDPOINT.md`)
2. ✅ **Crear symlink de storage** (`php artisan storage:link`)
3. ✅ **Testing completo** en dispositivo real
4. ⏳ **Opcional:** Agregar compresión de imágenes antes de subir
5. ⏳ **Opcional:** Agregar indicador de progreso de upload
6. ⏳ **Opcional:** Permitir seleccionar múltiples imágenes

---

**Fecha:** 2026-01-20  
**Feature:** Envío de imágenes y videos en chat  
**Estado Flutter:** ✅ Completo  
**Estado Backend:** ⏳ Pendiente
