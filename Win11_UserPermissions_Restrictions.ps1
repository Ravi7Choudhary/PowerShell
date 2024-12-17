# Author - Ravi Choudhary(ravi7cchoudhary@gmail.com)
# Github - https://github.com/Ravi7Choudhary/PowerShell
<# Purpose - This Script will lock and restrict users to access all the drives using user permissions.
All users other then All Users|Default|Public|Default User|Administrator|administrator-sts#>

# Introduction to the script

Write-Host "*************************************************************" -ForegroundColor Green
Write-Host "            Imply User Restrictions Windows 11               " -ForegroundColor Green
Write-Host "*************************************************************" -ForegroundColor Green
Write-Host "This script denies access to all drives for non-admin users" -ForegroundColor Green
Write-Host "while granting them full access to their respective folders" -ForegroundColor Green
Write-Host "under C:\Users. It ensures that the administrator-sts account" -ForegroundColor Green
Write-Host "remains unaffected." -ForegroundColor Green
Read-Host "Press Enter to continue"

# Run as Administrator for proper permissions
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "This script must be run as Administrator. Exiting..."
    exit
}

# Excluded accounts
$excludedUsers = @("administrator-sts", "administrator", "Public", "Default", "Default User", "All Users")

# Get all user profiles from C:\Users
$userProfiles = Get-ChildItem "C:\Users" -Directory -ErrorAction SilentlyContinue | 
    Where-Object { $_.Name -notin $excludedUsers }

if (-not $userProfiles) {
    Write-Error "No user profiles found to process. Exiting..."
    exit
}

# Loop through each user profile
foreach ($profile in $userProfiles) {
    $userName = $profile.Name
    $userFolderPath = "C:\Users\$userName"

    Write-Output "`nProcessing restrictions for user: $userName"

    # Deny access to ALL drives except their user folder
    Get-PSDrive -PSProvider FileSystem | ForEach-Object {
        $drive = $_.Root

        # Ensure the user's home folder exists
        if ($drive -eq "C:\" -and -not (Test-Path $userFolderPath)) {
            Write-Warning "User folder not found for $userName. Skipping..."
            return
        }

        Write-Output "Applying deny rule on drive: $drive for user: $userName"

        try {
            # Get current ACL of the drive
            $acl = Get-Acl $drive

            # Create a Deny rule for Modify permission
            $denyRule = New-Object System.Security.AccessControl.FileSystemAccessRule($userName, "Modify", "ContainerInherit,ObjectInherit", "None", "Deny")

            # Add the Deny rule
            $acl.AddAccessRule($denyRule)
            Set-Acl -Path $drive -AclObject $acl

            Write-Output "Deny permissions applied to $drive for user: $userName"

            # Restore permissions to the user's home folder
            if ($drive -eq "C:\") {
                Write-Output "Restoring access to user folder: $userFolderPath"
                $userAcl = Get-Acl $userFolderPath

                # Remove any existing Deny rule for the user
                $userAcl.Access | Where-Object { $_.IdentityReference -eq $userName -and $_.AccessControlType -eq "Deny" } | ForEach-Object {
                    $userAcl.RemoveAccessRule($_)
                }

                # Add Full Control rule for the user
                $allowRule = New-Object System.Security.AccessControl.FileSystemAccessRule($userName, "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
                $userAcl.AddAccessRule($allowRule)
                Set-Acl -Path $userFolderPath -AclObject $userAcl

                Write-Output "Full access restored to $userFolderPath for user: $userName"
            }
        }
        catch {
            Write-Error "Failed to set permissions on $drive for user: $userName. Error: $_"
        }
    }
}

Write-Output "`nPermissions successfully updated for all users except administrator-sts."
