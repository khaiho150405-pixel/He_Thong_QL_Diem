@echo off
chcp 65001 >nul
title Tat nhan dang
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\recognition\pilot\down.ps1"
echo.
pause
