@echo off
:: Check for administrator privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Requesting administrator privileges...
    powershell -Command "Start-Process cmd -ArgumentList '/c %0' -Verb RunAs"
    exit /b
)

echo Modifying Windows Defender settings...

:: Disable real-time monitoring
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v "DisableRealtimeMonitoring" /t REG_DWORD /d 1 /f

:: Disable behavior monitoring
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v "DisableBehaviorMonitoring" /t REG_DWORD /d 1 /f

:: Attempt to disable Defender entirely
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v "DisableAntiSpyware" /t REG_DWORD /d 1 /f

:: Disable scanning of downloads
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v "DisableIOAVProtection" /t REG_DWORD /d 1 /f

:: Disable cloud-based protection
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Spynet" /v "SubmitSamplesConsent" /t REG_DWORD /d 2 /f

:: Stop and disable the WinDefend service
sc stop WinDefend >nul 2>&1
sc config WinDefend start= disabled >nul 2>&1

echo Changes completed. A restart is recommended for these changes to take full effect.