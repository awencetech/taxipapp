@echo off
chcp 65001 >nul
echo ========================================
echo   Taxi Nanban - Starting All Services
echo ========================================
echo.

echo [1/3] Starting Backend...
start "Backend" cmd /k "cd /d d:\User app\backend && npm run dev"

echo Waiting 5 seconds for backend to start...
timeout /t 5 /nobreak >nul

echo [2/3] Starting User Frontend...
start "User Frontend" cmd /k "cd /d d:\User app\userfrontend && flutter run -d chrome --web-port=8000"

echo [3/3] Starting Driver Frontend...
start "Driver Frontend" cmd /k "cd /d d:\User app\driverfrontend && flutter run -d chrome --web-port=8001"

echo.
echo ========================================
echo   All services started!
echo ========================================
echo.
echo Services:
echo   - Backend:     http://localhost:5000
echo   - User App:    http://localhost:8000
echo   - Driver App:  http://localhost:8001
echo.
echo Press any key to close this window (services will continue running)
pause >nul
