@echo off
title Maqueta Comercial Sedyjo
cd /d "%~dp0"
echo Abriendo la maqueta de Comercial Sedyjo...
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0servidor.ps1" -Pagina "?cliente=1"
pause
