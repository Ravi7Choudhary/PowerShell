# Author - Ravi Choudhary(ravi7cchoudhary@gmail.com)
# Purpose - This Script will lock all the drives and restrict users to use task manager for all the users other then All Users|Default|Public|Default User|Administrator

# Introduction to the script

Write-Host "*************************************************************" -ForegroundColor Green
Write-Host "                   Imply User Restrictions                   " -ForegroundColor Green
Write-Host "*************************************************************" -ForegroundColor Green
Write-Host "This PowerShell script restricts non-administrators by hiding" -ForegroundColor Green
Write-Host "all drives, disabling Quick Access and preventing drive access" -ForegroundColor Green
Write-Host "via File Explorer. It optionally disables Task Manager for" -ForegroundColor Green
Write-Host "added security." -ForegroundColor Green
Read-Host "Press Enter to continue"

# Set execution policy for the current session
Set-ExecutionPolicy remotesigned -Scope Process

# Explicitly set the path to the "Users" folder
$usersPath = "C:\Users"

# Get all user directories
$userDirs = Get-ChildItem -Path $usersPath -Directory

# Function to apply restrictions for a specific user
function Apply-UserRestrictions {
    param ($userSid)
    
    # Define registry policy paths
    $explorerPolicyPath = "Registry::HKEY_USERS\$userSid\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer"
    $systemPolicyPath = "Registry::HKEY_USERS\$userSid\Software\Microsoft\Windows\CurrentVersion\Policies\System"

    # Create required registry paths
    New-Item -Path $explorerPolicyPath -ErrorAction SilentlyContinue | Out-Null
    New-Item -Path $systemPolicyPath -ErrorAction SilentlyContinue | Out-Null

    # Restrict access to drives
    Set-ItemProperty -Path $explorerPolicyPath -Name "NoDrives" -Value 4294967295  # Hide all drives (value for all drives)
    Set-ItemProperty -Path $explorerPolicyPath -Name "NoViewOnDrive" -Value 4294967295  # Disable viewing drives entirely

    # Disable access to Quick Access
    Set-ItemProperty -Path $explorerPolicyPath -Name "NoRecentDocsHistory" -Value 1  # Disable recent documents
    Set-ItemProperty -Path $explorerPolicyPath -Name "NoRecentDocsMenu" -Value 1  # Disable recent documents menu
    Set-ItemProperty -Path $explorerPolicyPath -Name "NoRecentDocsNetHood" -Value 1  # Disable Quick Access in network locations

    # Disable Task Manager (optional, prevent bypassing restrictions)
    Set-ItemProperty -Path $systemPolicyPath -Name "DisableTaskMgr" -Value 1  # Disable Task Manager

    Write-Host "Restrictions applied to user SID: $userSid"
}

# Iterate over each user directory
foreach ($userDir in $userDirs) {
    # Skip system, default, public, or administrator profiles
    if ($userDir.Name -match "^(All Users|Default|Public|Default User|Administrator)$") {
        continue
    }

    try {
        # Get the user's SID
        $userSid = (New-Object System.Security.Principal.NTAccount($userDir.Name)).Translate([System.Security.Principal.SecurityIdentifier]).Value

        # Apply restrictions
        Apply-UserRestrictions -userSid $userSid
    }
    catch {
        Write-Host "Error processing user '$($userDir.Name)': $_"
    }
}
