# Windows Massive Download & Install Programs

Small repo with scripts to download and install multiple Windows programs.

Contents
- `autoinstall.ps1` — PowerShell automation script to download and install packages.
- `install.bat` — Batch helper to run installers (Windows).
- `programs/` — Directory containing program installers or helper manifests.

## Architecture

![Diagram](https://raw.githubusercontent.com/FierSet/windows-massive-download-install-programs/refs/heads/main/diagram.png)

Prerequisites
- Windows 10/11 (or later)
- Administrative privileges
- PowerShell (built-in)
- Set execution policy or use the bypass flag when running the script

Usage

Open an elevated PowerShell (Run as Administrator), change to this repository folder, then run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\\autoinstall.ps1
```

Or from an elevated PowerShell prompt:

```powershell
Set-Location -Path "C:\\Path\\To\\windows-massive-download&install-programs"
.\\autoinstall.ps1
```

To use the batch helper, run `install.bat` as administrator:

```bat
install.bat
```

Safety & Notes
- Review `autoinstall.ps1`, `install.bat`, and any files in `programs/` before running.
- The scripts may download installers from the internet; ensure you trust the sources.
- Run only on systems you control and where you have appropriate backups.

Want changes?
- If you want more detailed per-program instructions, logging, or a dry-run mode, open an issue or request edits.

"Use at your own risk" — these scripts are provided as-is; test in a VM first.
