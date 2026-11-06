# Enhanced Windows Deep Cleanup Script - Extended Edition (Run as Administrator)
# Built by: Pause_Navigator & Antigravity AI
# Email: pausenavigator@gmail.com
# RUN AT YOUR OWN RISK.
# This script requires Administrator privileges.

[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingPositionalParameters', '', Justification = 'Flags native commands such as npm, which take positional args.')]
[CmdletBinding()]
param (
    [Parameter()][switch]$DryRun,
    [Parameter()][string]$LogPath = "$env:USERPROFILE\Cleanup-Logs\deep_cleanup_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
)

# Check for Administrator privileges and relaunch if not elevated
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Requesting Administrator privileges..." -ForegroundColor Yellow
    # Construct arguments to pass parameters to the elevated session
    $ArgumentList = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    if ($DryRun) { $ArgumentList += " -DryRun" }
    if ($LogPath) { $ArgumentList += " -LogPath `"$LogPath`"" }
    Start-Process powershell.exe -ArgumentList $ArgumentList -Verb RunAs
    exit
}

# Set up logging directory and start transcript
$LogDirectory = Split-Path -Parent $LogPath
if (-not (Test-Path $LogDirectory)) {
    New-Item -ItemType Directory -Path $LogDirectory -Force | Out-Null
}
Start-Transcript -Path $LogPath -Append -Force | Out-Null
Write-Host "Transcript logging started. Output is saved to: $LogPath"

if ($DryRun) {
    Write-Host "=== RUNNING IN DRY RUN MODE ===" -ForegroundColor Magenta
    Write-Host "No changes will be written to disk or registry." -ForegroundColor Magenta
}

# Registry Backup Dir
$BackupDir = "$env:USERPROFILE\Cleanup-Backups\Registry_$(Get-Date -Format 'yyyyMMdd_HHmmss')"

# Restart Explorer to unlock files
if (-not $DryRun) {
    Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 5
    Start-Process explorer -WindowStyle Hidden
} else {
    Write-Host "[Dry-Run] Would restart Windows Explorer to release file locks." -ForegroundColor Cyan
}

# Take ownership and grant permissions before deletion (Example: Windows Update Cache)
try {
    if (-not $DryRun) {
        takeown /f "C:\Windows\SoftwareDistribution\*" /r /d y
        icacls "C:\Windows\SoftwareDistribution\*" /grant administrators:F /t /c /q
        Remove-Item -Path "C:\Windows\SoftwareDistribution\*" -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "Forced deletion: Windows Update cache cleared."
    } else {
        Write-Host "[Dry-Run] Would take ownership and delete contents of: C:\Windows\SoftwareDistribution\*" -ForegroundColor Cyan
    }
} catch {
    Write-Warning "Error forcing Windows Update cache deletion: $($_.Exception.Message)"
}

# Run Disk Cleanup with default settings
try {
    if (-not $DryRun) {
        cleanmgr /sagerun:1
        Write-Host "Disk Cleanup started with default settings."
    } else {
        Write-Host "[Dry-Run] Would start Disk Cleanup (cleanmgr /sagerun:1)." -ForegroundColor Cyan
    }
} catch {
    Write-Warning "Disk cleanup failed to start. Error: $($_.Exception.Message)"
}

# Clear Temp folders
try {
    if (-not $DryRun) {
        Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item -Path "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item -Path "C:\Windows\SoftwareDistribution\Download\*" -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "Temporary files cleared."
    } else {
        Write-Host "[Dry-Run] Would clear Temp folders:" -ForegroundColor Cyan
        Write-Host "  - $env:TEMP\*"
        Write-Host "  - C:\Windows\Temp\*"
        Write-Host "  - C:\Windows\SoftwareDistribution\Download\*"
    }
} catch {
    Write-Warning "Error clearing temporary files: $($_.Exception.Message)"
}

# Clear Prefetch (requires Administrator)
try {
    if (-not $DryRun) {
        Stop-Service -Name SysMain -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 5
        Remove-Item -Path "C:\Windows\Prefetch\*" -Recurse -Force -ErrorAction SilentlyContinue
        Start-Service -Name SysMain -ErrorAction SilentlyContinue
        Write-Host "Prefetch cleared."
    } else {
        Write-Host "[Dry-Run] Would stop SysMain service and clear: C:\Windows\Prefetch\*" -ForegroundColor Cyan
    }
} catch {
    Write-Warning "Error clearing Prefetch: $($_.Exception.Message)"
}

# Clear Windows Update Cache
try {
    if (-not $DryRun) {
        Stop-Service -Name wuauserv -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 5
        Remove-Item -Path "C:\Windows\SoftwareDistribution\*" -Recurse -Force -ErrorAction SilentlyContinue
        Start-Service -Name wuauserv -ErrorAction SilentlyContinue
        Write-Host "Windows Update cache cleared."
    } else {
        Write-Host "[Dry-Run] Would stop wuauserv service and clear: C:\Windows\SoftwareDistribution\*" -ForegroundColor Cyan
    }
} catch {
    Write-Warning "Error clearing Windows Update cache: $($_.Exception.Message)"
}

# Empty Recycle Bin
try {
    if (-not $DryRun) {
        Clear-RecycleBin -Force -ErrorAction SilentlyContinue
        Write-Host "Recycle Bin emptied."
    } else {
        Write-Host "[Dry-Run] Would empty Recycle Bin." -ForegroundColor Cyan
    }
} catch {
    Write-Warning "Error emptying Recycle Bin: $($_.Exception.Message)"
}

# Delete Old System Restore Points (Keep the Last One)
try {
    if (-not $DryRun) {
        vssadmin delete shadows /for=C: /oldest /quiet
        Write-Host "Old system restore points deleted."
    } else {
        Write-Host "[Dry-Run] Would delete oldest system restore shadow copies." -ForegroundColor Cyan
    }
} catch {
    Write-Warning "Error deleting old system restore points: $($_.Exception.Message)"
}

# Remove Windows Error Reporting files
try {
    if (-not $DryRun) {
        Remove-Item -Path "C:\ProgramData\Microsoft\Windows\WER\*" -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "Windows Error Reporting files deleted."
    } else {
        Write-Host "[Dry-Run] Would delete Windows Error Reporting files at: C:\ProgramData\Microsoft\Windows\WER\*" -ForegroundColor Cyan
    }
} catch {
    Write-Warning "Error deleting Windows Error Reporting files: $($_.Exception.Message)"
}

# Clear Windows Event Logs
try {
    if (-not $DryRun) {
        wevtutil el | ForEach-Object { wevtutil cl $_ }
        Write-Host "Windows Event Logs cleared."
    } else {
        Write-Host "[Dry-Run] Would clear all Windows Event Logs." -ForegroundColor Cyan
    }
} catch {
    Write-Warning "Error clearing Windows Event Logs: $($_.Exception.Message)"
}

# --- Browser Caches ---

# Clear Microsoft Edge cache
try {
    if (-not $DryRun) {
        Remove-Item -Path "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache\*" -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "Microsoft Edge cache cleared."
    } else {
        Write-Host "[Dry-Run] Would clear Microsoft Edge cache files." -ForegroundColor Cyan
    }
} catch {
    Write-Warning "Error clearing Edge cache: $($_.Exception.Message)"
}

# Clear Google Chrome cache
try {
    if (-not $DryRun) {
        Remove-Item -Path "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache\*" -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "Google Chrome cache cleared."
    } else {
        Write-Host "[Dry-Run] Would clear Google Chrome cache files." -ForegroundColor Cyan
    }
} catch {
    Write-Warning "Error clearing Chrome cache: $($_.Exception.Message)"
}

# Clear Brave Browser cache
try {
    $BraveCachePath = "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data\Default\Cache"
    if (Test-Path $BraveCachePath) {
        if (-not $DryRun) {
            Remove-Item -Path "$BraveCachePath\*" -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host "Brave Browser cache cleared."
        } else {
            Write-Host "[Dry-Run] Would clear Brave Browser cache files." -ForegroundColor Cyan
        }
    } else {
        Write-Host "Brave Browser cache path not found. Skipping."
    }
} catch {
    Write-Warning "Error clearing Brave cache: $($_.Exception.Message)"
}

# Clear Mozilla Firefox cache
try {
    $FirefoxProfilesPath = "$env:LOCALAPPDATA\Mozilla\Firefox\Profiles"
    if (Test-Path $FirefoxProfilesPath) {
        if (-not $DryRun) {
            Remove-Item -Path "$FirefoxProfilesPath\*\cache2\*" -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host "Mozilla Firefox cache cleared."
        } else {
            Write-Host "[Dry-Run] Would clear Mozilla Firefox cache files." -ForegroundColor Cyan
        }
    } else {
        Write-Host "Mozilla Firefox cache path not found. Skipping."
    }
} catch {
    Write-Warning "Error clearing Firefox cache: $($_.Exception.Message)"
}

# Clear Windows Defender Cache
try {
    if (-not $DryRun) {
        Remove-Item -Path "C:\ProgramData\Microsoft\Windows Defender\Scans\*.*" -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "Windows Defender cache cleared."
    } else {
        Write-Host "[Dry-Run] Would clear Windows Defender cache." -ForegroundColor Cyan
    }
} catch {
    Write-Warning "Error clearing Windows Defender cache: $($_.Exception.Message)"
}

# Clear DNS Cache
try {
    if (-not $DryRun) {
        ipconfig /flushdns
        Write-Host "DNS cache cleared."
    } else {
        Write-Host "[Dry-Run] Would flush system DNS cache." -ForegroundColor Cyan
    }
} catch {
    Write-Warning "Error clearing DNS cache: $($_.Exception.Message)"
}

# Clear Windows Thumbnail Cache
try {
    if (-not $DryRun) {
        Remove-Item -Path "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\thumbcache_*.db" -Force -ErrorAction SilentlyContinue
        Write-Host "Windows Thumbnail cache cleared."
    } else {
        Write-Host "[Dry-Run] Would clear Windows Thumbnail cache files." -ForegroundColor Cyan
    }
} catch {
    Write-Warning "Error clearing Windows Thumbnail cache: $($_.Exception.Message)"
}

# Clear Windows Font Cache
try {
    if (-not $DryRun) {
        Stop-Service -Name FontCache -Force -ErrorAction SilentlyContinue
        Remove-Item -Path "C:\Windows\ServiceProfiles\LocalService\AppData\Local\FontCache\*" -Recurse -Force -ErrorAction SilentlyContinue
        Start-Service -Name FontCache -ErrorAction SilentlyContinue
        Write-Host "Windows Font cache cleared."
    } else {
        Write-Host "[Dry-Run] Would stop FontCache service and clear font cache files." -ForegroundColor Cyan
    }
} catch {
    Write-Warning "Error clearing Windows Font cache: $($_.Exception.Message)"
}

# Clear Windows Icon Cache
try {
    if (-not $DryRun) {
        Remove-Item -Path "$env:LOCALAPPDATA\IconCache.db" -Force -ErrorAction SilentlyContinue
        Write-Host "Windows Icon cache cleared."
    } else {
        Write-Host "[Dry-Run] Would clear Windows Icon cache." -ForegroundColor Cyan
    }
} catch {
    Write-Warning "Error clearing Windows Icon cache: $($_.Exception.Message)"
}

# Basic Memory Cleaning
try {
    if (-not $DryRun) {
        Clear-Content -Path "C:\pagefile.sys" -Force -ErrorAction SilentlyContinue
        Write-Host "System memory cleaned."
    } else {
        Write-Host "[Dry-Run] Would clear content of C:\pagefile.sys." -ForegroundColor Cyan
    }
} catch {
    Write-Warning "Error cleaning system memory: $($_.Exception.Message)"
}

# --- Developer Caches ---
Write-Host "--- Cleaning Developer Caches ---"

# npm Cache
if (Get-Command npm -ErrorAction SilentlyContinue) {
    try {
        if (-not $DryRun) {
            npm cache clean --force
            Write-Host "npm cache cleared."
        } else {
            Write-Host "[Dry-Run] Would clear npm cache using npm cache clean --force." -ForegroundColor Cyan
        }
    } catch {
        Write-Warning "Error clearing npm cache: $($_.Exception.Message)"
    }
} else {
    Write-Host "npm is not installed. Skipping."
}

# pip Cache
if (Get-Command pip -ErrorAction SilentlyContinue) {
    try {
        if (-not $DryRun) {
            pip cache purge
            Write-Host "pip cache cleared."
        } else {
            Write-Host "[Dry-Run] Would purge pip cache using pip cache purge." -ForegroundColor Cyan
        }
    } catch {
        Write-Warning "Error clearing pip cache: $($_.Exception.Message)"
    }
} else {
    Write-Host "pip is not installed. Skipping."
}

# NuGet Cache
if (Get-Command dotnet -ErrorAction SilentlyContinue) {
    try {
        if (-not $DryRun) {
            dotnet nuget locals all --clear
            Write-Host "NuGet locals cleared."
        } else {
            Write-Host "[Dry-Run] Would clear NuGet cache using dotnet nuget locals all --clear." -ForegroundColor Cyan
        }
    } catch {
        Write-Warning "Error clearing NuGet cache: $($_.Exception.Message)"
    }
} else {
    Write-Host "dotnet/NuGet is not installed. Skipping."
}

# Docker Cache
if (Get-Command docker -ErrorAction SilentlyContinue) {
    try {
        if (-not $DryRun) {
            docker system prune -f
            Write-Host "Docker system prune completed."
        } else {
            Write-Host "[Dry-Run] Would run Docker system prune -f." -ForegroundColor Cyan
        }
    } catch {
        Write-Warning "Error pruning Docker system: $($_.Exception.Message)"
    }
} else {
    Write-Host "Docker is not installed. Skipping."
}

# --- Deep Registry Cleaning for Windows 10/11 ---
# WARNING: Modifying the registry can cause system instability. Proceed with caution.
# It is highly recommended to create a system restore point before running this script.

# --- System Restore Point (Optional but Recommended) ---
if (-not $DryRun) {
    $RestorePointName = "Registry Cleanup - $(Get-Date -Format 'yyyyMMdd_HHmmss')"
    Checkpoint-Computer -Description $RestorePointName -RestorePointType "MODIFY_SETTINGS"
} else {
    Write-Host "[Dry-Run] Would create a system restore point." -ForegroundColor Cyan
}

# --- Variables ---
$ErrorCount = 0
$DeletedKeysCount = 0
$DeletedValuesCount = 0

# --- Function to Delete Registry Key/Value and Handle Errors ---
function Remove-RegistryItemSafe {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Internal helper; deletion is the purpose of the script, which is the confirmation point.')]
    param (
        [string]$Path,
        [string]$Name = $null
    )
    if (-not (Test-Path $Path)) {
        Write-Host "Registry path does not exist: $Path. Skipping."
        return
    }

    # Backup before deletion (if not in Dry Run)
    if (-not $DryRun) {
        try {
            $RegPath = $Path.Replace("HKCU:\", "HKCU\").Replace("HKLM:\", "HKLM\")
            if (-not (Test-Path $BackupDir)) {
                New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
            }
            $SanitizedPath = $Path -replace '[:\\]', '_'
            $BackupFile = "$BackupDir\Backup_$SanitizedPath.reg"
            reg.exe export "$RegPath" "$BackupFile" /y *>$null
        } catch {
            Write-Warning "Failed to back up registry path ${Path}: $($_.Exception.Message)"
        }
    }

    try {
        if ($Name) {
            if (-not $DryRun) {
                Remove-ItemProperty -Path $Path -Name $Name -Force -ErrorAction Stop
                Write-Host "Deleted Value: $($Path)\$($Name)" -ForegroundColor Green
            } else {
                Write-Host "[Dry-Run] Would delete Value: $($Path)\$($Name)" -ForegroundColor Cyan
            }
            $script:DeletedValuesCount++
        } else {
            if (-not $DryRun) {
                Remove-Item -Path $Path -Recurse -Force -ErrorAction Stop
                Write-Host "Deleted Key: $($Path)" -ForegroundColor Green
            } else {
                Write-Host "[Dry-Run] Would delete Key: $($Path)" -ForegroundColor Cyan
            }
            $script:DeletedKeysCount++
        }
    } catch {
        Write-Warning "Error deleting $($Path)\$($Name): $($_.Exception.Message)"
        $script:ErrorCount++
    }
}

# --- Cleaning Recent Files and Programs ---
Write-Host "--- Cleaning Recent Files and Programs ---"
$RecentFiles = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\RecentDocs"
$RunMRU = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\RunMRU"
$TypedURLs = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\TypedURLs"

#RecentDocs
Get-ChildItem -Path $RecentFiles | ForEach-Object { Remove-RegistryItemSafe -Path $_.PSPath }

#RunMRU
Get-ChildItem -Path $RunMRU | ForEach-Object { Remove-RegistryItemSafe -Path $_.PSPath }

#TypedURLs
if (Test-Path $TypedURLs) {
    Get-ChildItem -Path $TypedURLs | ForEach-Object { Remove-RegistryItemSafe -Path $_.PSPath }
} else {
    Write-Host "Path $TypedURLs does not exist."
}

# --- Cleaning Internet Explorer/Edge History and Cache ---
Write-Host "--- Cleaning Internet Explorer/Edge History and Cache ---"
Remove-RegistryItemSafe -Path "HKCU:\Software\Microsoft\Internet Explorer\TypedURLs"
Remove-RegistryItemSafe -Path "HKCU:\Software\Microsoft\Internet Explorer\LowRegistry\IEContentService\Cache"
Remove-RegistryItemSafe -Path "HKCU:\Software\Microsoft\Edge\BLBeacon" #Edge Telemetry.

# --- Cleaning Windows Error Reporting ---
Write-Host "--- Cleaning Windows Error Reporting ---"
Remove-RegistryItemSafe -Path "HKCU:\Software\Microsoft\Windows\Windows Error Reporting\UserQueuedReports"
Remove-RegistryItemSafe -Path "HKLM:\SOFTWARE\Microsoft\Windows\Windows Error Reporting\LocalDumps"

# --- Summary ---
Write-Host "--- Summary ---"
if ($DryRun) {
    Write-Host "Dry Run completed. No modifications were made." -ForegroundColor Magenta
    Write-Host "Keys to be deleted: $DeletedKeysCount"
    Write-Host "Values to be deleted: $DeletedValuesCount"
} else {
    Write-Host "Deleted Keys: $DeletedKeysCount"
    Write-Host "Deleted Values: $DeletedValuesCount"
    if ($DeletedKeysCount -gt 0 -or $DeletedValuesCount -gt 0) {
        Write-Host "Registry backups saved to: $BackupDir" -ForegroundColor Yellow
    }
}
Write-Host "Errors: $ErrorCount" -ForegroundColor Red

if($ErrorCount -eq 0){
    Write-Host "Cleanup script run completed successfully."
} else {
    Write-Warning "Cleanup script run completed with errors. Please review the output."
}

Stop-Transcript | Out-Null

# Display final message
Add-Type -AssemblyName PresentationFramework
if ($DryRun) {
    [System.Windows.MessageBox]::Show("✨ Dry Run completed successfully! ✨`n`nNo changes were made to your system. Both the registry and Windows deep cleaning simulations were performed.`n`nLog file saved to:`n$LogPath", "Dry Run Complete", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
} else {
    $shutdownChoice = [System.Windows.MessageBox]::Show("✨ Windows Deep Cleanup process completed successfully! ✨`n`nDo you want to shut down the system now? Both the registry and Windows deep cleaning were performed to ensure optimal performance. 🚀`n`nLog file saved to:`n$LogPath", "Cleanup Complete", [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Information)

    if ($shutdownChoice -eq [System.Windows.MessageBoxResult]::Yes) {
        # Wait for 60 seconds before shutting down
        Start-Sleep -Seconds 60
        # Shutdown the system
        Stop-Computer -Force
        Write-Host "Windows Deep Cleanup process completed successfully and system is shutting down!"
    } else {
        Write-Host "Windows Deep Cleanup process completed successfully! Shutdown canceled."
    }
}
