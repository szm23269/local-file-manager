@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion

set "APP_NAME=Filie"
set "INSTALL_DIR=%LOCALAPPDATA%\Filie"

echo.
echo ================================================
echo   Filie インストーラー (Windows)
echo ================================================
echo.

:: ── Python 確認 ──────────────────────────────────────
python --version >nul 2>&1
if %errorlevel% neq 0 (
    py --version >nul 2>&1
    if %errorlevel% neq 0 (
        echo [エラー] Python が見つかりません。
        echo.
        echo https://www.python.org/downloads/ から
        echo Python 3.10 以降をインストールしてください。
        echo.
        echo インストール時に「Add Python to PATH」に
        echo チェックを入れることを忘れずに！
        pause
        exit /b 1
    )
    set PYTHON=py
) else (
    set PYTHON=python
)

for /f "tokens=2" %%v in ('!PYTHON! --version 2^>^&1') do set PY_VER=%%v
echo [OK] Python !PY_VER! が見つかりました

:: ── インストール先作成 ────────────────────────────────
echo.
echo インストール先: %INSTALL_DIR%
if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%"

set "SCRIPT_DIR=%~dp0"
copy /y "%SCRIPT_DIR%server.py"        "%INSTALL_DIR%\server.py"        >nul
copy /y "%SCRIPT_DIR%index.html"       "%INSTALL_DIR%\index.html"       >nul
copy /y "%SCRIPT_DIR%requirements.txt" "%INSTALL_DIR%\requirements.txt" >nul

:: ── 仮想環境 ──────────────────────────────────────────
echo.
echo Python 仮想環境を作成中...
!PYTHON! -m venv "%INSTALL_DIR%\venv"

echo 依存パッケージをインストール中...
"%INSTALL_DIR%\venv\Scripts\pip" install --upgrade pip -q
"%INSTALL_DIR%\venv\Scripts\pip" install -r "%INSTALL_DIR%\requirements.txt" -q
echo [OK] パッケージのインストール完了

:: ── 起動バッチ ────────────────────────────────────────
set "LAUNCH_BAT=%INSTALL_DIR%\launch.bat"
(
echo @echo off
echo cd /d "%%LOCALAPPDATA%%\Filie"
echo start "" "%%LOCALAPPDATA%%\Filie\venv\Scripts\python.exe" server.py
echo timeout /t 2 /nobreak ^>nul
echo start http://127.0.0.1:8000
) > "%LAUNCH_BAT%"

:: ── デスクトップショートカット ─────────────────────────
set "SHORTCUT_PS=%TEMP%\create_shortcut.ps1"
set "DESKTOP_LINK=%USERPROFILE%\Desktop\Filie.lnk"
(
echo $ws = New-Object -ComObject WScript.Shell
echo $s = $ws.CreateShortcut('%DESKTOP_LINK%'^)
echo $s.TargetPath = '%LAUNCH_BAT%'
echo $s.WorkingDirectory = '%INSTALL_DIR%'
echo $s.Description = 'Filie'
echo $s.Save(^)
) > "%SHORTCUT_PS%"
powershell -ExecutionPolicy Bypass -File "%SHORTCUT_PS%" >nul 2>&1
del "%SHORTCUT_PS%" >nul 2>&1

echo.
echo ================================================
echo   インストール完了！
echo ================================================
echo.
echo 起動方法:
echo   1. デスクトップの「Filie」ショートカットをダブルクリック
echo   2. または: %LAUNCH_BAT%
echo.
echo アンインストール: フォルダを削除してください
echo   %INSTALL_DIR%
echo.
pause
