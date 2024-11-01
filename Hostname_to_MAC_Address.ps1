# Developer - Ravi Choudhary (ravi7cchoudhary@gmail.com) 
# Date - 1/11/2024
# Purpose - Setup of server with basic hardening steps

#####################################################################################################
<# Instructions
This Script will do below tasks on the server it is being ran on and in the same sequence:
1. Rename hostname to MAC Address of connected interface
2. Reboot of Server

Hostname will be set to MAC Address of the server.
#>

#####################################################################################################

# Display Banner
Write-Host "******************************************************" -ForegroundColor Cyan
Write-Host "                  Renaming Hostname                   " -ForegroundColor Cyan
Write-Host "******************************************************" -ForegroundColor Cyan
Write-Host "This Script will rename the Server Hostname and it" -ForegroundColor Green
Write-Host "includes the following operations:" -ForegroundColor Green
Write-Host "1. Renaming Hostname to MAC Address" -ForegroundColor Green
Write-Host "2. Reboot of Server" -ForegroundColor Green
Read-Host "If you are sure to proceed, press Enter to continue."

# Rename Hostname to MAC Address of Connected Interface
try {
    Write-Host "Renaming Hostname to MAC Address..."
    $macAddress = (Get-NetAdapter | Where-Object {$_.Status -eq "Up"} | Select-Object -ExpandProperty MacAddress).Replace("-", "")
    Rename-Computer -NewName $macAddress -Force
    Write-Host "Computer renamed to MAC address: $macAddress" -ForegroundColor Green
} catch {
    Write-Host "Error renaming computer to MAC address: $_" -ForegroundColor Red
}

# Reboot of the Server
Write-Host "The system is about to reboot to apply hostname changes" -ForegroundColor Green
Write-Host "Please review any console messages for errors before" -ForegroundColor Green
Write-Host "the reboot proceeds." -ForegroundColor Green
Read-Host "Press Enter to proceed with the final reboot."
try {
    Restart-Computer -Force -Wait
} catch {
    Write-Host "Error initiating reboot: $_" -ForegroundColor Red
}