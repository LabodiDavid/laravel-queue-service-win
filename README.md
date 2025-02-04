# Laravel Queue Worker Windows Service

**PowerShell scripts** to install/uninstall a **Laravel Queue Worker Wrapper Script as a Windows service** using [NSSM (Non-Sucking Service Manager)](https://nssm.cc).

## Features

- 🛠️ Automated easy service installation/uninstallation
- 🔄 **Auto-restarting worker** with configurable delay
- 📅 **Time-stamped logging** integrated with Laravel's log system
- 📊 **Dual logging** (file + console if wrapper run directly) with ERROR tagging
- 🚦 **Process monitoring** with output/error stream handling
- 📁 Automated NSSM setup (downloaded on first run)
- 📝 Integrated logging for service operations (NSSM)
- 🔄 **Automatic service restart** on failure (NSSM)
- 🛠️ **Self-contained configuration** with automatic path detection

## File Structure
```
{LARAVEL_ROOT}/
	├── Install-Queue-Worker-Service.ps1       # Service installation script
	├── Uninstall-Queue-Worker-Service.ps1     # Service removal script
	├── queue-worker.ps1          # Worker process wrapper, this is what the service run
	└── /storage/logs/             # Laravel logs (auto-used)
		├── queue-worker.txt      # Real-time logging by worker wrapper
		├── queue-service.log # Service output logs (auto-created, handled by NSSM)  
		└── queue-service-error.log # Service error logs (auto-created, handled by NSSM)
```

## Installation
1. **Clone repository:**
````powershell
git clone https://github.com/labodidavid/laravel-queue-service-win.git
````
2. **Place scripts** in your Laravel root directory
3. **Run as Administrator**:
```powershell
.\Install-Queue-Worker-Service.ps1
```
4. **In development environments:** Add `/nssm` directory and the scripts to `.gitignore` 

**Uninstall** when needed:
```powershell
.\Uninstall-Service.ps1
```
Alternatively you can run the worker wrapper without the service install:
```powershell
# Run worker directly (no service)
.\queue-worker.ps1
```

## Customization

Edit these in `queue-worker.ps1`:
```powershell
# Worker arguments (add --queue, --sleep, etc.)
$CommandArgs = "artisan queue:work --tries=3 --timeout=900"

# Restart delay (seconds)
$RestartDelay = 10 

# Log location (default: storage/logs/queue-worker.txt)
$LogPath = "C:\custom\logs\worker.log"
```


## Troubleshooting
- *Permission errors*: Ensure write access to `storage/logs`
- *Missing PHP*: Verify PHP is in system PATH
- *Service not starting*: Check `Event Viewer → Windows Logs → Application or ` or `queue-service.log`

## Requirements
- Windows Server 2012+ / Windows 10+
- PowerShell 5.1+
- An initialized Laravel project
- NSSM (auto-downloaded by install script)
## Contributing

1.  Fork the repository
    
2.  Create a feature branch (`git checkout -b feature/improvement`)
    
3.  Commit changes (`git commit -am 'Add some feature'`)
    
4.  Push to branch (`git push origin feature/improvement`)
    
5.  Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)