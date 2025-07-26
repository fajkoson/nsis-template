@echo off
setlocal

:: === Config ===
set NSIS_EXE="C:\Program Files\NSIS\makensis.exe"
set NSIS_SCRIPT=nsis\installer.nsi

if not exist out\bin (
    mkdir out\bin
)

:: === Run NSIS ===
%NSIS_EXE% %NSIS_SCRIPT%

if errorlevel 1 (
    echo [E] NSIS failed.
    pause
    exit /b 1
)

echo [I] Package created successfully.
pause
exit /b 0
