# Developer - Ravi Choudhary (ravi7cchoudhary@gmail.com) 
# Date - 1/11/2024
# Purpose - Setup of server with basic hardening steps and app installation

#####################################################################################################
<# Instructions
This Script will do below tasks on the server it is being ran on and in the same sequence:
1. Force windows time resync
2. Deploy zabbix agent with passive and active server parameters
3. Deploy LogMeIn silently defining passcode
4. Run Broadsign bsp_dedicate.exe as Administrator
5. Reboot

Details being used in this script:
Zabbix Config:
msi package location = C:\deploy\
zabbixServer = "3.105.94.198"
zabbixConfigPath = "C:\Program Files\Zabbix Agent\zabbix_agentd.conf"

LogMeIn Config:
msi package location = C:\deploy\
logmeinPasscode = "!Password123!"

Run Broadsign bsp_dedicate.exe as Administrator and using below command for the same:
"C:\Program Files\Broadsign\bsp\bin\bsp_dedicate.exe" --dedicate --with_gui"
#>

#####################################################################################################

# Display Banner
Write-Host "******************************************************" -ForegroundColor Cyan
Write-Host "                Server Applications Setup              " -ForegroundColor Cyan
Write-Host "******************************************************" -ForegroundColor Cyan
Write-Host "This Script will set up the server for first use and includes the following operations:" -ForegroundColor Green
Write-Host "1. Windows Time Sync" -ForegroundColor Green
Write-Host "2. Zabbix Agent Deployment and Configuration" -ForegroundColor Green
Write-Host "3. LogMeIn Deployment" -ForegroundColor Green
Write-Host "4. Run Broadsign bsp_dedicate.exe as Administrator" -ForegroundColor Green
Read-Host "If you are sure to proceed, press Enter to continue"

# 1. Force Windows Time Resync
try {
    Write-Host "Syncing Time..."
    w32tm /resync
    Write-Host "Windows time resynced successfully." -ForegroundColor Green
} catch {
    Write-Host "Error resyncing Windows time: $_" -ForegroundColor Red
}

# 2. Deploy Zabbix Agent with Passive and Active Server Parameters
try {
    $zabbixServer = "3.105.94.198"
    $zabbixConfigPath = "C:\Program Files\Zabbix Agent\zabbix_agentd.conf"
    
    if (Test-Path -Path "C:\deploy\zabbix_agent2.msi") {
        Write-Host "Installing Zabbix Agent..."
        Start-Process "msiexec.exe" -ArgumentList "/i C:\deploy\zabbix_agent2.msi /quiet /norestart /l*v C:\deploy\zabbix_install.log" -Wait
        Write-Host "Zabbix Agent installed successfully." -ForegroundColor Green
        
        # Configure Zabbix server parameters
        Write-Host "Configuring Active & Passive Server Parameters..."
        (Get-Content -Path $zabbixConfigPath) | ForEach-Object {
            $_ -replace 'Server=.*', "Server=$zabbixServer"
            $_ -replace 'ServerActive=.*', "ServerActive=$zabbixServer"
        } | Set-Content -Path $zabbixConfigPath
        Write-Host "Zabbix Agent configured successfully." -ForegroundColor Green
    } else {
        Write-Host "Zabbix MSI file not found at C:\deploy\zabbix_agent2.msi" -ForegroundColor Red
    }
} catch {
    Write-Host "Error installing or configuring Zabbix Agent: $_" -ForegroundColor Red
}

# 3. Deploy LogMeIn Silently with Passcode
try {
    $logmeinPasscode = "!Password123!"
    if (Test-Path -Path "C:\deploy\LogMeIn.msi") {
        Write-Host "Installing LogMeIn..."
        Start-Process "msiexec.exe" -ArgumentList "/i C:\deploy\LogMeIn.msi /quiet /norestart PASSCODE=$logmeinPasscode" -Wait
        Write-Host "LogMeIn installed successfully." -ForegroundColor Green
    } else {
        Write-Host "LogMeIn MSI file not found at C:\deploy\LogMeIn.msi" -ForegroundColor Red
    }
} catch {
    Write-Host "Error installing LogMeIn: $_" -ForegroundColor Red
}

# 4. Run Broadsign bsp_dedicate.exe as Administrator
try {
    Write-Host "Executing bsp_dedicate.exe command as Administrator..."
    Start-Process -FilePath "C:\Program Files\Broadsign\bsp\bin\bsp_dedicate.exe" -ArgumentList "--dedicate --with_gui" -Verb RunAs
    Write-Host "bsp_dedicate.exe command executed successfully as Administrator." -ForegroundColor Green
} catch {
    Write-Host "Error executing bsp_dedicate.exe command: $_" -ForegroundColor Red
}

# 5. Final Reboot of the Server
Write-Host "The system is about to reboot to apply application setup changes. Please"
Write-Host "review any console messages for errors before the reboot proceeds."
Read-Host "Press Enter to proceed with the final reboot."
try {
    Restart-Computer -Force -Wait
} catch {
    Write-Host "Error initiating reboot: $_" -ForegroundColor Red
}
