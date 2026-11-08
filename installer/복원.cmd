@echo off
chcp 65001 >nul
powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -File "%~dp0patcher.ps1" -Mode Restore -RootPath "%~1"
set "MELO_EXIT=%ERRORLEVEL%"
pause
exit /b %MELO_EXIT%
