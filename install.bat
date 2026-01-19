@echo off

set selflocation=%~dp0

powershell -NoProfile -ExecutionPolicy Bypass -File %selflocation%/autoinstall.ps1

pause