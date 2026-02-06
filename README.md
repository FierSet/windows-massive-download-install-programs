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

**CSV Format**
- **Header:** The CSV file must contain: Name,Install,URL,Parameters
- **Name:** Friendly program identifier; used to name the downloaded file (no extension required).
- **Install:** Put `x` (case-insensitive) to mark the program for download/installation.
- **URL:** Direct download URL. Prefer URLs that end with `.exe` or `.msi`. If a URL does not include an extension the script follows redirects to detect the final filename/extension — this can sometimes fail for dynamic download endpoints.
- **Parameters:** Silent install arguments passed to the installer. Do not include surrounding quotes; include only the arguments. Examples: `/S`, `/VERYSILENT /NORESTART`.

**Example CSV**
```csv
Name,Install,URL,Parameters
firefox,x,https://download.mozilla.org/?product=firefox-latest&os=win64&lang=en-US,/S
steam,x,https://steamcdn-a.akamaihd.net/client/installer/SteamSetup.exe,/S /D=C:\Program Files (x86)\Steam
java-jdk,x,https://download.oracle.com/java/25/latest/jdk-25_windows-x64_bin.exe,INSTALLDIR="C:\Program Files\Java\jdk-25" /s /L en
```

**Running the script**
- Run from an elevated PowerShell (Run as Administrator):

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\autoinstall.ps1
```

Or from an elevated prompt after changing to the repo folder:

```powershell
Set-Location -Path "C:\Path\To\windows-massive-download-install-programs"
.\autoinstall.ps1
```

**Logs & Troubleshooting**
- **Log file:** The script writes to [autoinstall.log](autoinstall.log). Check it for download and install entries.
- **Downloads:** If a program failed to download, verify the `URL` in the CSV directly in a browser. If the URL redirects to a CDN or a dynamic endpoint, prefer a direct link ending in `.exe` or `.msi` where possible.
- **Installers & Parameters:** Not all installers support the same silent flags. If an installer returns a non-zero exit code, test the installer manually from a command prompt to see interactive prompts or error messages.
- **Common exit codes:** `0` = success, `3010` = success (reboot required), other codes vary by installer (e.g., `1603` general MSI error, `1602` cancelled).
- **Java JDK notes:** Oracle's GUI installer may not behave well with generic silent flags; consider using an MSI or an OpenJDK/Temurin MSI for unattended installs. If using Oracle's exe, test the `INSTALLDIR` and `/s` flags manually first.
- **Steam notes:** Steam's installer sometimes spawns background services and may return non-standard exit codes; include `/S` and `/D=...` if you need a custom install folder, but verify manually if failures occur.
- **Permissions & AV:** Run as Administrator and temporarily disable antivirus/endpoint protection if downloads or installs are being blocked.

**Tips**
- Ensure the `Install` column uses `x` (lower or upper case) to include entries.
- Keep `Parameters` simple and test each installer manually before adding to the CSV.
- If a program repeatedly fails, try downloading the installer to the `programs/` folder manually, then run the script to perform only the installation step.

If you'd like, I can:
- run the script locally and inspect `autoinstall.log` (you'll need to paste its contents here), or
- help craft correct parameters/URLs for specific programs you want to automate.
