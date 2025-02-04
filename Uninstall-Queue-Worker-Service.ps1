<#
    Copyright (c) 2025 Dávid Lábodi
    Licensed under the MIT License. See LICENSE file in the project root for full license information.
#>

$ErrorActionPreference = "Stop"

# Configuration
$serviceName = "LaravelQueueWorker"
$scriptDir = $PSScriptRoot  # Define $scriptDir as the directory where the script is located
$nssmDir = Join-Path $scriptDir "nssm\nssm-2.24-101-g897c7ad\win64"
$nssmExe = Join-Path $nssmDir "nssm.exe"

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

# If the script reaches this point, it is running as an administrator
Write-Host "Running with administrator privileges." -ForegroundColor Green

# Check if NSSM exists
if (-not (Test-Path $nssmExe)) {
    Write-Host "NSSM executable not found at $nssmExe. Please ensure NSSM is installed." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# Check if service exists
$service = Get-Service $serviceName -ErrorAction SilentlyContinue
if (-not $service) {
    Write-Host "Service $serviceName does not exist." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 0
}

# Stop and remove service
try {
    if ($service.Status -eq "Running") {
        Write-Host "Stopping service $serviceName..." -ForegroundColor Yellow
        Stop-Service $serviceName -Force
        Write-Host "Service stopped." -ForegroundColor Green
    }

    Write-Host "Removing service $serviceName..." -ForegroundColor Yellow
    & $nssmExe remove $serviceName confirm
    Write-Host "Service uninstalled." -ForegroundColor Green
}
catch {
    Write-Host "An error occurred: $_" -ForegroundColor Red
	Write-Host ""
	Write-Host "Ensure the script is running as admin privileges, and the service name is correct!" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# Optional: Cleanup NSSM (comment out if you want to remove)
# Remove-Item $nssmDir -Recurse -Force
# Write-Host "NSSM uninstalled." -ForeGroundColor Green

Read-Host "Press Enter to exit"