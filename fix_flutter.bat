
@echo off
REM Fix PATH issues
SET PATH=C:\Windows\System32;C:\Windows;C:\Program Files\Git\cmd;C:\Program Files\Git\bin;C:\flutter\bin;C:\Program Files\nodejs;%PATH%
ECHO PATH has been fixed!
ECHO.

where.exe git
ECHO.
where.exe flutter
ECHO.
git --version
ECHO.
flutter --version
ECHO.
cd /d d:\taxinanpan\vendorfrontend
ECHO Running flutter doctor...
flutter doctor -v
