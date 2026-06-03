# Filie Setup — Windows GUI Installer
# Requires: PowerShell 5+ (Windows 10/11 built-in)

param()
$PSScriptRoot2 = Split-Path -Parent $MyInvocation.MyCommand.Path
$INSTALL_DIR   = "$env:LOCALAPPDATA\Filie"
$PYTHON_VER    = "3.12.7"
$PYTHON_URL    = "https://www.python.org/ftp/python/$PYTHON_VER/python-$PYTHON_VER-amd64.exe"

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

# ── Color palette ─────────────────────────────────────
$COL_BG      = [System.Drawing.Color]::FromArgb(14, 17, 23)
$COL_BG2     = [System.Drawing.Color]::FromArgb(22, 27, 39)
$COL_BG3     = [System.Drawing.Color]::FromArgb(30, 37, 53)
$COL_ACCENT  = [System.Drawing.Color]::FromArgb(79, 142, 247)
$COL_GREEN   = [System.Drawing.Color]::FromArgb(62, 207, 142)
$COL_TEXT    = [System.Drawing.Color]::FromArgb(200, 208, 224)
$COL_MUTED   = [System.Drawing.Color]::FromArgb(107, 122, 153)
$COL_WHITE   = [System.Drawing.Color]::White

# ── Form ──────────────────────────────────────────────
$form = New-Object System.Windows.Forms.Form
$form.Text            = "Filie Installer"
$form.ClientSize      = New-Object System.Drawing.Size(480, 420)
$form.StartPosition   = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox     = $false
$form.BackColor       = $COL_BG2

# ── Header ────────────────────────────────────────────
$header = New-Object System.Windows.Forms.Panel
$header.Size      = New-Object System.Drawing.Size(480, 96)
$header.Location  = New-Object System.Drawing.Point(0, 0)
$header.BackColor = $COL_BG
$form.Controls.Add($header)

$lblApp = New-Object System.Windows.Forms.Label
$lblApp.Text      = "Filie"
$lblApp.Font      = New-Object System.Drawing.Font("Segoe UI", 30, [System.Drawing.FontStyle]::Bold)
$lblApp.ForeColor = $COL_ACCENT
$lblApp.AutoSize  = $true
$lblApp.Location  = New-Object System.Drawing.Point(28, 14)
$header.Controls.Add($lblApp)

$lblSub = New-Object System.Windows.Forms.Label
$lblSub.Text      = "Local File Manager  —  Installer"
$lblSub.Font      = New-Object System.Drawing.Font("Segoe UI", 10)
$lblSub.ForeColor = $COL_MUTED
$lblSub.AutoSize  = $true
$lblSub.Location  = New-Object System.Drawing.Point(30, 64)
$header.Controls.Add($lblSub)

# ── Install path ──────────────────────────────────────
$lblPathCaption = New-Object System.Windows.Forms.Label
$lblPathCaption.Text      = "Install location:"
$lblPathCaption.Font      = New-Object System.Drawing.Font("Segoe UI", 9)
$lblPathCaption.ForeColor = $COL_MUTED
$lblPathCaption.AutoSize  = $true
$lblPathCaption.Location  = New-Object System.Drawing.Point(28, 114)
$form.Controls.Add($lblPathCaption)

$lblPath = New-Object System.Windows.Forms.Label
$lblPath.Text      = $INSTALL_DIR
$lblPath.Font      = New-Object System.Drawing.Font("Consolas", 9)
$lblPath.ForeColor = $COL_GREEN
$lblPath.AutoSize  = $true
$lblPath.Location  = New-Object System.Drawing.Point(28, 134)
$form.Controls.Add($lblPath)

# ── Progress bar ──────────────────────────────────────
$progress = New-Object System.Windows.Forms.ProgressBar
$progress.Size     = New-Object System.Drawing.Size(424, 14)
$progress.Location = New-Object System.Drawing.Point(28, 196)
$progress.Minimum  = 0
$progress.Maximum  = 100
$progress.Value    = 0
$progress.Visible  = $false
$form.Controls.Add($progress)

$lblStatus = New-Object System.Windows.Forms.Label
$lblStatus.Text      = ""
$lblStatus.Font      = New-Object System.Drawing.Font("Segoe UI", 9)
$lblStatus.ForeColor = $COL_TEXT
$lblStatus.Size      = New-Object System.Drawing.Size(424, 22)
$lblStatus.Location  = New-Object System.Drawing.Point(28, 216)
$form.Controls.Add($lblStatus)

# ── URL result panel (shown after success) ────────────
$urlPanel = New-Object System.Windows.Forms.Panel
$urlPanel.Size      = New-Object System.Drawing.Size(424, 80)
$urlPanel.Location  = New-Object System.Drawing.Point(28, 265)
$urlPanel.BackColor = $COL_BG3
$urlPanel.Visible   = $false
$form.Controls.Add($urlPanel)

$lblUrlCaption = New-Object System.Windows.Forms.Label
$lblUrlCaption.Text      = "Open in your browser and bookmark:"
$lblUrlCaption.Font      = New-Object System.Drawing.Font("Segoe UI", 9)
$lblUrlCaption.ForeColor = $COL_MUTED
$lblUrlCaption.AutoSize  = $true
$lblUrlCaption.Location  = New-Object System.Drawing.Point(14, 10)
$urlPanel.Controls.Add($lblUrlCaption)

$lblUrl = New-Object System.Windows.Forms.Label
$lblUrl.Text      = "http://filie"
$lblUrl.Font      = New-Object System.Drawing.Font("Consolas", 20, [System.Drawing.FontStyle]::Bold)
$lblUrl.ForeColor = $COL_ACCENT
$lblUrl.AutoSize  = $true
$lblUrl.Location  = New-Object System.Drawing.Point(14, 34)
$urlPanel.Controls.Add($lblUrl)

# ── Buttons ───────────────────────────────────────────
$btnInstall = New-Object System.Windows.Forms.Button
$btnInstall.Text      = "Install"
$btnInstall.Size      = New-Object System.Drawing.Size(130, 44)
$btnInstall.Location  = New-Object System.Drawing.Point(322, 360)
$btnInstall.FlatStyle = "Flat"
$btnInstall.BackColor = $COL_ACCENT
$btnInstall.ForeColor = $COL_WHITE
$btnInstall.Font      = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$btnInstall.FlatAppearance.BorderSize = 0
$btnInstall.Cursor    = [System.Windows.Forms.Cursors]::Hand
$form.Controls.Add($btnInstall)

$btnLaunch = New-Object System.Windows.Forms.Button
$btnLaunch.Text      = "Launch Filie"
$btnLaunch.Size      = New-Object System.Drawing.Size(160, 44)
$btnLaunch.Location  = New-Object System.Drawing.Point(154, 360)
$btnLaunch.FlatStyle = "Flat"
$btnLaunch.BackColor = $COL_GREEN
$btnLaunch.ForeColor = $COL_BG
$btnLaunch.Font      = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$btnLaunch.FlatAppearance.BorderSize = 0
$btnLaunch.Cursor    = [System.Windows.Forms.Cursors]::Hand
$btnLaunch.Visible   = $false
$form.Controls.Add($btnLaunch)

# ── Helpers ───────────────────────────────────────────
function Update-UI {
    param($msg, $pct)
    $lblStatus.Text  = $msg
    if ($pct -ge 0) { $progress.Value = [Math]::Min($pct, 100) }
    $form.Refresh()
    [System.Windows.Forms.Application]::DoEvents()
}

function Find-Python {
    foreach ($cmd in @("python", "py")) {
        try {
            $null = & $cmd --version 2>&1
            if ($LASTEXITCODE -eq 0) { return $cmd }
        } catch {}
    }
    $dirs = @(
        "$env:LOCALAPPDATA\Programs\Python\Python313",
        "$env:LOCALAPPDATA\Programs\Python\Python312",
        "$env:LOCALAPPDATA\Programs\Python\Python311",
        "$env:LOCALAPPDATA\Programs\Python\Python310",
        "C:\Python313","C:\Python312","C:\Python311","C:\Python310"
    )
    foreach ($d in $dirs) {
        if (Test-Path "$d\python.exe") { return "$d\python.exe" }
    }
    return $null
}

# ── Install logic ─────────────────────────────────────
$btnInstall.Add_Click({
    $btnInstall.Enabled  = $false
    $btnInstall.Text     = "Installing..."
    $progress.Visible    = $true

    try {
        # 1. Python
        Update-UI "Checking Python..." 5
        $py = Find-Python

        if (-not $py) {
            Update-UI "Python not found. Trying winget..." 8
            try {
                $null = winget install -e --id Python.Python.3.12 --silent `
                    --accept-package-agreements --accept-source-agreements 2>&1
            } catch {}
            $py = Find-Python
        }

        if (-not $py) {
            Update-UI "Downloading Python $PYTHON_VER..." 8
            $progress.Style = [System.Windows.Forms.ProgressBarStyle]::Marquee
            Invoke-WebRequest -Uri $PYTHON_URL -OutFile "$env:TEMP\py_setup.exe" -UseBasicParsing
            $progress.Style = [System.Windows.Forms.ProgressBarStyle]::Continuous
            Update-UI "Running Python installer..." 18
            $proc = Start-Process -Wait -PassThru "$env:TEMP\py_setup.exe" `
                -ArgumentList "/quiet InstallAllUsers=0 PrependPath=1 /norestart"
            Remove-Item "$env:TEMP\py_setup.exe" -ErrorAction SilentlyContinue
            $py = Find-Python
        }

        if (-not $py) { throw "Python installation failed. Please install from https://www.python.org/downloads/" }
        Update-UI "Python ready." 28

        # 2. Copy files
        Update-UI "Copying app files..." 35
        New-Item -ItemType Directory -Force -Path $INSTALL_DIR | Out-Null
        @("server.py","index.html","requirements.txt") | ForEach-Object {
            $src = Join-Path $PSScriptRoot2 $_
            if (-not (Test-Path $src)) { throw "File not found: $_. Re-download the installer." }
            Copy-Item $src "$INSTALL_DIR\" -Force
        }

        # 3. Virtual env
        Update-UI "Creating virtual environment..." 48
        & $py -m venv "$INSTALL_DIR\venv" 2>$null
        if (-not (Test-Path "$INSTALL_DIR\venv\Scripts\pip.exe")) {
            throw "Virtual environment creation failed."
        }

        # 4. Packages
        Update-UI "Installing packages (may take a minute)..." 62
        & "$INSTALL_DIR\venv\Scripts\pip" install --upgrade pip -q 2>$null
        & "$INSTALL_DIR\venv\Scripts\pip" install -r "$INSTALL_DIR\requirements.txt" -q 2>$null

        # 5. Launcher
        Update-UI "Creating launcher..." 78
        $launcher = "$INSTALL_DIR\launch.bat"
        [System.IO.File]::WriteAllText($launcher,
            "@echo off`r`ncd /d `"$INSTALL_DIR`"`r`n" +
            "start `"`" `"$INSTALL_DIR\venv\Scripts\python.exe`" server.py`r`n" +
            "timeout /t 2 /nobreak >nul`r`nstart http://filie`r`n",
            [System.Text.Encoding]::ASCII)

        $ws = New-Object -ComObject WScript.Shell
        $sc = $ws.CreateShortcut("$env:USERPROFILE\Desktop\Filie.lnk")
        $sc.TargetPath       = $launcher
        $sc.WorkingDirectory = $INSTALL_DIR
        $sc.Description      = "Filie"
        $sc.Save()

        # 6. URL setup
        Update-UI "Configuring http://filie..." 88
        $hostsPath = "$env:WINDIR\System32\drivers\etc\hosts"
        $hostsText = [System.IO.File]::ReadAllText($hostsPath)
        if ($hostsText -notmatch "filie") {
            [System.IO.File]::AppendAllText($hostsPath, "`r`n127.0.0.1    filie`r`n")
        }
        $null = netsh interface portproxy add v4tov4 `
            listenaddress=127.0.0.1 listenport=80 `
            connectaddress=127.0.0.1 connectport=8000 2>&1
        $null = ipconfig /flushdns 2>&1

        # Done!
        Update-UI "Installation complete!" 100
        $progress.Visible    = $false
        $urlPanel.Visible    = $true
        $btnLaunch.Visible   = $true
        $btnInstall.Visible  = $false

    } catch {
        $progress.Visible   = $false
        $btnInstall.Enabled = $true
        $btnInstall.Text    = "Retry"
        [System.Windows.Forms.MessageBox]::Show(
            $_.Exception.Message, "Installation Error",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error)
    }
})

$btnLaunch.Add_Click({
    Start-Process "$INSTALL_DIR\launch.bat"
    $form.Close()
})

[void]$form.ShowDialog()
