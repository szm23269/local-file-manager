@echo off
setlocal

:: ── Admin elevation ──────────────────────────────────
net session >nul 2>&1
if %errorlevel% neq 0 (
    powershell -Command "Start-Process '%~f0' -Verb RunAs -Wait"
    exit /b
)

set "INSTALL_DIR=%LOCALAPPDATA%\Filie"
set "DESKTOP_LINK=%USERPROFILE%\Desktop\Filie.lnk"
set "HOSTS_FILE=%WINDIR%\System32\drivers\etc\hosts"

echo.
echo ================================================
echo   Filie Uninstaller for Windows
echo ================================================
echo.
echo The following will be removed:
echo   - %INSTALL_DIR%
echo   - Desktop shortcut
echo   - Port redirect (netsh portproxy)
echo   - hosts file entry
echo.
set /p confirm="Continue? [y/N]: "
if /i not "%confirm%"=="y" (
    echo Cancelled.
    pause & exit /b 0
)
echo.

:: ── App folder ───────────────────────────────────────
if exist "%INSTALL_DIR%" (
    rmdir /s /q "%INSTALL_DIR%"
    echo [OK] Removed: %INSTALL_DIR%
) else (
    echo [--] Not found: %INSTALL_DIR%
)

:: ── Desktop shortcut ─────────────────────────────────
if exist "%DESKTOP_LINK%" (
    del /f /q "%DESKTOP_LINK%"
    echo [OK] Removed: Desktop shortcut
) else (
    echo [--] Not found: Desktop shortcut
)

:: ── Port proxy 80 -> 8000 ────────────────────────────
netsh interface portproxy delete v4tov4 ^
    listenaddress=127.0.0.1 listenport=80 >nul 2>&1
echo [OK] Removed port redirect (80 -^> 8000)

:: ── hosts file entry ─────────────────────────────────
findstr /v /c:"filie" "%HOSTS_FILE%" > "%TEMP%\hosts_new.txt" 2>nul
if %errorlevel% equ 0 (
    copy /y "%TEMP%\hosts_new.txt" "%HOSTS_FILE%" >nul
    del "%TEMP%\hosts_new.txt" >nul 2>&1
    echo [OK] Removed "filie" from hosts file
)

:: Flush DNS
ipconfig /flushdns >nul 2>&1

echo.
echo ================================================
echo   Uninstall complete!
echo ================================================
echo.
echo Python itself is NOT removed.
echo To remove Python, use "Apps and features" in Settings.
echo.
pause
