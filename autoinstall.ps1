$selfPath = Split-Path -Parent $PSCommandPath #get script directory path

$programsPath = "$selfPath\programs" #programs directory path

$log = "$selfPath\autoinstall.log" #log file path

$csvPath = "$selfPath\programlist.csv" #csv file path

$ARGUMENTS = @{} #silent install arguments only exe files, the exe only use arguments if exists in this hashtable

if(-not (Test-Path $csvPath)) #check if csv file exists
{
    Write-Host "Failed to read CSV file at $csvPath or is empty. A csv file was created on $selfPath. please edit it with your programs list." -ForegroundColor Red
    "Name,Install,URL,Parameters" | Out-File -FilePath $csvPath -Encoding UTF8
    exit 1
}

$programsData = Import-Csv -Path $csvPath #import csv data

if($programsData.Count -eq 0) #check if csv file is empty
{
    Write-Host "CSV file at $csvPath is empty. Please edit it with your programs list." -ForegroundColor Red
    exit 1
}

function LogMessage([string]$message, [string]$level = "INFO"){  # INFO, WARNING, ERROR
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss" #get current timestamp
    $logEntry = "[$timestamp] [$level] $message" #format log entry
    
    Add-Content -Path $log -Value $logEntry #append log entry to log file
}

if(!(Test-Path -Path $log)){ #check if log file exists
    New-Item -ItemType File -Path $log | Out-Null #create log file
    LogMessage "Log file created at $log" #log file creation message
}

if (!(Test-Path -Path $programsPath)) { #check if programs directory exists
    New-Item -ItemType Directory -Path $programsPath | Out-Null #create programs directory
    LogMessage "Created programs directory at $programsPath" #
}

function downloadprogram($name, $url){

    Write-Output "Downloading: $name from $url"

    try
    {
        $dowunload = Invoke-WebRequest -Uri $url -UseBasicParsing #download file

        if($dowunload.StatusCode -eq 200) #check if download was successful
        {
            $urlFinal = $dowunload.BaseResponse.ResponseUri.AbsoluteUri #get final url after redirections

            $extension = [System.IO.Path]::GetExtension($urlFinal).Replace("&response-content-type=application%2Foctet-stream", "") #get extension from final url
            $finalPath = "$programsPath\$name$extension" #set final path with extension
            $responseStream = $dowunload.RawContentStream #get response stream

            $fileStream = [System.IO.File]::Open($finalPath, [System.IO.FileMode]::Create, [System.IO.FileAccess]::Write) #create file stream
            $responseStream.CopyTo($fileStream) #copy response stream to file stream

            Write-Host "Downloading: $name$extension Success." -ForegroundColor Green
            LogMessage "Downloaded: $name$extension from $urlFinal"
            $fileStream.Close(); $responseStream.Close()
            return "$name$extension" #return extension
        }else{
            Write-Host "Downloading: $name Fatal Error: no downloaded." -ForegroundColor Red
            LogMessage "Failed to download: $name from $url. Status Code: $($dowunload.StatusCode)" "ERROR"
        }
    }
    catch{
        Write-Host "Downloading: $name Fatal Error: no downloaded: $($_.Exception.Message)" -ForegroundColor Red
        LogMessage "Failed to download: $name from $url. Error: $($_.Exception.Message)" "ERROR"
    }

}

function install_program ($program, $name){

    if($name -match '.msi'){ #msi installation
        $job = Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$program`" /qn /norestart" -PassThru -Verb RunAs #-Wait
    }
    elseif($ARGUMENTS.ContainsKey($name)){ #exe installation with arguments
        $job = Start-Process -FilePath $program -ArgumentList $ARGUMENTS[$name] -PassThru -Verb RunAs #-Wait
    }
    else{ #exe installation without arguments
        $job = Start-Process -FilePath $program -PassThru -Verb RunAs #-Wait
    }

    $job.WaitForExit() #wait for installation to finish

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

function stardownloadfromcsv {

    $current_file_nom = 0
    $nomfiles = $programsData.Count
    $namewithextension = ".exe"

    # Build hashtables from CSV data
    foreach ($program in $programsData) 
    {   
        if($program.Install -ne "")
        {
            $programName = $program.Name
            $url = $program.URL
            $paragmeters = $program.Parameters

            $percentComplete = ($current_file_nom / $nomfiles) * 100

            Write-Progress -Activity "Processing..." -Status "$percentComplete% Complete" -PercentComplete $percentComplete

            #check if file already exists
            if(Test-Path "$programsPath\$programName.exe"){$namewithextension = ".exe"} 
            elseif (Test-Path "$programsPath\$programName.msi") {$namewithextension = ".msi"}
            else {$namewithextension = downloadprogram $programName $url}
            
            if($namewithextension -match '.exe' -and $program.Parameters -ne ""){ $ARGUMENTS["$programName.exe"] = $paragmeters }

            $current_file_nom++
        }
    }
}

function startinstallfromcsv 
{
    $current_file_nom = 0

    $nomfiles = (Get-ChildItem -Path ($programsPath) -File).Count

    Get-ChildItem -Path ($programsPath) | ForEach-Object {
        
        Write-Output "Installing: $($_.Name)."

        $percentComplete = ($current_file_nom / $nomfiles) * 100

        Write-Progress -Activity "Processing..." -Status "$percentComplete% Complete" -PercentComplete $percentComplete

        install_program $_.FullName $_.Name

        $current_file_nom++
    }

    if($nomfiles -eq 0)
    {
        Write-Host "No programs to install. Please check the programs directory at $programsPath or the CSV file at $csvPath." -ForegroundColor Yellow
        LogMessage "No programs to install. Programs directory is empty." "WARNING"
    }
}

LogMessage "Starting download process____________________________________"

## Downloading Section
Write-Output "Downloading programs."
Write-Output "`n"
Write-Output "`n"
Write-Output "`n"
Write-Output "`n"
Write-Output "================================================================"
Write-Output "`n"
Write-Output "`n"
Write-Output "`n"
Write-Output "`n"

stardownloadfromcsv

## Installation Section
LogMessage "Starting installation process____________________________________"

Write-Output "Installing programs."
Write-Output "`n"#"Script location: $selfPath"

startinstallfromcsv


Write-Output "Process completed. you can check the log file at $log for more details."