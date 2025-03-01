# Enhanced Windows Deep Cleanup Script (Run as Administrator)
# Built by: Pause_Navigator
# Email: pausenavigator@gmail.com
# With the help and assistance of: Copilot
# URL: https://copilot.microsoft.com
# RUN AT YOUR OWN RISK.
# DO NOT EDIT AND DO NOT CHANGE ANYTHING TO THIS SCRIPT.
# This script is to be copied and pasted in PowerShell that was run previously as Administrator.

# Enhanced Windows Deep Cleanup Script (Run as Administrator)

# Check for Administrator privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "This script requires Administrator privileges. Right-click and select 'Run as administrator'."
    exit
}

# Relaunch as Admin if Not Already
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# Restart Explorer to unlock files
Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 5
Start-Process explorer -WindowStyle Hidden

# Take ownership and grant permissions before deletion (Example: Windows Update Cache)
try {
    takeown /f "C:\Windows\SoftwareDistribution\*" /r /d y
    icacls "C:\Windows\SoftwareDistribution\*" /grant administrators:F /t /c /q
    Remove-Item -Path "C:\Windows\SoftwareDistribution\*" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "Forced deletion: Windows Update cache cleared."
} catch {
    Write-Warning "Error forcing Windows Update cache deletion: $($_.Exception.Message)"
}

# Run Disk Cleanup with default settings
try {
    cleanmgr /sagerun:1
    Write-Host "Disk Cleanup started with default settings."
} catch {
    Write-Warning "Disk cleanup failed to start. Error: $($_.Exception.Message)"
}

# Clear Temp folders
try {
    Get-ChildItem -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    Get-ChildItem -Path "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    Get-ChildItem -Path "C:\Windows\SoftwareDistribution\Download\*" -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "Temporary files cleared."
} catch {
    Write-Warning "Error clearing temporary files: $($_.Exception.Message)"
}

# Clear Prefetch (requires Administrator)
try {
    Stop-Service -Name SysMain -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 5
    Get-ChildItem -Path "C:\Windows\Prefetch\*" -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    Start-Service -Name SysMain -ErrorAction SilentlyContinue
    Write-Host "Prefetch cleared."
} catch {
    Write-Warning "Error clearing Prefetch: $($_.Exception.Message)"
}

# Clear Windows Update Cache
try {
    Stop-Service -Name wuauserv -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 5
    Remove-Item -Path "C:\Windows\SoftwareDistribution\*" -Recurse -Force -ErrorAction SilentlyContinue
    Start-Service -Name wuauserv -ErrorAction SilentlyContinue
    Write-Host "Windows Update cache cleared."
} catch {
    Write-Warning "Error clearing Windows Update cache: $($_.Exception.Message)"
}

# Empty Recycle Bin
try {
    Clear-RecycleBin -Force -ErrorAction SilentlyContinue
    Write-Host "Recycle Bin emptied."
} catch {
    Write-Warning "Error emptying Recycle Bin: $($_.Exception.Message)"
}

# Delete Old System Restore Points (Keep the Last One)
try {
    vssadmin delete shadows /for=C: /oldest /quiet
    Write-Host "Old system restore points deleted."
} catch {
    Write-Warning "Error deleting old system restore points: $($_.Exception.Message)"
}

# Remove Windows Error Reporting files
try {
    Remove-Item -Path "C:\ProgramData\Microsoft\Windows\WER\*" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "Windows Error Reporting files deleted."
} catch {
    Write-Warning "Error deleting Windows Error Reporting files: $($_.Exception.Message)"
}

# Clear Windows Event Logs
try {
    wevtutil el | ForEach-Object { wevtutil cl $_ }
    Write-Host "Windows Event Logs cleared."
} catch {
    Write-Warning "Error clearing Windows Event Logs: $($_.Exception.Message)"
}

# Clear Microsoft Edge cache
try {
    Remove-Item -Path "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache\*" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "Microsoft Edge cache cleared."
} catch {
    Write-Warning "Error clearing Edge cache: $($_.Exception.Message)"
}

# Clear Google Chrome cache
try {
    Remove-Item -Path "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache\*" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "Google Chrome cache cleared."
} catch {
    Write-Warning "Error clearing Chrome cache: $($_.Exception.Message)"
}

# Clear Windows Defender Cache
try {
    Remove-Item -Path "C:\ProgramData\Microsoft\Windows Defender\Scans\*.*" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "Windows Defender cache cleared."
} catch {
    Write-Warning "Error clearing Windows Defender cache: $($_.Exception.Message)"
}

# Clear DNS Cache
try {
    ipconfig /flushdns
    Write-Host "DNS cache cleared."
} catch {
    Write-Warning "Error clearing DNS cache: $($_.Exception.Message)"
}

# Clear Windows Thumbnail Cache
try {
    Remove-Item -Path "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\thumbcache_*.db" -Force -ErrorAction SilentlyContinue
    Write-Host "Windows Thumbnail cache cleared."
} catch {
    Write-Warning "Error clearing Windows Thumbnail cache: $($_.Exception.Message)"
}

# Clear Windows Font Cache
try {
    Stop-Service -Name FontCache -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "C:\Windows\ServiceProfiles\LocalService\AppData\Local\FontCache\*" -Recurse -Force -ErrorAction SilentlyContinue
    Start-Service -Name FontCache -ErrorAction SilentlyContinue
    Write-Host "Windows Font cache cleared."
} catch {
    Write-Warning "Error clearing Windows Font cache: $($_.Exception.Message)"
}

# Clear Windows Icon Cache
try {
    Remove-Item -Path "$env:LOCALAPPDATA\IconCache.db" -Force -ErrorAction SilentlyContinue
    Write-Host "Windows Icon cache cleared."
} catch {
    Write-Warning "Error clearing Windows Icon cache: $($_.Exception.Message)"
}

# Basic Memory Cleaning
try {
    Clear-Content -Path "C:\pagefile.sys" -Force -ErrorAction SilentlyContinue
    Write-Host "System memory cleaned."
} catch {
    Write-Warning "Error cleaning system memory: $($_.Exception.Message)"
}

# Deep Registry Cleaning for Windows 10 (PowerShell)
# WARNING: Modifying the registry can cause system instability. Proceed with caution.
# It is highly recommended to create a system restore point before running this script.

# --- System Restore Point (Optional but Recommended) ---
$RestorePointName = "Registry Cleanup - $(Get-Date -Format 'yyyyMMdd_HHmmss')"
Checkpoint-Computer -Description $RestorePointName -RestorePointType "MODIFY_SETTINGS"

# --- Variables ---
$ErrorCount = 0
$DeletedKeysCount = 0
$DeletedValuesCount = 0

# --- Function to Delete Registry Key/Value and Handle Errors ---
function Delete-RegistryItemSafe {
    param (
        [string]$Path,
        [string]$Name = $null
    )
    try {
        if ($Name) {
            Remove-ItemProperty -Path $Path -Name $Name -Force -ErrorAction Stop
            Write-Host "Deleted Value: $($Path)\$($Name)" -ForegroundColor Green
            $global:DeletedValuesCount++
        } else {
            Remove-Item -Path $Path -Recurse -Force -ErrorAction Stop
            Write-Host "Deleted Key: $($Path)" -ForegroundColor Green
            $global:DeletedKeysCount++
        }
    } catch {
        Write-Warning "Error deleting $($Path)\$($Name): $($_.Exception.Message)"
        $global:ErrorCount++
    }
}

# --- Cleaning Recent Files and Programs ---
Write-Host "--- Cleaning Recent Files and Programs ---"
$RecentFiles = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\RecentDocs"
$RunMRU = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\RunMRU"
$TypedURLs = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\TypedURLs"
$UninstallKeys = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall", "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall"

#RecentDocs
Get-ChildItem -Path $RecentFiles | ForEach-Object { Delete-RegistryItemSafe -Path $_.PSPath }

#RunMRU
Get-ChildItem -Path $RunMRU | ForEach-Object { Delete-RegistryItemSafe -Path $_.PSPath }

#TypedURLs
if (Test-Path $TypedURLs) {
    Get-ChildItem -Path $TypedURLs | ForEach-Object { Delete-RegistryItemSafe -Path $_.PSPath }
} else {
    Write-Host "Path $TypedURLs does not exist."
}

#Uninstall Keys (Orphaned Entries)
foreach ($UninstallKey in $UninstallKeys) {
    Get-ChildItem -Path $UninstallKey | ForEach-Object {
        $DisplayName = Get-ItemProperty -Path $_.PSPath -Name DisplayName -ErrorAction SilentlyContinue
        if (-not $DisplayName) {
            Delete-RegistryItemSafe -Path $_.PSPath
        }
    }
}

# --- Cleaning Internet Explorer/Edge History and Cache ---
Write-Host "--- Cleaning Internet Explorer/Edge History and Cache ---"
$IEDownloadPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders"
Delete-RegistryItemSafe -Path "HKCU:\Software\Microsoft\Internet Explorer\TypedURLs"
Delete-RegistryItemSafe -Path "HKCU:\Software\Microsoft\Internet Explorer\LowRegistry\IEContentService\Cache"
Delete-RegistryItemSafe -Path "HKCU:\Software\Microsoft\Edge\BLBeacon" #Edge Telemetry.

# --- Cleaning System Leftovers ---
Write-Host "--- Cleaning System Leftovers ---"
Delete-RegistryItemSafe -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths"
Delete-RegistryItemSafe -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers"
Delete-RegistryItemSafe -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\PendingFileRenameOperations"
Delete-RegistryItemSafe -Path "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\App Paths" #For 64bit systems

# --- Cleaning Windows Error Reporting ---
Write-Host "--- Cleaning Windows Error Reporting ---"
Delete-RegistryItemSafe -Path "HKCU:\Software\Microsoft\Windows\Windows Error Reporting\UserQueuedReports"
Delete-RegistryItemSafe -Path "HKLM:\SOFTWARE\Microsoft\Windows\Windows Error Reporting\LocalDumps"

# --- Summary ---
Write-Host "--- Summary ---"
Write-Host "Deleted Keys: $DeletedKeysCount"
Write-Host "Deleted Values: $DeletedValuesCount"
Write-Host "Errors: $ErrorCount" -ForegroundColor Red

if($ErrorCount -eq 0){
    Write-Host "Registry cleaning completed successfully."
} else {
    Write-Warning "Registry cleaning completed with errors. Please review the output."
}

# Display final message with two choices
Add-Type -AssemblyName PresentationFramework
$shutdownChoice = [System.Windows.MessageBox]::Show("✨ Windows Deep Cleanup process completed successfully! ✨`n`nDo you want to shut down the system now? Both the registry and Windows deep cleaning were performed to ensure optimal performance. 🚀", "Cleanup Complete", [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Information)

if ($shutdownChoice -eq [System.Windows.MessageBoxResult]::Yes) {
    # Wait for 60 seconds before shutting down
    Start-Sleep -Seconds 60
    # Shutdown the system
    Stop-Computer -Force
    Write-Host "Windows Deep Cleanup process completed successfully and system is shutting down!"
} else {
    Write-Host "Windows Deep Cleanup process completed successfully! Shutdown canceled."
}