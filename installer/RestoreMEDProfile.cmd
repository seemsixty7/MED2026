@echo off
setlocal
title Restore MED Profile
echo.
echo  Restore MED Profile
echo  ==================
echo  Creates or repairs the AutoCAD profile named MED2026
echo  (Support path + trusted folder). Close AutoCAD first.
echo.
set "ROOT=%~dp0"
if "%ROOT:~-1%"=="\" set "ROOT=%ROOT:~0,-1%"
set "PS1=%ROOT%\installer\Install-MED2026.ps1"
if not exist "%PS1%" (
  echo ERROR: Missing %PS1%
  echo Run this from your MED2026 install folder.
  echo.
  pause
  exit /b 1
)
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%PS1%" -InstallDir "%ROOT%" -Provider SQLite -SkipCopy
set ERR=%ERRORLEVEL%
echo.
if %ERR% neq 0 (
  echo Restore failed. See log: %ROOT%\installer\Install-MED2026.log
) else (
  echo Done. Use the MED2026 AutoCAD desktop shortcut to launch.
)
echo.
pause
endlocal & exit /b %ERR%