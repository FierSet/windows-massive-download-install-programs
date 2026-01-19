$selfPath = Split-Path -Parent $PSCommandPath

$programsPath = "$selfPath\programs"

$log = "$selfPath\autoinstall.log" #log file path


function LogMessage([string]$message, [string]$level = "INFO"){  # INFO, WARNING, ERROR
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$level] $message"
    
    # Write to console
    #Write-Host $logEntry
    
    # Write to log file
    Add-Content -Path $log -Value $logEntry
}

if(!(Test-Path -Path $log)){ #check if log file exists
    New-Item -ItemType File -Path $log | Out-Null #create log file
    LogMessage "Log file created at $log"
}

if (!(Test-Path -Path $programsPath)) { #check if programs directory exists
    New-Item -ItemType Directory -Path $programsPath | Out-Null #create programs directory
    LogMessage "Created programs directory at $programsPath"
}


$downloadsPath = @{ #program name and download url
    "java-jdk" = "https://download.oracle.com/java/25/latest/jdk-25_windows-x64_bin.exe"
    "firefox" = "https://download.mozilla.org/?product=firefox-latest&os=win64&lang=en-US"
    "steam" = "https://steamcdn-a.akamaihd.net/client/installer/SteamSetup.exe"
    "winrar" = "https://www.rarlab.com/rar/winrar-x64-602.exe"
    "visualstudiocode" = "https://update.code.visualstudio.com/latest/win32-x64-user/stable"
    "Rainmeter" = "https://github.com/rainmeter/rainmeter/releases/download/v4.5.23.3836/Rainmeter-4.5.23.exe"
    "git" = "https://github.com/git-for-windows/git/releases/download/v2.52.0.windows.1/Git-2.52.0-64-bit.exe"
    "brave" = "https://laptop-updates.brave.com/latest/win64"
    "discord" = "https://discord.com/api/download?platform=win"
    "dotnet" = "https://builds.dotnet.microsoft.com/dotnet/Sdk/10.0.102/dotnet-sdk-10.0.102-win-x64.exe"
}

$ARGUMENTS = @{ #silent install arguments
    "firefox.exe" = "/S"
    "steam.exe" = "/S"
    "brave.exe" = "/silent /install"
    "winrar.exe" = "/S"
    "visualstudiocode.exe" = "/VERYSILENT /NORESTART /MERGETASKS=`"!runcode`""
    "Rainmeter.exe" = "/S"
    "git.exe" = "/VERYSILENT /NORESTART /NOCANCEL /SP /CLOSEAPPLICATIONS /RESTARTAPPLICATIONS /COMPONENTS=`"icons,ext\reg\shellhere,assoc,assoc_sh`""
    "discord.exe" = "/S"
    "dotnet.exe" = "/install /quiet /norestart"
    "java-jdk.exe" = "/s INSTALLDIR=C:\Progra~1\Java\jdk"
}

function downloadprogram($name, $url){

    Write-Output "Downloading: $name from $url"

    try
    {
        $dowunload = Invoke-WebRequest -Uri $url -UseBasicParsing #download file

        if($dowunload.StatusCode -eq 200)
        {
            $urlFinal = $dowunload.BaseResponse.ResponseUri.AbsoluteUri #get final url after redirections

            $extension = [System.IO.Path]::GetExtension($urlFinal).Replace("&response-content-type=application%2Foctet-stream", "") #get extension from final url
            $finalPath = "$programsPath\$name$extension" #set final path with extension
            $responseStream = $dowunload.RawContentStream #get response stream

            $fileStream = [System.IO.File]::Open($finalPath, [System.IO.FileMode]::Create, [System.IO.FileAccess]::Write) #create file stream
            $responseStream.CopyTo($fileStream) #copy response stream to file stream

            Write-Host "Downloading: $name$extension Success." -ForegroundColor Green
            LogMessage "Downloaded: $name$extension from $urlFinal"
        }else{
            Write-Host "Downloading: $name Fatal Error: no downloaded." -ForegroundColor Red
            LogMessage "Failed to download: $name from $url. Status Code: $($dowunload.StatusCode)" "ERROR"
        }
    }
    catch{
        Write-Host "Downloading: $name Fatal Error: no downloaded: $($_.Exception.Message)" -ForegroundColor Red
        LogMessage "Failed to download: $name from $url. Error: $($_.Exception.Message)" "ERROR"
    }
    finally { $fileStream.Close(); $responseStream.Close()<#  #close streams  #>} 

}

function install_program ($program, $name){

    if($name -match '.msi'){
        $job = Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$program`" /qn /norestart" -PassThru -Verb RunAs #-Wait
    }
    elseif($ARGUMENTS.ContainsKey($name)){
        $job = Start-Process -FilePath $program -ArgumentList $ARGUMENTS[$name] -PassThru -Verb RunAs #-Wait
    }
    else{
        $job = Start-Process -FilePath $program -PassThru -Verb RunAs #-Wait
    }

    $job.WaitForExit()

    if($job.ExitCode -eq 0){
        Write-Host "Installing: $name Success." -ForegroundColor Green
        LogMessage "Installed: $name successfully."
    }elseif($job.ExitCode -eq 3010){
        Write-Host "Installing: $name Success, Reboot Required." -ForegroundColor Blue
        LogMessage "Installed: $name successfully. Reboot Required." "WARNING"
    }else{
        Write-Host "Installing: $name Fatal Error: no installed." -ForegroundColor Red
        LogMessage "Failed to install: $name" "ERROR"
    }

    
}

LogMessage "Starting download process____________________________________"
## Downloading Section

Write-Output "Downloading programs."
Write-Output "`n"#"Script location: $selfPath"

$current_file_nom = 0

$nomfiles = $downloadsPath.Count

foreach ($key in $downloadsPath.Keys) { #loop through hashtable keys


    $percentComplete = ($current_file_nom / $nomfiles) * 100

    Write-Progress -Activity "Processing..." -Status "$percentComplete% Complete" -PercentComplete $percentComplete

    downloadprogram $key $downloadsPath[$key]

    $current_file_nom++

}

## Installation Section

LogMessage "Starting installation process____________________________________"

Write-Output "Installing programs."
Write-Output "`n"#"Script location: $selfPath"

$current_file_nom = 0

$nomfiles = (Get-ChildItem -Path ($programsPath) -File).Count

Get-ChildItem -Path ($programsPath) | ForEach-Object {
    
    Write-Output "Installing: $($_.Name)."

    $percentComplete = ($current_file_nom / $nomfiles) * 100

    Write-Progress -Activity "Processing..." -Status "$percentComplete% Complete" -PercentComplete $percentComplete

    install_program $_.FullName $_.Name

    $current_file_nom++
}

Write-Output "Process completed."