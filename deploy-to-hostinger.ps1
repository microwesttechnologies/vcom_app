param(
    [string]$HostName = "195.35.41.137",
    [string]$UserName = "u963527317",
    [int]$Port = 65002,
    # Ruta exacta vista en el File Manager: root / public_html / vcom-app
    [string]$RemoteDir = "/home/u963527317/public_html/vcom-app",
    [string]$RemoteArchive = "/home/u963527317/vcom-app-web.tar.gz",
    [switch]$SkipBuild,
    [switch]$SkipHostKeyCheck = $true
)

$ErrorActionPreference = "Stop"

function Require-Command {
    param([string]$Name)
    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        throw "No se encontro el comando requerido: $Name"
    }
}

Require-Command scp
Require-Command ssh
Require-Command tar
Require-Command flutter

function Invoke-ExternalChecked {
    param(
        [Parameter(Mandatory = $true)][string]$FilePath,
        [Parameter(Mandatory = $false)][string[]]$Arguments = @()
    )

    & $FilePath @Arguments
    if ($LASTEXITCODE -ne 0) {
        $joinedArgs = if ($Arguments.Count -gt 0) { $Arguments -join " " } else { "" }
        throw "Command failed ($LASTEXITCODE): $FilePath $joinedArgs"
    }
}

$isWindows = $true
try {
    $isWindows = [System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform(
        [System.Runtime.InteropServices.OSPlatform]::Windows
    )
} catch {
    $isWindows = $true
}

$nullKnownHostsPath = if ($isWindows) { "NUL" } else { "/dev/null" }
$sshArgs = @("-p", "$Port")
$scpArgs = @("-P", "$Port")
if ($SkipHostKeyCheck) {
    $sshArgs += @("-o", "StrictHostKeyChecking=no", "-o", "UserKnownHostsFile=$nullKnownHostsPath")
    $scpArgs += @("-o", "StrictHostKeyChecking=no", "-o", "UserKnownHostsFile=$nullKnownHostsPath")
}

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$webBuildDir = Join-Path $projectRoot "build\web"
$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) "vcom-app-hostinger-deploy"
$archivePath = Join-Path $tempRoot "vcom-app-web.tar.gz"

Write-Host "Proyecto: $projectRoot"
Write-Host "Destino:  ${UserName}@${HostName}:${Port} -> $RemoteDir"

if (-not $SkipBuild) {
    Write-Host "Compilando Flutter web (Hostinger / PWA)..."
    Push-Location $projectRoot
    try {
        Invoke-ExternalChecked -FilePath "flutter" -Arguments @(
            "build", "web",
            "--release",
            "--no-wasm-dry-run",
            "--base-href", "/",
            "--dart-define=FIREBASE_API_KEY=AIzaSyCAM3Ar85ckVjVI04l90rAX5zd9JfgnTYE",
            "--dart-define=FIREBASE_APP_ID=1:395194182340:web:ca0f33b5c79d63dc833791",
            "--dart-define=FIREBASE_MESSAGING_SENDER_ID=395194182340",
            "--dart-define=FIREBASE_PROJECT_ID=vcom-chat",
            "--dart-define=FIREBASE_AUTH_DOMAIN=vcom-chat.firebaseapp.com",
            "--dart-define=FIREBASE_STORAGE_BUCKET=vcom-chat.firebasestorage.app",
            "--dart-define=FIREBASE_VAPID_KEY=BPv-BPPNJjSfPJaHcCFsqjP1t3NQCLjS6PVyX0vm5W1uFdtNnAd5Fiw5sKmS7M2GmDWau3NGqzyarHBFUfbNZPY"
        )
    }
    finally {
        Pop-Location
    }

    $htaccess = Join-Path $projectRoot "web\.htaccess"
    $firebaseConfig = Join-Path $projectRoot "web\firebase-config.js"
    $firebaseSw = Join-Path $projectRoot "web\firebase-messaging-sw.js"
    if (Test-Path $htaccess) { Copy-Item $htaccess (Join-Path $webBuildDir ".htaccess") -Force }
    if (Test-Path $firebaseConfig) { Copy-Item $firebaseConfig (Join-Path $webBuildDir "firebase-config.js") -Force }
    if (Test-Path $firebaseSw) { Copy-Item $firebaseSw (Join-Path $webBuildDir "firebase-messaging-sw.js") -Force }
}

if (-not (Test-Path (Join-Path $webBuildDir "index.html"))) {
    throw "No existe build web en $webBuildDir. Corre sin -SkipBuild o ejecuta tool\build_hostinger.bat"
}

if (Test-Path $tempRoot) {
    Remove-Item -LiteralPath $tempRoot -Recurse -Force
}
New-Item -ItemType Directory -Path $tempRoot | Out-Null

Write-Host "Empaquetando build\web ..."
Push-Location $webBuildDir
try {
    Invoke-ExternalChecked -FilePath "tar" -Arguments @("-czf", $archivePath, ".")
}
finally {
    Pop-Location
}

Write-Host ("Subiendo a {0}@{1}:{2}" -f $UserName, $HostName, $RemoteArchive)
Invoke-ExternalChecked -FilePath "scp" -Arguments ($scpArgs + @($archivePath, "${UserName}@${HostName}:$RemoteArchive"))

$remoteScript = @'
set -e
mkdir -p '__REMOTE_DIR__'
# Limpia contenido previo sin borrar la carpeta
find '__REMOTE_DIR__' -mindepth 1 -maxdepth 1 -exec rm -rf {} +
tar -xzf '__REMOTE_ARCHIVE__' -C '__REMOTE_DIR__'
rm -f '__REMOTE_ARCHIVE__'
find '__REMOTE_DIR__' -type d -exec chmod 755 {} \;
find '__REMOTE_DIR__' -type f -exec chmod 644 {} \;
echo "Deploy OK -> '__REMOTE_DIR__'"
ls -la '__REMOTE_DIR__' | head -n 25
'@

$remoteScript = $remoteScript.Replace("__REMOTE_DIR__", $RemoteDir)
$remoteScript = $remoteScript.Replace("__REMOTE_ARCHIVE__", $RemoteArchive)
# Bash rechaza CRLF de Windows
$remoteScript = $remoteScript -replace "`r`n", "`n" -replace "`r", "`n"

Write-Host "Extrayendo en Hostinger..."
Invoke-ExternalChecked -FilePath "ssh" -Arguments ($sshArgs + @("${UserName}@${HostName}", $remoteScript))

Write-Host "Proceso completado."
Write-Host "Verifica: https://vcom-app.microwesttechnologies.com/"
