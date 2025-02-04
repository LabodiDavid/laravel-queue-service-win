<#
    Copyright (c) 2025 Dávid Lábodi
    Licensed under the MIT License. See LICENSE file in the project root for full license information.
#>

$startingHourMinute = Get-Date -Format "HHmm" # Script start hour and minute for include in the log file name

# Configuration
$LaravelPath = $PSScriptRoot             # Path to your Laravel project
$PhpPath = (Get-Command php.exe).Source        # Path to your PHP executable
$LogDir = "$LaravelPath\storage\logs"    # Path to the log dir
$LogPath = "$($LogDir)\queue-worker.txt" # Path to the default log file
$CommandArgs = "artisan queue:work --tries=3" # Artisan command arguments
$RestartDelay = 5                        # Delay in seconds before restarting


if (-not (Test-Path $LogDir)) {
    Write-Host "Laravel log directory not found, ensure the script is in the laravel root directory." -ForegroundColor Red
    exit 1
}

function Log {
    param (
        [string]$Message
    )
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $FinalText = "[$($Timestamp)] $($Message)"
    
    # Write to the log file
    $FinalText | Out-File -FilePath $LogPath -Append -Encoding utf8

    # Optionally, display in the console
    Write-Host $FinalText
}

Log -Message "Starting, monitoring Laravel Queue Worker..."
Write-Host "Log directory: $LogDir"
Write-Host ""

# Variable to store the current worker process
$WorkerProcess = $null
# Cleanup function to terminate the worker process
function Cleanup-Worker {
    if ($WorkerProcess -and !$WorkerProcess.HasExited) {
        Log -Message "Stopping artisan queue worker..."
        $WorkerProcess.Kill()
    }
}

# Register cleanup on PowerShell session exit
Register-EngineEvent -SourceIdentifier PowerShell.Exiting -Action { Cleanup-Worker } | Out-Null

$StartInfo = New-Object System.Diagnostics.ProcessStartInfo -Property @{
    FileName = $PhpPath
    Arguments = $CommandArgs
    UseShellExecute = $false
    RedirectStandardOutput = $true
    RedirectStandardError = $true
}

# Function to read and log process output
function Read-ProcessOutput {
    param (
        [System.Diagnostics.Process]$Process
    )

    while (!$Process.HasExited) {
        while (!$Process.StandardOutput.EndOfStream) {
            $Output = $Process.StandardOutput.ReadLine()
            Log $Output
        }
        
        while (!$Process.StandardError.EndOfStream) {
            $Err = $Process.StandardError.ReadLine()
            Log "ERROR: $Err"
        }
        
        Start-Sleep -Milliseconds 100
    }

    # Read remaining output after the process exits
    while (!$Process.StandardOutput.EndOfStream) {
        $Output = $Process.StandardOutput.ReadLine()
        Log $Output
    }
    while (!$Process.StandardError.EndOfStream) {
        $Err = $Process.StandardError.ReadLine()
        Log "ERROR: $Err"
    }
}

# Monitor loop
while ($true) {
    # Create new process
    $WorkerProcess = New-Object System.Diagnostics.Process
    # Assign previously created StartInfo properties
    $WorkerProcess.StartInfo = $StartInfo

    try {
        # Start process
        [void]$WorkerProcess.Start()
        Write-Host "Process started."

        # Read and log process output
        Read-ProcessOutput -Process $WorkerProcess

    } catch {
        Write-Host "Error: $_"
    }

    # Log the restart event
    Log "Artisan queue worker stopped. Restarting in $RestartDelay seconds..."
    # Delay before restarting
    Start-Sleep -Seconds $RestartDelay
}
