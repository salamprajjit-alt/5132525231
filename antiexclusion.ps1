#Requires -Version 5.1
#Requires -RunAsAdministrator

while ($true) {
    # Check for Windows Security (Defender) Exclusions page
    $exclusionsWindow = Get-Process | Where-Object {
        $_.ProcessName -eq "SecurityHealthHost" -and 
        $_.MainWindowTitle -like "*Exclusions*"
    }

    if ($exclusionsWindow) {
        Write-Host "Exclusions page detected - terminating..."
        Stop-Process -Id $exclusionsWindow.Id -Force
        Write-Host "Windows Security has been closed."
    }

    # Check every 3 seconds
    Start-Sleep -Seconds 3
}