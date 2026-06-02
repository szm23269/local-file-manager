@echo off
setlocal

set "INSTALL_DIR=%LOCALAPPDATA%\Filie"
set "SCRIPT_DIR=%~dp0"
set "PYTHON_VER=3.12.7"
set "PYTHON_URL=https://www.python.org/ftp/python/%PYTHON_VER%/python-%PYTHON_VER%-amd64.exe"

echo.
echo ================================================
echo   Filie Installer for Windows
echo ================================================
echo.

:: ── Check Python ─────────────────────────────────────
python --version >nul 2>&1
if %errorlevel% equ 0 ( set "PYTHON_CMD=python" & goto :python_found )
py --version >nul 2>&1
if %errorlevel% equ 0 ( set "PYTHON_CMD=py"     & goto :python_found )

:: ── Python not found: auto install ───────────────────
echo [INFO] Python not found. Installing automatically...
echo.

:: Try winget (Windows 10 1709+ / Windows 11)
winget --version >nul 2>&1
if %errorlevel% equ 0 (
    echo [INFO] Installing Python via Windows Package Manager...
    winget install -e --id Python.Python.3.12 --silent ^
        --accept-package-agreements --accept-source-agreements
    echo [INFO] Winget install done.
    goto :find_python
)

:: Fallback: download official installer
echo [INFO] Downloading Python %PYTHON_VER% installer...
echo       This may take a few minutes.
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "Invoke-WebRequest -Uri '%PYTHON_URL%' -OutFile '%TEMP%\python_setup.exe' -UseBasicParsing"
echo [INFO] Running Python installer silently...
"%TEMP%\python_setup.exe" /quiet InstallAllUsers=0 PrependPath=1 /norestart
del "%TEMP%\python_setup.exe" >nul 2>&1

:find_python
:: Search common install locations after auto-install
for %%D in (
    "%LOCALAPPDATA%\Programs\Python\Python313"
    "%LOCALAPPDATA%\Programs\Python\Python312"
    "%LOCALAPPDATA%\Programs\Python\Python311"
    "%LOCALAPPDATA%\Programs\Python\Python310"
    "C:\Python313"
    "C:\Python312"
    "C:\Python311"
    "C:\Python310"
) do (
    if exist "%%~D\python.exe" (
        set "PYTHON_CMD=%%~D\python.exe"
        goto :python_found
    )
)

:: Final check via PATH (in case PATH was refreshed)
python --version >nul 2>&1
if %errorlevel% equ 0 ( set "PYTHON_CMD=python" & goto :python_found )
py --version >nul 2>&1
if %errorlevel% equ 0 ( set "PYTHON_CMD=py"     & goto :python_found )

echo [ERROR] Python installation failed.
echo Please install Python manually: https://www.python.org/downloads/
echo Make sure to check "Add Python to PATH"!
pause
exit /b 1

:python_found
for /f "tokens=2 delims= " %%v in ('"%PYTHON_CMD%" --version 2^>^&1') do set PY_VER=%%v
echo [OK] Python %PY_VER% found.

:: ── Copy app files ───────────────────────────────────
echo.
echo Installing to: %INSTALL_DIR%
if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%"

copy /y "%SCRIPT_DIR%server.py"         "%INSTALL_DIR%\server.py"         >nul
copy /y "%SCRIPT_DIR%index.html"        "%INSTALL_DIR%\index.html"        >nul
copy /y "%SCRIPT_DIR%requirements.txt"  "%INSTALL_DIR%\requirements.txt"  >nul

:: ── Virtual environment ───────────────────────────────
echo.
echo Creating virtual environment...
"%PYTHON_CMD%" -m venv "%INSTALL_DIR%\venv"

echo Installing packages...
"%INSTALL_DIR%\venv\Scripts\pip" install --upgrade pip -q
"%INSTALL_DIR%\venv\Scripts\pip" install -r "%INSTALL_DIR%\requirements.txt" -q
echo [OK] Packages installed.

:: ── Launcher batch ────────────────────────────────────
set "LAUNCH_BAT=%INSTALL_DIR%\launch.bat"
(
    echo @echo off
    echo cd /d "%INSTALL_DIR%"
    echo start "" "%INSTALL_DIR%\venv\Scripts\python.exe" server.py
    echo timeout /t 2 /nobreak ^>nul
    echo start http://127.0.0.1:8000
) > "%LAUNCH_BAT%"

:: ── Desktop shortcut ─────────────────────────────────
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
echo How to launch: Double-click "Filie" on your Desktop
echo To uninstall:  delete %INSTALL_DIR%
echo.
pause
