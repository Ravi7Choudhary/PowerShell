# Name - Ravi Choudhary (ravi7cchoudhary@gmail.com)
# Date - 28/10/2024
# Purpose - Setup of server with basic hardening steps

<# Instructions

#>

Write-Host "*****************************************************" -ForegroundColor Cyan
Write-Host                  "Server Setup/Hardening"               -ForegroundColor Cyan
Write-Host "*****************************************************" -ForegroundColor Cyan
Write-Host "This Script will setup the server for first use"     -ForegroundColor Green
Write-Host "as it includes below operations:" -ForegroundColor Green
Write-Host "1. Windows Time Sync" -ForegroundColor Green
Write-Host "2. Renaming of Hostname to its MAC Address" -ForegroundColor Green
Write-Host "3. Zabbix Agent Deployment and Configuration" -ForegroundColor Green
Write-Host "4. Deploying Logmein Silently" -ForegroundColor Green
Read-Host "If you are sure to proceed on this server, press enter to continue"

# 1. Force Windows Time Resync
Write-Host "Syncing Time..."
w32tm /resync
Write-Output "Windows time resynced successfully."-ForegroundColor Green

# 2. Deploy Zabbix Agent with Passive and Active Server Parameters
# Define Zabbix Server details
$zabbixServer = "3.105.94.198"
$zabbixConfigPath = "C:\Program Files\Zabbix Agent\zabbix_agentd.conf"

# Download Zabbix Agent (ensure URL and installation commands match your setup)
#Invoke-WebRequest -Uri "https://www.zabbix.com/downloads/5.4.6/zabbix_agent-5.4.6-windows-amd64-openssl.msi" -OutFile "C:\temp\zabbix_agent.msi"
Write-Host "Installing Zabbix..."
Start-Process "msiexec.exe" -ArgumentList "/i C:\deploy\zabbix_agent2.msi /quiet /norestart /l*v C:\deploy\zabbix_install.log" -Wait

# Set server parameters in configuration file
Write-Host "Configuring Active & Passive Server Parameters..."
(Get-Content -Path $zabbixConfigPath) | ForEach-Object {
    $_ -replace 'Server=.*', "Server=$zabbixServer"
    $_ -replace 'ServerActive=.*', "ServerActive=$zabbixServer"
} | Set-Content -Path $zabbixConfigPath

Write-Output "Zabbix Agent deployed and configured successfully."  -ForegroundColor Green

# 3. Deploy LogMeIn Silently and Define Passcode
# Replace with the correct installer path and passcode
Write-Host "Installing Logmein..."
$logmeinPasscode = "!Password123!"
#Invoke-WebRequest -Uri "https://secure.logmein.com/logmein.msi" -OutFile "C:\temp\logmein.msi"
Start-Process "msiexec.exe" -ArgumentList "/i C:\deploy\LogMeIn.msi /quiet /norestart PASSCODE=$logmeinPasscode" -Wait
Write-Output "LogMeIn installed with specified passcode." -ForegroundColor Green

# 4. Run Application Shortcut as Administrator
# Specify the path to the shortcut file
Creating Application Shortcut...
$shortcutPath = "C:\Path\To\Application.lnk"
Start-Process -FilePath $shortcutPath -Verb RunAs
Write-Output "Application run as administrator." -ForegroundColor Green

# 5. Rename Hostname to MAC Address of Connected Interface
Write-Host "Changing Hostname to MACAddress..."
$macAddress = (Get-NetAdapter | Where-Object {$_.Status -eq "Up"} | Select-Object -ExpandProperty MacAddress).Replace("-", "")
Rename-Computer -NewName $macAddress -Force
Write-Output "Computer renamed to MAC address: $macAddress" -ForegroundColor Green

# 6. Final Reboot of the server (to recognize hostname change and setup other changes)
Write-Output "Server will reboot now for hostname change and setup final changes..."
Write-Host "Please check the console for any errors as after this the reboot"
Write-Host "of the server will take place."
Read-Host "Press Enter to continue with the final reboot"
Restart-Computer -Force -Wait

