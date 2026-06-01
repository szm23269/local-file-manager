@echo off
setlocal

set "INSTALL_DIR=%LOCALAPPDATA%\Filie"
set "SCRIPT_DIR=%~dp0"

echo.
echo ================================================
echo   Filie Installer for Windows
echo ================================================
echo.

:: Check Python
python --version >nul 2>&1
if %errorlevel% equ 0 (
    set "PYTHON_CMD=python"
    goto :python_found
)
py --version >nul 2>&1
if %errorlevel% equ 0 (
    set "PYTHON_CMD=py"
    goto :python_found
)

echo [ERROR] Python not found.
echo Please install Python 3.10 or later from:
echo   https://www.python.org/downloads/
echo.
echo IMPORTANT: Check "Add Python to PATH" during installation!
pause
exit /b 1

:python_found
for /f "tokens=2 delims= " %%v in ('"%PYTHON_CMD%" --version 2^>^&1') do set PY_VER=%%v
echo [OK] Python %PY_VER% found.

echo.
echo Installing to: %INSTALL_DIR%
if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%"

copy /y "%SCRIPT_DIR%server.py"         "%INSTALL_DIR%\server.py"         >nul
copy /y "%SCRIPT_DIR%index.html"        "%INSTALL_DIR%\index.html"        >nul
copy /y "%SCRIPT_DIR%requirements.txt"  "%INSTALL_DIR%\requirements.txt"  >nul

echo.
echo Creating virtual environment...
"%PYTHON_CMD%" -m venv "%INSTALL_DIR%\venv"

echo Installing packages...
"%INSTALL_DIR%\venv\Scripts\pip" install --upgrade pip -q
"%INSTALL_DIR%\venv\Scripts\pip" install -r "%INSTALL_DIR%\requirements.txt" -q
echo [OK] Packages installed.

:: Create launcher batch
set "LAUNCH_BAT=%INSTALL_DIR%\launch.bat"
(
    echo @echo off
    echo cd /d "%INSTALL_DIR%"
    echo start "" "%INSTALL_DIR%\venv\Scripts\python.exe" server.py
    echo timeout /t 2 /nobreak ^>nul
    echo start http://127.0.0.1:8000
) > "%LAUNCH_BAT%"

:: Create desktop shortcut via PowerShell
set "DESKTOP_LINK=%USERPROFILE%\Desktop\Filie.lnk"
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$ws=New-Object -ComObject WScript.Shell;" ^
  "$s=$ws.CreateShortcut('%DESKTOP_LINK%');" ^
  "$s.TargetPath='%LAUNCH_BAT%';" ^
  "$s.WorkingDirectory='%INSTALL_DIR%';" ^
  "$s.Description='Filie';" ^
  "$s.Save()"

echo.
echo ================================================
echo   Installation complete!
echo ================================================
echo.
echo How to launch Filie:
echo   Double-click the "Filie" shortcut on your Desktop
echo   or run directly: %LAUNCH_BAT%
echo.
echo To uninstall, delete this folder:
echo   %INSTALL_DIR%
echo.
pause
