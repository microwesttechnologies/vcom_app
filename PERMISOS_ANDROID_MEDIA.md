# 📱 Permisos de Android para Cámara y Galería

## 🎯 Configuración Necesaria

Para que la app pueda acceder a la cámara y galería, necesitas configurar los permisos en Android.

---

## 📁 Archivo: `android/app/src/main/AndroidManifest.xml`

Agregar los siguientes permisos dentro del tag `<manifest>`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.example.vcom_app">
    
    <!-- Permisos para cámara y galería -->
    <uses-permission android:name="android.permission.CAMERA" />
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" 
                     android:maxSdkVersion="32" />
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" 
                     android:maxSdkVersion="29" />
    
    <!-- Para Android 13+ (API 33+) -->
    <uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
    <uses-permission android:name="android.permission.READ_MEDIA_VIDEO" />
    
    <!-- Declarar que la cámara es opcional (no obligatoria para instalar) -->
    <uses-feature android:name="android.hardware.camera" 
                  android:required="false" />
    <uses-feature android:name="android.hardware.camera.autofocus" 
                  android:required="false" />

    <application
        ...
    </application>
</manifest>
```

---

## 📝 Explicación de Permisos

| Permiso | Propósito | Android Version |
|---------|-----------|----------------|
| `CAMERA` | Acceso a la cámara para tomar fotos/videos | Todas |
| `READ_EXTERNAL_STORAGE` | Leer imágenes/videos de la galería | API ≤ 32 |
| `WRITE_EXTERNAL_STORAGE` | Guardar fotos/videos | API ≤ 29 |
| `READ_MEDIA_IMAGES` | Leer imágenes específicamente | API ≥ 33 (Android 13+) |
| `READ_MEDIA_VIDEO` | Leer videos específicamente | API ≥ 33 (Android 13+) |

---

## 🔧 Solicitud de Permisos en Runtime

El paquete `image_picker` maneja automáticamente la solicitud de permisos en runtime, pero para mayor control, puedes usar `permission_handler`:

### **Opcional: Agregar permission_handler**

```yaml
# pubspec.yaml
dependencies:
  permission_handler: ^11.0.0
```

### **Ejemplo de uso:**

```dart
import 'package:permission_handler/permission_handler.dart';

Future<bool> requestCameraPermission() async {
  final status = await Permission.camera.request();
  return status.isGranted;
}

Future<bool> requestGalleryPermission() async {
  if (await Permission.photos.isGranted) {
    return true;
  }
  
  final status = await Permission.photos.request();
  return status.isGranted;
}
```

---

## 🧪 Testing

1. **Desinstalar la app del dispositivo/emulador**
2. **Rebuild completo:**
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```
3. **Al intentar tomar foto/video o seleccionar de galería:**
   - Debe aparecer un diálogo pidiendo permisos
   - Aceptar los permisos
   - La funcionalidad debe funcionar correctamente

---

## 🚨 Troubleshooting

### **Error: "Permission denied"**
- Verificar que los permisos estén en `AndroidManifest.xml`
- Desinstalar y reinstalar la app
- En configuración del dispositivo, verificar que la app tenga permisos

### **Error: "No camera found"**
- Agregar `<uses-feature android:name="android.hardware.camera" android:required="false" />`
- En emulador, verificar que la cámara virtual esté habilitada

### **La galería no muestra imágenes recientes**
- Para Android 13+, asegurarse de tener `READ_MEDIA_IMAGES` y `READ_MEDIA_VIDEO`
- Reiniciar la app después de otorgar permisos

---

**Nota:** Estos cambios solo afectan a Android. iOS tiene su propia configuración en `Info.plist`.
