@echo off
title Maqueta Comercial Sedyjo (con panel de vistas)
cd /d "%~dp0"
echo Abriendo la maqueta con el panel para saltar entre pantallas...
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0servidor.ps1" -Pagina "?panel=1"
pause
