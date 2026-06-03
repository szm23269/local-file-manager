@echo off
:: Filie Setup Launcher — elevates to admin then shows the GUI installer
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "Start-Process powershell -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File ""%~dp0Filie-Setup.ps1""' -Verb RunAs"
