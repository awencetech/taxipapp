# Taxi Nanban - Run All Services

This folder contains scripts to easily start all Taxi Nanban services at once.

## Prerequisites

Before running, make sure you have:
- **Node.js** (for backend)
- **Flutter** (for frontends)
- At least **5 GB free space** on C: drive

## Quick Start

### Option 1: PowerShell Script (Recommended)

1. **First time only**: Install dependencies
   ```powershell
   .\setup.ps1
   ```

2. **Run all services**:
   ```powershell
   .\run-all.ps1
   ```

### Option 2: Batch File (Simpler)

Just double-click:
```
run-all.bat
```

## Services

Once started, you can access:

| Service | URL | Description |
|---------|-----|-------------|
| **Backend** | http://localhost:5000 | API server |
| **User App** | http://localhost:8000 | User frontend |
| **Driver App** | http://localhost:8001 | Driver frontend |

## Stopping Services

- **PowerShell script**: Press `Ctrl+C` in the terminal
- **Batch file**: Close each individual command window

## Troubleshooting

### "Not enough space on disk"
- Free up at least 5 GB on C: drive
- Delete temp files: `Win+R` → `%temp%` → delete everything
- Empty Recycle Bin

### Port already in use
- The scripts automatically try to clear ports, but if needed:
  - Restart your computer, or
  - Manually kill processes on ports 5000, 8000, 8001

### Flutter build fails
- Run `flutter clean` in the frontend folders
- Make sure you have enough disk space

## Files in this Folder

- `setup.ps1` - Installs all dependencies (run once)
- `run-all.ps1` - Starts all services (PowerShell)
- `run-all.bat` - Starts all services (Batch file)
- `RUN-SERVICES.md` - This file
