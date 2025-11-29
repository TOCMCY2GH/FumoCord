@echo off
cls

set "CURRENT_DIR=%~dp0"
for %%a in ("%CURRENT_DIR%\..") do set "PROJECT_ROOT=%%~fa"
if "%PROJECT_ROOT:~-1%"=="\" set "PROJECT_ROOT=%PROJECT_ROOT:~0,-1%"
set "WEZ=%PROJECT_ROOT%\WezTerm\wezterm.exe"

start "" "%WEZ%" start -- cmd /K "cd /d %PROJECT_ROOT% && chcp 65001 & dart run bin\admin.dart"

exit
