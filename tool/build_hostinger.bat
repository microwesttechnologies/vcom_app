@echo off
setlocal
cd /d "%~dp0.."
echo Compilando VCOM para Hostinger...
call flutter build web --release --no-wasm-dry-run --base-href "/"
if errorlevel 1 exit /b 1

copy /Y "web\.htaccess" "build\web\.htaccess" >nul

if not exist "dist" mkdir "dist"
powershell -NoProfile -Command "Compress-Archive -Path 'build\web\*' -DestinationPath 'dist\vcom_app_hostinger.zip' -Force"

echo.
echo Listo:
echo   Carpeta: build\web
echo   ZIP:     dist\vcom_app_hostinger.zip
echo.
echo Sube TODO el contenido de build\web a public_html en Hostinger.
endlocal
