@echo off
setlocal EnableDelayedExpansion
title Laptop Cleaner PRO

:: ============================================
::  Auto Admin Elevation
:: ============================================
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Requesting Administrator permissions...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

set LOGFILE=%~dp0cleaner_log.txt
echo Laptop Cleaner PRO - Log %date% %time% > "%LOGFILE%"

:menu
cls
color 0B
echo ==========================================
echo         LAPTOP CLEANER PRO
echo ==========================================
echo.
echo   1. Quick Clean (Temp + Prefetch + Recycle Bin)
echo   2. Full Clean (Quick Clean + Update Cache + Thumbnails + DNS)
echo   3. Repair Windows System Files (SFC + DISM)
echo   4. Clear Microsoft Store Cache
echo   5. Show Disk Space Report
echo   6. Run EVERYTHING (Full Clean + Repair)
echo   0. Exit
echo.
set /p choice="Enter option number: "

if "%choice%"=="1" goto quickclean
if "%choice%"=="2" goto fullclean
if "%choice%"=="3" goto repair
if "%choice%"=="4" goto storecache
if "%choice%"=="5" goto diskreport
if "%choice%"=="6" goto everything
if "%choice%"=="0" goto end
goto menu

:quickclean
echo.
echo [*] Cleaning Temp folder...
del /q /f /s "%temp%\*" >nul 2>&1
echo Cleaned: User Temp >> "%LOGFILE%"

echo [*] Cleaning Windows Temp folder...
del /q /f /s "C:\Windows\Temp\*" >nul 2>&1
echo Cleaned: Windows Temp >> "%LOGFILE%"

echo [*] Cleaning Prefetch...
del /q /f /s "C:\Windows\Prefetch\*" >nul 2>&1
echo Cleaned: Prefetch >> "%LOGFILE%"

echo [*] Emptying Recycle Bin...
rd /s /q C:\$Recycle.Bin >nul 2>&1
echo Cleaned: Recycle Bin >> "%LOGFILE%"

echo.
echo Quick Clean complete!
pause
goto menu

:fullclean
call :quickclean_silent

echo [*] Clearing Windows Update cache...
net stop wuauserv >nul 2>&1
rd /s /q "C:\Windows\SoftwareDistribution\Download" >nul 2>&1
net start wuauserv >nul 2>&1
echo Cleaned: Windows Update Cache >> "%LOGFILE%"

echo [*] Clearing Thumbnail cache...
del /q /f "%LocalAppData%\Microsoft\Windows\Explorer\thumbcache_*.db" >nul 2>&1
echo Cleaned: Thumbnail Cache >> "%LOGFILE%"

echo [*] Flushing DNS cache...
ipconfig /flushdns >nul 2>&1
echo Cleaned: DNS Cache >> "%LOGFILE%"

echo.
echo Full Clean complete!
pause
goto menu

:quickclean_silent
del /q /f /s "%temp%\*" >nul 2>&1
del /q /f /s "C:\Windows\Temp\*" >nul 2>&1
del /q /f /s "C:\Windows\Prefetch\*" >nul 2>&1
rd /s /q C:\$Recycle.Bin >nul 2>&1
echo Cleaned: Quick Clean items >> "%LOGFILE%"
exit /b

:repair
echo.
echo [*] Running SFC scan (this may take a few minutes)...
sfc /scannow
echo Ran: SFC Scan >> "%LOGFILE%"
echo [*] Running DISM repair...
DISM /Online /Cleanup-Image /RestoreHealth
echo Ran: DISM Repair >> "%LOGFILE%"
echo.
echo Repair complete!
pause
goto menu

:storecache
echo.
echo [*] Clearing Microsoft Store cache...
wsreset.exe
echo Cleaned: MS Store Cache >> "%LOGFILE%"
pause
goto menu

:diskreport
echo.
wmic logicaldisk get name,description,filesystem,freespace,size
echo.
pause
goto menu

:everything
call :quickclean_silent
echo [*] Clearing Windows Update cache...
net stop wuauserv >nul 2>&1
rd /s /q "C:\Windows\SoftwareDistribution\Download" >nul 2>&1
net start wuauserv >nul 2>&1
echo [*] Clearing Thumbnail cache...
del /q /f "%LocalAppData%\Microsoft\Windows\Explorer\thumbcache_*.db" >nul 2>&1
echo [*] Flushing DNS...
ipconfig /flushdns >nul 2>&1
echo [*] Running SFC...
sfc /scannow
echo [*] Running DISM...
DISM /Online /Cleanup-Image /RestoreHealth
echo Ran: EVERYTHING >> "%LOGFILE%"
echo.
echo Everything cleaned and repaired!
pause
goto menu

:end
echo.
echo Log file saved: %LOGFILE%
echo Laptop Cleaner is closing. Goodbye!
timeout /t 3 >nul
exit