# Taxi Nanban - Run All Services Script
# This script starts backend, userfrontend, and driverfrontend

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Taxi Nanban - Starting All Services" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if Node.js is installed
try {
    $nodeVersion = node --version
    Write-Host "✓ Node.js found: $nodeVersion" -ForegroundColor Green
} catch {
    Write-Host "✗ Node.js is not installed! Please install Node.js first." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# Check if Flutter is installed
try {
    $flutterVersion = flutter --version | Select-Object -First 1
    Write-Host "✓ Flutter found" -ForegroundColor Green
} catch {
    Write-Host "✗ Flutter is not installed! Please install Flutter first." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host ""
Write-Host "Starting services..." -ForegroundColor Yellow
Write-Host ""

# Function to kill any existing processes on common ports
function Clear-Ports {
    Write-Host "Clearing existing processes on ports 5000, 8000, 8001..." -ForegroundColor Yellow
    $ports = @(5000, 8000, 8001)
    foreach ($port in $ports) {
        $processes = Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue | Select-Object -ExpandProperty OwningProcess -ErrorAction SilentlyContinue
        if ($processes) {
            foreach ($pid in $processes) {
                try {
                    Stop-Process -Id $pid -Force -ErrorAction SilentlyContinue
                    Write-Host "  Killed process on port $port" -ForegroundColor Gray
                } catch {
                    # Ignore errors
                }
            }
        }
    }
    Start-Sleep -Seconds 1
}

# Clear existing processes
Clear-Ports

Write-Host ""

# Start Backend
Write-Host "[1/3] Starting Backend..." -ForegroundColor Cyan
$backendJob = Start-Job -ScriptBlock {
    Set-Location "d:\User app\backend"
    npm run dev
} -Name "Backend"
Write-Host "  → Backend started (port 5000)" -ForegroundColor Green
Write-Host ""

# Wait a bit for backend to start
Write-Host "Waiting 3 seconds for backend to initialize..." -ForegroundColor Yellow
Start-Sleep -Seconds 3

# Start User Frontend
Write-Host "[2/3] Starting User Frontend..." -ForegroundColor Cyan
$userFrontendJob = Start-Job -ScriptBlock {
    Set-Location "d:\User app\userfrontend"
    flutter run -d chrome --web-port=8000
} -Name "UserFrontend"
Write-Host "  → User Frontend started (port 8000)" -ForegroundColor Green
Write-Host ""

# Start Driver Frontend
Write-Host "[3/3] Starting Driver Frontend..." -ForegroundColor Cyan
$driverFrontendJob = Start-Job -ScriptBlock {
    Set-Location "d:\User app\driverfrontend"
    flutter run -d chrome --web-port=8001
} -Name "DriverFrontend"
Write-Host "  → Driver Frontend started (port 8001)" -ForegroundColor Green
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  All services started successfully!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Services:" -ForegroundColor Yellow
Write-Host "  • Backend:     http://localhost:5000" -ForegroundColor White
Write-Host "  • User App:    http://localhost:8000" -ForegroundColor White
Write-Host "  • Driver App:  http://localhost:8001" -ForegroundColor White
Write-Host ""
Write-Host "Press Ctrl+C to stop all services" -ForegroundColor Yellow
Write-Host ""

# Monitor jobs
try {
    while ($true) {
        # Check if any job has stopped
        $allJobs = Get-Job
        foreach ($job in $allJobs) {
            if ($job.State -eq "Completed" -or $job.State -eq "Failed") {
                Write-Host ""
                Write-Host "⚠️  $($job.Name) has stopped!" -ForegroundColor Red
                Write-Host "   State: $($job.State)" -ForegroundColor Gray
                Write-Host ""
            }
        }
        
        Start-Sleep -Seconds 5
    }
} finally {
    # Cleanup on exit
    Write-Host ""
    Write-Host "Stopping all services..." -ForegroundColor Yellow
    
    # Stop all jobs
    Get-Job | Stop-Job -PassThru | Remove-Job -Force
    
    # Clear ports again
    Clear-Ports
    
    Write-Host "✓ All services stopped." -ForegroundColor Green
}
