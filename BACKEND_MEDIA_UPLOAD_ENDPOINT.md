# 📤 Backend: Endpoint para Subir Archivos Multimedia

## 🎯 Requisito

Crear un endpoint en el backend Laravel para recibir y almacenar archivos multimedia (imágenes y videos) del chat.

---

## 📋 Especificaciones del Endpoint

### **URL:**
```
POST /api/v1/chat/upload-media
```

### **Headers:**
```
Authorization: Bearer {token}
Content-Type: multipart/form-data
```

### **Request Body (multipart/form-data):**
| Campo | Tipo   | Descripción                          | Obligatorio |
|-------|--------|--------------------------------------|-------------|
| file  | File   | Archivo (imagen o video)             | Sí          |
| type  | String | Tipo de archivo ('image' o 'video') | Sí          |

### **Validaciones:**

**Para Imágenes:**
- Extensiones permitidas: `jpg`, `jpeg`, `png`, `gif`, `webp`
- Tamaño máximo: `10 MB`

**Para Videos:**
- Extensiones permitidas: `mp4`, `mov`, `avi`, `webm`
- Tamaño máximo: `50 MB`
- Duración máxima: `60 segundos` (validado en Flutter)

### **Response Success (200):**
```json
{
  "success": true,
  "url": "https://tu-dominio.com/storage/chat/2026/01/20/archivo.jpg",
  "type": "image",
  "size": 1234567,
  "filename": "archivo.jpg"
}
```

### **Response Error (422):**
```json
{
  "success": false,
  "message": "El archivo supera el tamaño máximo permitido",
  "errors": {
    "file": ["El archivo debe ser menor a 10MB"]
  }
}
```

---

## 💻 Implementación en Laravel

### **1. Crear el Controller**

Archivo: `app/Presentation/Http/Controllers/ChatController.php`

```php
<?php

namespace App\Presentation\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

class ChatController extends Controller
{
    /**
     * Sube un archivo multimedia (imagen o video) al storage
     */
    public function uploadMedia(Request $request)
    {
        // Validar el request
        $request->validate([
            'file' => [
                'required',
                'file',
                function ($attribute, $value, $fail) use ($request) {
                    $type = $request->input('type');
                    
                    if ($type === 'image') {
                        // Validar imágenes
                        if (!in_array($value->extension(), ['jpg', 'jpeg', 'png', 'gif', 'webp'])) {
                            $fail('El archivo debe ser una imagen válida.');
                        }
                        if ($value->getSize() > 10 * 1024 * 1024) { // 10MB
                            $fail('La imagen no debe superar los 10MB.');
                        }
                    } elseif ($type === 'video') {
                        // Validar videos
                        if (!in_array($value->extension(), ['mp4', 'mov', 'avi', 'webm'])) {
                            $fail('El archivo debe ser un video válido.');
                        }
                        if ($value->getSize() > 50 * 1024 * 1024) { // 50MB
                            $fail('El video no debe superar los 50MB.');
                        }
                    }
                },
            ],
            'type' => 'required|in:image,video',
        ]);

        try {
            $file = $request->file('file');
            $type = $request->input('type');
            
            // Generar nombre único para el archivo
            $extension = $file->extension();
            $filename = Str::uuid() . '.' . $extension;
            
            // Organizar por tipo y fecha
            $path = $file->storeAs(
                'chat/' . date('Y/m/d') . '/' . $type . 's',
                $filename,
                'public'
            );
            
            // Obtener URL completa del archivo
            $url = Storage::url($path);
            $fullUrl = url($url);
            
            return response()->json([
                'success' => true,
                'url' => $fullUrl,
                'type' => $type,
                'size' => $file->getSize(),
                'filename' => $filename,
            ]);
            
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error al subir el archivo: ' . $e->getMessage(),
            ], 500);
        }
    }
}
```

---

### **2. Agregar la Ruta**

Archivo: `routes/api.php`

```php
Route::middleware('auth:sanctum')->group(function () {
    // ... otras rutas ...
    
    // Chat - Upload Media
    Route::post('/chat/upload-media', [ChatController::class, 'uploadMedia']);
});
```

---

### **3. Configurar Storage**

Archivo: `config/filesystems.php`

Asegurarse de que el disco `public` esté configurado:

```php
'disks' => [
    'public' => [
        'driver' => 'local',
        'root' => storage_path('app/public'),
        'url' => env('APP_URL').'/storage',
        'visibility' => 'public',
    ],
],
```

---

### **4. Crear Symlink (solo primera vez)**

Ejecutar en terminal:

```bash
php artisan storage:link
```

Esto crea un enlace simbólico de `storage/app/public` a `public/storage`.

---

### **5. Configurar Permisos (Servidor de Producción)**

```bash
chmod -R 755 storage
chmod -R 755 bootstrap/cache
chown -R www-data:www-data storage
chown -R www-data:www-data bootstrap/cache
```

---

## 🗂️ Estructura de Carpetas Resultante

```
storage/
└── app/
    └── public/
        └── chat/
            └── 2026/
                └── 01/
                    └── 20/
                        ├── images/
                        │   ├── abc123-uuid.jpg
                        │   └── def456-uuid.png
                        └── videos/
                            ├── ghi789-uuid.mp4
                            └── jkl012-uuid.mov
```

---

## 🔗 URLs Generadas

**Desarrollo:**
```
http://192.168.1.2:8000/storage/chat/2026/01/20/images/abc123-uuid.jpg
http://192.168.1.2:8000/storage/chat/2026/01/20/videos/ghi789-uuid.mp4
```

**Producción:**
```
https://vcamb.microwesttechnologies.com/storage/chat/2026/01/20/images/abc123-uuid.jpg
https://vcamb.microwesttechnologies.com/storage/chat/2026/01/20/videos/ghi789-uuid.mp4
```

---

## 🧪 Testing con Postman

### **Request:**
```
POST http://192.168.1.2:8000/api/v1/chat/upload-media
Headers:
  Authorization: Bearer {token}
Body (form-data):
  file: [seleccionar archivo]
  type: image  (o "video")
```

### **Response Esperado:**
```json
{
  "success": true,
  "url": "http://192.168.1.2:8000/storage/chat/2026/01/20/images/abc123-uuid.jpg",
  "type": "image",
  "size": 1234567,
  "filename": "abc123-uuid.jpg"
}
```

---

## 📝 Notas Importantes

1. **UUID:** Se usa UUID para nombres de archivo únicos y evitar colisiones
2. **Organización:** Archivos organizados por año/mes/día/tipo para mejor gestión
3. **Seguridad:** Solo usuarios autenticados pueden subir archivos
4. **Validación:** Flutter valida duración de videos (máx 1 min) antes de subir
5. **CORS:** Asegurarse de que CORS permita `multipart/form-data`

---

## 🔐 Seguridad Adicional (Opcional)

### **Limitar Rate Limiting:**

```php
// En routes/api.php
Route::middleware(['auth:sanctum', 'throttle:10,1'])->group(function () {
    Route::post('/chat/upload-media', [ChatController::class, 'uploadMedia']);
});
```

Esto limita a 10 uploads por minuto por usuario.

---

## 🚨 Troubleshooting

### **Error: "The file is not readable"**
```bash
chmod -R 755 storage
```

### **Error: "Symlink not found"**
```bash
php artisan storage:link
```

### **Error: "Disk [public] not configured"**
Verificar `config/filesystems.php` y ejecutar:
```bash
php artisan config:cache
```

---

**Fecha:** 2026-01-20  
**Feature:** Upload de imágenes y videos en chat  
**Estado:** Pendiente de implementación en backend
