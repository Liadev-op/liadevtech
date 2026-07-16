@echo off
rem Lanzador de Liadev Tech - ejecuta el script compilado con doble clic.
rem El propio script pide elevacion (UAC) si hace falta.
cd /d "%~dp0"
if not exist "liadevtech.ps1" (
    echo No se encontro liadevtech.ps1. Compilalo primero con: powershell -ExecutionPolicy Bypass -File Compile.ps1
    pause
    exit /b 1
)
powershell -ExecutionPolicy Bypass -NoProfile -File "liadevtech.ps1"
