<#
    Copyright (c) 2025 Dávid Lábodi
    Licensed under the MIT License. See LICENSE file in the project root for full license information.
#>

$ErrorActionPreference = "Stop"

# Configuration
$serviceName = "LaravelQueueWorker"
$workerScriptName = "queue-worker.ps1"
$serviceDisplayName = "Laravel Queue Worker"
$serviceDescription = "Runs Laravel queue worker process"

$scriptDir = $PSScriptRoot # Need to place this script too in the laravel project root directory!
$logDir = Join-Path $scriptDir -ChildPath "storage\logs"
$nssmDir = Join-Path $scriptDir "nssm\nssm-2.24-101-g897c7ad\win64"
$nssmExe = Join-Path $nssmDir "nssm.exe"
$workerScriptPath = Join-Path $scriptDir $workerScriptName

if (-not (Test-Path $LogDir)) {
    Write-Host "Laravel log directory not found, ensure the script is in the laravel root directory." -ForegroundColor Red
	Read-Host
    exit 1
}

# Check if the script is running as an administrator
function Test-Admin {
    $currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Restart the script as an administrator if not already running as one
if (-not (Test-Admin)) {
    Write-Host "This script requires administrator privileges." -ForegroundColor Yellow
    Write-Host "Restarting script with elevated permissions..." -ForegroundColor Yellow

    # Start a new PowerShell process with elevated privileges
    $newProcess = Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs -PassThru

    # Wait for the new process to exit
    $newProcess.WaitForExit()

    # Exit the current script
    exit
}

# Download and extract NSSM if missing
if (-not (Test-Path $nssmExe)) {
    Write-Host "Downloading NSSM..."
    $nssmZipUrl = "https://nssm.cc/ci/nssm-2.24-101-g897c7ad.zip"
    $zipPath = Join-Path $env:TEMP "nssm.zip"
    
    try {
        Invoke-WebRequest -Uri $nssmZipUrl -OutFile $zipPath
        Expand-Archive -Path $zipPath -DestinationPath $nssmDir
    }
    finally {
        if (Test-Path $zipPath) { Remove-Item $zipPath }
    }
}

# Verify worker script exists
if (-not (Test-Path $workerScriptPath)) {
    throw "Worker script ($workerScriptName) not found in script directory!"
}

# Check existing service
if (Get-Service $serviceName -ErrorAction SilentlyContinue) {
    throw "Service $serviceName already exists! Uninstall it first."
}

# Get PowerShell path
$powerShellPath = (Get-Command "powershell.exe").Path

# Install service
& $nssmExe install $serviceName $powerShellPath "-ExecutionPolicy Bypass -File `"$workerScriptPath`""
& $nssmExe set $serviceName DisplayName $serviceDisplayName
& $nssmExe set $serviceName Description $serviceDescription
& $nssmExe set $serviceName AppDirectory $scriptDir
& $nssmExe set $serviceName Start SERVICE_AUTO_START
& $nssmExe set $serviceName AppStdout (Join-Path $logDir "queue-service.log")
& $nssmExe set $serviceName AppStderr (Join-Path $logDir "queue-service-error.log")
Write-Host ""
Write-Host "==========================================="
Start-Service $serviceName
Write-Host "Service installed and started successfully!" -ForeGroundColor Green
Write-Host "Service Name: $serviceName" -ForeGroundColor Green
Write-Host "Worker Script: $workerScriptPath" -ForeGroundColor Green
Write-Host "==========================================="
Write-Host "Don't forget to add NSSM directory ($($nssmDir)) to .gitignore if this is a development instance!"
Read-Host