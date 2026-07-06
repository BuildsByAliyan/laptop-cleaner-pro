@echo off
setlocal EnableDelayedExpansion
title Laptop Cleaner PRO v2

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
echo Laptop Cleaner PRO v2 - Log %date% %time% > "%LOGFILE%"

:menu
cls
color 0B
echo ==========================================
echo         LAPTOP CLEANER PRO v2
echo ==========================================
echo.
echo   1. Quick Clean (Temp + Prefetch + Recycle Bin)
echo   2. Full Clean (Quick Clean + Update Cache + Thumbnails + DNS)
echo   3. Preview Mode / Dry-Run (shows what will be deleted, then asks)
echo   4. Browser Cache Cleaner (Chrome + Edge - safe)
echo   5. Duplicate Files Finder (lists only, no deletion)
echo   6. Repair Windows System Files (SFC + DISM)
echo   7. Clear Microsoft Store Cache
echo   8. Show Disk Space Report
echo   9. Run EVERYTHING (Full Clean + Repair)
echo   0. Exit
echo.
set /p choice="Enter option number: "

if "%choice%"=="1" goto quickclean
if "%choice%"=="2" goto fullclean
if "%choice%"=="3" goto previewmode
if "%choice%"=="4" goto browsercache
if "%choice%"=="5" goto dupfinder
if "%choice%"=="6" goto repair
if "%choice%"=="7" goto storecache
if "%choice%"=="8" goto diskreport
if "%choice%"=="9" goto everything
if "%choice%"=="0" goto end
goto menu

:: ============================================
::  Helper: Calculate free space (in GB), C: drive
:: ============================================
:getfreespace
set FREESPACE=
powershell -NoProfile -Command "[math]::Round((Get-PSDrive C -ErrorAction SilentlyContinue).Free/1GB,2)" > "%TEMP%\lcp_freespace.txt" 2>nul
set /p FREESPACE=<"%TEMP%\lcp_freespace.txt"
if not defined FREESPACE set FREESPACE=0
exit /b

:: ============================================
::  1. QUICK CLEAN (with Before/After report)
:: ============================================
:quickclean
call :getfreespace
set FREEBEFORE=%FREESPACE%
echo.
echo [*] Starting cleanup, please wait...
call :quickclean_silent
call :getfreespace
set FREEAFTER=%FREESPACE%
call :showreport
echo Quick Clean complete!
pause
goto menu

:: ============================================
::  2. FULL CLEAN (with Before/After report)
:: ============================================
:fullclean
call :getfreespace
set FREEBEFORE=%FREESPACE%
echo.
echo [*] Starting Full Clean...
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

call :getfreespace
set FREEAFTER=%FREESPACE%
call :showreport
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

:: ============================================
::  Helper: Display Before/After report
:: ============================================
:showreport
echo.
echo ==========================================
echo         DISK SPACE REPORT
echo ==========================================
echo   Before:  %FREEBEFORE% GB free
echo   After:   %FREEAFTER% GB free
powershell -NoProfile -Command "$b=0.0;$a=0.0;[double]::TryParse($env:FREEBEFORE,[ref]$b) | Out-Null;[double]::TryParse($env:FREEAFTER,[ref]$a) | Out-Null;$d=[math]::Round($a-$b,2); if($d -lt 0){$d=0}; Write-Host '  ------------------------------------'; Write-Host \"  Total Space Freed: $d GB\""
echo ==========================================
echo Report: Before=%FREEBEFORE%GB After=%FREEAFTER%GB >> "%LOGFILE%"
echo.
exit /b

:: ============================================
::  3. PREVIEW MODE / DRY-RUN
:: ============================================
:previewmode
cls
echo ==========================================
echo     PREVIEW MODE (DRY-RUN)
echo ==========================================
echo.
echo [*] Checking what will be deleted...
echo     (Nothing is being deleted yet, this is a preview only)
echo.

powershell -NoProfile -Command ^
 "$folders = @($env:TEMP, 'C:\Windows\Temp', 'C:\Windows\Prefetch');" ^
 "$totalSize=0; $totalCount=0;" ^
 "foreach($f in $folders) {" ^
 "  if(Test-Path $f) {" ^
 "    $items = Get-ChildItem -Path $f -Recurse -Force -ErrorAction SilentlyContinue;" ^
 "    $size = ($items | Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum;" ^
 "    $count = $items.Count;" ^
 "    if(-not $size){$size=0};" ^
 "    $totalSize += $size; $totalCount += $count;" ^
 "    Write-Host (\"  {0,-30} {1,6} files   {2,8:N2} MB\" -f $f, $count, ($size/1MB));" ^
 "  }" ^
 "}" ^
 "Write-Host '';" ^
 "Write-Host (\"  TOTAL: {0} files, {1:N2} MB ({2:N2} GB)\" -f $totalCount, ($totalSize/1MB), ($totalSize/1GB));"

echo.
echo   The Recycle Bin will also be emptied (its size is not included above).
echo.
set /p confirmdel="Delete all of this now? (Y/N): "
if /i "%confirmdel%"=="Y" (
    echo.
    echo [*] Confirmed, deleting now...
    call :getfreespace
    set FREEBEFORE=%FREESPACE%
    call :quickclean_silent
    call :getfreespace
    set FREEAFTER=%FREESPACE%
    call :showreport
    echo Preview Mode cleanup complete!
) else (
    echo.
    echo [*] Cancelled. Nothing was deleted.
)
pause
goto menu

:: ============================================
::  4. BROWSER CACHE CLEANER (Chrome + Edge)
:: ============================================
:browsercache
cls
echo ==========================================
echo     BROWSER CACHE CLEANER
echo ==========================================
echo.
echo   This will only clean the CACHE.
echo   Cookies, Saved Passwords, History, Bookmarks
echo   will not be touched. 100%% safe.
echo.
echo   Please close both Chrome and Edge first, otherwise
echo   some files may be locked and skipped.
echo.
pause

call :getfreespace
set FREEBEFORE=%FREESPACE%

echo [*] Cleaning Chrome cache...
del /q /f /s "%LocalAppData%\Google\Chrome\User Data\Default\Cache\*" >nul 2>&1
del /q /f /s "%LocalAppData%\Google\Chrome\User Data\Default\Code Cache\*" >nul 2>&1
echo Cleaned: Chrome Cache >> "%LOGFILE%"

echo [*] Cleaning Edge cache...
del /q /f /s "%LocalAppData%\Microsoft\Edge\User Data\Default\Cache\*" >nul 2>&1
del /q /f /s "%LocalAppData%\Microsoft\Edge\User Data\Default\Code Cache\*" >nul 2>&1
echo Cleaned: Edge Cache >> "%LOGFILE%"

call :getfreespace
set FREEAFTER=%FREESPACE%
call :showreport
echo Browser Cache Clean complete!
pause
goto menu

:: ============================================
::  5. DUPLICATE FILES FINDER (list only, no delete)
:: ============================================
:dupfinder
cls
echo ==========================================
echo     DUPLICATE FILES FINDER
echo ==========================================
echo.
echo   This will NOT delete any files.
echo   It will only show a list of duplicate files,
echo   the decision to delete them is yours.
echo.
set /p scanfolder="Which folder do you want to scan? (enter full path, e.g. D:\Downloads): "

if not exist "%scanfolder%" (
    echo.
    echo [!] Folder not found. Please check the path.
    pause
    goto menu
)

echo.
echo [*] Scanning, larger folders will take more time...
echo.

powershell -NoProfile -Command ^
 "$path = '%scanfolder%';" ^
 "$files = Get-ChildItem -Path $path -Recurse -File -ErrorAction SilentlyContinue;" ^
 "Write-Host (\"Total files scanned: {0}\" -f $files.Count);" ^
 "Write-Host '';" ^
 "$groups = $files | Group-Object Length | Where-Object {$_.Count -gt 1};" ^
 "$dupFound = $false;" ^
 "foreach($g in $groups) {" ^
 "  $hashGroups = $g.Group | Get-FileHash -ErrorAction SilentlyContinue | Group-Object Hash | Where-Object {$_.Count -gt 1};" ^
 "  foreach($hg in $hashGroups) {" ^
 "    $dupFound = $true;" ^
 "    Write-Host '---- Duplicate Group ----';" ^
 "    foreach($item in $hg.Group) { Write-Host ('  ' + $item.Path) };" ^
 "    Write-Host '';" ^
 "  }" ^
 "}" ^
 "if(-not $dupFound) { Write-Host 'No duplicate files found.' }"

echo.
echo Duplicate scan complete. No files were deleted, please review the list above.
echo Duplicate Finder run kiya on: %scanfolder% >> "%LOGFILE%"
pause
goto menu

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
call :getfreespace
set FREEBEFORE=%FREESPACE%
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
call :getfreespace
set FREEAFTER=%FREESPACE%
call :showreport
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