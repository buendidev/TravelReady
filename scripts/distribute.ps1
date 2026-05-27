<#
  distribute.ps1 — Compila APK, sube a Firebase Storage y genera QR
  Uso:
    .\scripts\distribute.ps1              (compila + sube a Storage + QR)
    .\scripts\distribute.ps1 -SkipBuild   (sube APK ya compilado + QR)
#>
param(
    [string]$Bucket = "travelready-app.firebasestorage.app",
    [string]$ApkPath = "app-release.apk",
    [switch]$SkipBuild
)

$ErrorActionPreference = "Stop"

# ── Helper: generar QR ───────────────────────────────────────────────
function _Generate-QR([string]$url) {
    $encoded = [uri]::EscapeDataString($url)
    $qrUrl   = "https://api.qrserver.com/v1/create-qr-code/?size=400x400&data=$encoded"
    $outPath = "qr_travelready.png"

    Invoke-WebRequest -Uri $qrUrl -OutFile $outPath

    Write-Host ""
    Write-Host "QR guardado en: $outPath" -ForegroundColor Green
    Write-Host "Escaneá el código con la cámara del celular para descargar la app." -ForegroundColor White

    Start-Process $outPath
}

# ── 1. Validar dependencias ──────────────────────────────────────────
function Check-Command($cmd) {
    $found = Get-Command $cmd -ErrorAction SilentlyContinue
    if (-not $found) {
        Write-Host "ERROR: '$cmd' no encontrado." -ForegroundColor Red
        exit 1
    }
}

Check-Command gsutil
if (-not $SkipBuild) { Check-Command flutter }

# ── 2. Compilar APK release (salteable) ──────────────────────────────
if (-not $SkipBuild) {
    Write-Host "Compilando APK release..." -ForegroundColor Cyan
    flutter build apk --release
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}

$apk = "build\app\outputs\flutter-apk\app-release.apk"
if (-not (Test-Path $apk)) {
    Write-Host "ERROR: APK no encontrado en $apk" -ForegroundColor Red
    exit 1
}

# ── 3. Subir a Firebase Storage (sobrescribe el anterior) ────────────
$gsPath = "gs://$Bucket/$ApkPath"
Write-Host "Subiendo a Firebase Storage: $gsPath ..." -ForegroundColor Cyan

gsutil cp $apk $gsPath
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Falló la subida a Storage. Asegurate de tener permisos." -ForegroundColor Red
    exit 1
}

# ── 4. Generar QR con URL directa de descarga ────────────────────────
# La URL publica de Firebase Storage para descarga directa
$downloadUrl = "https://firebasestorage.googleapis.com/v0/b/$Bucket/o/$([uri]::EscapeDataString($ApkPath))?alt=media"

Write-Host ""
Write-Host "=== URL de descarga directa ===" -ForegroundColor Cyan
Write-Host $downloadUrl -ForegroundColor Green

_Generate-QR $downloadUrl
