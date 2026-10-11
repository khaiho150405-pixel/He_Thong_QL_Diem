@echo off
chcp 65001 >nul
title Noi lai dien thoai (USB)
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\recognition\pilot\usb-reconnect.ps1"
echo.
pause
