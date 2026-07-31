# Taxi Nanban - Setup Script
# Installs all dependencies for backend and frontends

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Taxi Nanban - Setup Dependencies" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check Node.js
try {
    $nodeVersion = node --version
    Write-Host "✓ Node.js: $nodeVersion" -ForegroundColor Green
} catch {
    Write-Host "✗ Node.js is not installed!" -ForegroundColor Red
    Write-Host "  Please install Node.js from https://nodejs.org/" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

# Check Flutter
try {
    $flutterVersion = flutter --version | Select-Object -First 1
    Write-Host "✓ Flutter: $flutterVersion" -ForegroundColor Green
} catch {
    Write-Host "✗ Flutter is not installed!" -ForegroundColor Red
    Write-Host "  Please install Flutter from https://flutter.dev/" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host ""
Write-Host "Installing dependencies..." -ForegroundColor Yellow
Write-Host ""

# Install Backend Dependencies
Write-Host "[1/3] Installing Backend dependencies..." -ForegroundColor Cyan
Set-Location "d:\User app\backend"
npm install
if ($LASTEXITCODE -eq 0) {
    Write-Host "  ✓ Backend dependencies installed" -ForegroundColor Green
} else {
    Write-Host "  ✗ Failed to install backend dependencies" -ForegroundColor Red
}
Write-Host ""

# Install User Frontend Dependencies
Write-Host "[2/3] Installing User Frontend dependencies..." -ForegroundColor Cyan
Set-Location "d:\User app\userfrontend"
flutter pub get
if ($LASTEXITCODE -eq 0) {
    Write-Host "  ✓ User Frontend dependencies installed" -ForegroundColor Green
} else {
    Write-Host "  ✗ Failed to install user frontend dependencies" -ForegroundColor Red
}
Write-Host ""

# Install Driver Frontend Dependencies
Write-Host "[3/3] Installing Driver Frontend dependencies..." -ForegroundColor Cyan
Set-Location "d:\User app\driverfrontend"
flutter pub get
if ($LASTEXITCODE -eq 0) {
    Write-Host "  ✓ Driver Frontend dependencies installed" -ForegroundColor Green
} else {
    Write-Host "  ✗ Failed to install driver frontend dependencies" -ForegroundColor Red
}
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Setup complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "To run all services:" -ForegroundColor Yellow
Write-Host "  .\run-all.ps1" -ForegroundColor White
Write-Host ""
Write-Host "Or use the batch file:" -ForegroundColor Yellow
Write-Host "  run-all.bat" -ForegroundColor White
Write-Host ""
Read-Host "Press Enter to exit"
