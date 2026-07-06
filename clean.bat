@echo off
title Laptop Cleaner
color 0A

echo ==========================================
echo           LAPTOP CLEANER TOOL
echo ==========================================
echo.
echo This script will delete useless temporary,
echo prefetch, and recycle bin files from your
echo laptop. No personal files (docs, photos,
echo videos) will be deleted.
echo.
set /p confirm="Do you want to continue? (Y/N): "
if /i not "%confirm%"=="Y" goto :end

echo.
echo [1/6] Cleaning Temp folder...
del /q /f /s "%temp%\*" >nul 2>&1

echo [2/6] Cleaning Windows Temp folder...
del /q /f /s "C:\Windows\Temp\*" >nul 2>&1

echo [3/6] Cleaning Prefetch folder...
del /q /f /s "C:\Windows\Prefetch\*" >nul 2>&1

echo [4/6] Emptying Recycle Bin...
rd /s /q C:\$Recycle.Bin >nul 2>&1

echo [5/6] Flushing DNS cache...
ipconfig /flushdns >nul 2>&1

echo [6/6] Clearing temporary internet files...
rd /s /q "%LocalAppData%\Microsoft\Windows\INetCache" >nul 2>&1

echo.
echo ==========================================
echo     CLEANING COMPLETE! Your laptop has been cleaned.
echo ==========================================
echo.

:end
pause