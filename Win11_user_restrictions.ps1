# Author - Ravi Choudhary(ravi7cchoudhary@gmail.com)
# Purpose - This Script will lock all the drives and restrict users to use task manager for all the 
# users other then All Users|Default|Public|Default User|Administrator|administrator-sts
# Introduction to the script

Write-Host "*************************************************************" -ForegroundColor Green
Write-Host "            Imply User Restrictions Windows 11               " -ForegroundColor Green
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

# Function to load user registry hive
function Load-UserRegistryHive {
    param (
        [string]$userProfilePath,
        [string]$sid
    )

    # Path to NTUSER.DAT (user registry hive)
    $ntUserDat = Join-Path -Path $userProfilePath -ChildPath "NTUSER.DAT"
    $regHivePath = "HKEY_USERS\$sid"

    try {
        # Load the registry hive if not already loaded
        if (!(Test-Path $regHivePath)) {
            reg load "$regHivePath" "$ntUserDat" | Out-Null
            Write-Host "Registry hive loaded for user SID: $sid."
        }
    } catch {
        Write-Host "Error loading registry hive for user SID: $sid. $_"
    }
}

# Function to unload user registry hive
function Unload-UserRegistryHive {
    param (
        [string]$sid
    )
    $regHivePath = "HKEY_USERS\$sid"

    try {
        # Unload the registry hive if it exists
        if (Test-Path $regHivePath) {
            reg unload "$regHivePath" | Out-Null
            Write-Host "Registry hive unloaded for user SID: $sid."
        }
    } catch {
        Write-Host "Error unloading registry hive for user SID: $sid. $_"
    }
}

# Function to apply restrictions for a specific user
function Apply-UserRestrictions {
    param (
        [string]$userSid
    )

    try {
        # Define the registry path for Explorer policies
        $regPath = "HKEY_USERS\$userSid\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer"

        # Ensure the Explorer key exists
        reg add "HKEY_USERS\$userSid\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /f | Out-Null

        # Restrict access to all drives (hide all drives visually)
        reg add "$regPath" /v "NoDrives" /t REG_DWORD /d 4294967295 /f | Out-Null

        # Do not set NoViewOnDrive to allow folder access
        Write-Host "Drive restrictions applied for user SID: $userSid."

        # Disable Quick Access visibility by setting File Explorer to open "This PC"
        $userFileExplorerPath = "HKEY_USERS\$userSid\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
        reg add "$userFileExplorerPath" /v "LaunchTo" /t REG_DWORD /d 1 /f | Out-Null
        Write-Host "Quick Access disabled for user SID: $userSid."

        # Disable Quick Access features
        reg add "$regPath" /v "NoRecentDocsHistory" /t REG_DWORD /d 1 /f | Out-Null
        reg add "$regPath" /v "NoRecentDocsMenu" /t REG_DWORD /d 1 /f | Out-Null
        reg add "$regPath" /v "NoPinnedItems" /t REG_DWORD /d 1 /f | Out-Null

        # Disable Folder Options in File Explorer
        reg add "$regPath" /v "NoFolderOptions" /t REG_DWORD /d 1 /f | Out-Null

        # Disable Task Manager
        $systemPolicyPath = "HKEY_USERS\$userSid\Software\Microsoft\Windows\CurrentVersion\Policies\System"
        reg add "$systemPolicyPath" /v "DisableTaskMgr" /t REG_DWORD /d 1 /f | Out-Null

        # Disable Explorer bar (navigation pane)
        $sizerPath = "HKEY_USERS\$userSid\Software\Microsoft\Windows\CurrentVersion\Explorer\Modules\GlobalSettings\Sizer"
        reg add "$sizerPath" /f | Out-Null
        reg add "$sizerPath" /v "PageSpaceControlSizer" /t REG_BINARY /d 0000000000000000 /f | Out-Null
        Write-Host "Explorer bar disabled for user SID: $userSid."

        Write-Host "Restrictions applied for user SID: $userSid."
    } catch {
        Write-Host "Error applying restrictions for user SID: $userSid. $_"
    }
}

# Function to create a Downloads folder shortcut on the desktop
function Create-DownloadsShortcut {
    param (
        [string]$userProfilePath
    )

    try {
        # Paths for the Downloads folder and Desktop
        $downloadsPath = Join-Path -Path $userProfilePath -ChildPath "Downloads"
        $desktopPath = Join-Path -Path $userProfilePath -ChildPath "Desktop"
        $shortcutPath = Join-Path -Path $desktopPath -ChildPath "Downloads.lnk"

        # Check if the Downloads folder exists
        if (Test-Path $downloadsPath) {
            # Create a Shell COM object to create the shortcut
            $WshShell = New-Object -ComObject WScript.Shell
            $shortcut = $WshShell.CreateShortcut($shortcutPath)

            # Set the target of the shortcut to the Downloads folder
            $shortcut.TargetPath = $downloadsPath

            # Optionally, set an icon for the shortcut
            $shortcut.IconLocation = "shell32.dll, 3"  # Folder icon

            # Save the shortcut
            $shortcut.Save()

            Write-Host "Downloads shortcut created for user at '$desktopPath'."
        } else {
            Write-Host "Downloads folder not found for user at '$downloadsPath'."
        }
    } catch {
        Write-Host "Error creating Downloads shortcut for user profile: $userProfilePath. $_"
    }
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

        # Load the user's registry hive
        Load-UserRegistryHive -userProfilePath $userDir.FullName -sid $userSid

        # Apply restrictions
        Apply-UserRestrictions -userSid $userSid

        # Create the Downloads shortcut
        Create-DownloadsShortcut -userProfilePath $userDir.FullName

        # Unload the user's registry hive
        Unload-UserRegistryHive -sid $userSid
    } catch {
        Write-Host "Error processing user: $($userDir.Name). $_"
    }
}
