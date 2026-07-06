@echo off
setlocal
cd /d "%~dp0.."
echo Compilando VCOM para Hostinger (PWA + Firebase push)...

call flutter build web --release --no-wasm-dry-run --base-href "/" --dart-define=FIREBASE_API_KEY=AIzaSyCAM3Ar85ckVjVI04l90rAX5zd9JfgnTYE --dart-define=FIREBASE_APP_ID=1:395194182340:web:ca0f33b5c79d63dc833791 --dart-define=FIREBASE_MESSAGING_SENDER_ID=395194182340 --dart-define=FIREBASE_PROJECT_ID=vcom-chat --dart-define=FIREBASE_AUTH_DOMAIN=vcom-chat.firebaseapp.com --dart-define=FIREBASE_STORAGE_BUCKET=vcom-chat.firebasestorage.app --dart-define=FIREBASE_VAPID_KEY=BPv-BPPNJjSfPJaHcCFsqjP1t3NQCLjS6PVyX0vm5W1uFdtNnAd5Fiw5sKmS7M2GmDWau3NGqzyarHBFUfbNZPY
if errorlevel 1 exit /b 1

copy /Y "web\.htaccess" "build\web\.htaccess" >nul
copy /Y "web\firebase-config.js" "build\web\firebase-config.js" >nul
copy /Y "web\firebase-messaging-sw.js" "build\web\firebase-messaging-sw.js" >nul

if not exist "dist" mkdir "dist"
powershell -NoProfile -Command "Compress-Archive -Path 'build\web\*' -DestinationPath 'dist\vcom_app_hostinger.zip' -Force"

echo.
echo Listo:
echo   Carpeta: build\web
echo   ZIP:     dist\vcom_app_hostinger.zip
echo.
echo Sube TODO el contenido de build\web a public_html en Hostinger.
echo Verifica en Firebase dominios autorizados: vcom-app.microwesttechnologies.com
endlocal
