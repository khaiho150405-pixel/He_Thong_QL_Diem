@echo off
chcp 65001 >nul
title Bat nhan dang (dien thoai USB)
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\recognition\pilot\up.ps1" -Usb
echo.
pause
