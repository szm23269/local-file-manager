@echo off
setlocal

:: ── Admin elevation ──────────────────────────────────
net session >nul 2>&1
if %errorlevel% neq 0 (
    powershell -Command "Start-Process '%~f0' -Verb RunAs -Wait"
    exit /b
)

set "INSTALL_DIR=%LOCALAPPDATA%\Filie"
set "SCRIPT_DIR=%~dp0"
set "PYTHON_VER=3.12.7"
set "PYTHON_URL=https://www.python.org/ftp/python/%PYTHON_VER%/python-%PYTHON_VER%-amd64.exe"
set "HOSTS_FILE=%WINDIR%\System32\drivers\etc\hosts"

echo.
echo ================================================
echo   Filie Installer for Windows
echo ================================================
echo.

:: ── Check / auto-install Python ───────────────────────
python --version >nul 2>&1
if %errorlevel% equ 0 ( set "PYTHON_CMD=python" & goto :python_found )
py --version >nul 2>&1
if %errorlevel% equ 0 ( set "PYTHON_CMD=py"     & goto :python_found )

echo [INFO] Python not found. Installing automatically...
echo.

winget --version >nul 2>&1
if %errorlevel% equ 0 (
    echo [INFO] Installing Python via Windows Package Manager...
    winget install -e --id Python.Python.3.12 --silent ^
        --accept-package-agreements --accept-source-agreements
    goto :find_python
)

echo [INFO] Downloading Python %PYTHON_VER%... (may take a few minutes)
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "Invoke-WebRequest -Uri '%PYTHON_URL%' -OutFile '%TEMP%\python_setup.exe' -UseBasicParsing"
echo [INFO] Running Python installer silently...
"%TEMP%\python_setup.exe" /quiet InstallAllUsers=0 PrependPath=1 /norestart
del "%TEMP%\python_setup.exe" >nul 2>&1

:find_python
for %%D in (
    "%LOCALAPPDATA%\Programs\Python\Python313"
    "%LOCALAPPDATA%\Programs\Python\Python312"
    "%LOCALAPPDATA%\Programs\Python\Python311"
    "%LOCALAPPDATA%\Programs\Python\Python310"
    "C:\Python313" "C:\Python312" "C:\Python311" "C:\Python310"
) do (
    if exist "%%~D\python.exe" ( set "PYTHON_CMD=%%~D\python.exe" & goto :python_found )
)
python --version >nul 2>&1
if %errorlevel% equ 0 ( set "PYTHON_CMD=python" & goto :python_found )
echo [ERROR] Python installation failed.
echo Please install manually: https://www.python.org/downloads/
pause & exit /b 1

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
    echo start http://filie
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

:: ── URL setup: http://filie ──────────────────────────
echo.
echo Setting up http://filie address...

:: Add to hosts file (check for duplicate)
findstr /c:"127.0.0.1 filie" "%HOSTS_FILE%" >nul 2>&1
if %errorlevel% neq 0 (
    echo 127.0.0.1    filie >> "%HOSTS_FILE%"
    echo [OK] Added "filie" to hosts file.
) else (
    echo [OK] "filie" already in hosts file.
)

:: Port proxy 80 -> 8000 (persists across reboots via IP Helper service)
netsh interface portproxy add v4tov4 ^
    listenaddress=127.0.0.1 listenport=80 ^
    connectaddress=127.0.0.1 connectport=8000 >nul 2>&1
echo [OK] Port redirect 80 -^> 8000 configured.

:: Flush DNS cache so hosts file is picked up immediately
ipconfig /flushdns >nul 2>&1

echo.
echo ================================================
echo   Installation complete!
echo ================================================
echo.
echo How to launch: Double-click "Filie" on your Desktop
echo.
echo Open in browser (bookmark this URL):
echo   --^> http://filie
echo.
echo Fallback URL if the above does not open:
echo   --^> http://127.0.0.1:8000
echo.
echo To uninstall: delete %INSTALL_DIR%
echo.
pause
