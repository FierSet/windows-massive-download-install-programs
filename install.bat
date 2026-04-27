@echo off

set selflocation=%~dp0

set scriptdir=autoinstall.ps1

powershell -NoProfile -ExecutionPolicy Bypass -File %selflocation%/%scriptdir%

pause