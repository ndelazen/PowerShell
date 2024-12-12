## Bulk Revoke Users - using MSOnline and MgGraph 

Connect-MSOLService
$users = Get-MSOLUser

Foreach {
Set-MSOLUserPassword -UserPrincipalName $users -ForceChangePassword:$true
Set-MSOLUser -UserPrincipalName $users -StrongPasswordRequired:$true
}

# Install necessary modules
Install-Module Microsoft.Graph.Authentication -Force -AllowClobber
Install-Module Microsoft.Graph.Users -Force -AllowClobber

# Connect to Microsoft Graph
Connect-MgGraph -Scopes "User.ReadWrite.All", "Group.ReadWrite.All"
 
# Load external users from a CSV file
$externalUsers = Import-Csv -Path "c:\scripts\users.csv" # Assuming the CSV contains a column 'UserPrincipalName'
 
# Prepare an array to store the results
$results = @()
 
# Iterate through each user
foreach ($user in $externalUsers) {
    $userPrincipalName = $user.UserPrincipalName
    try {
        # Get the user object from Microsoft Graph
        $azureADUser = Get-MgUser -Filter "UserPrincipalName eq '$userPrincipalName'"
        if ($azureADUser) {
            # Revoke sign-in sessions
            Revoke-MgUserSignInSession -UserId $azureADUser.Id
            $results += [pscustomobject]@{
                UserPrincipalName = $userPrincipalName
                Status = "Revoked"
            }
        } else {
            $results += [pscustomobject]@{
                UserPrincipalName = $userPrincipalName
                Status = "Not Found"
            }
        }
    } catch {
        $results += [pscustomobject]@{
            UserPrincipalName = $userPrincipalName
            Status = "Error: $($_.Exception.Message)"
        }
    }
}
 
# Export results to a CSV file
$results | Export-Csv -Path "c:\temp\RevokeResults.csv" -NoTypeInformation -Force
 
# Clean up
Disconnect-MgGraph
 
Write-Host "Process completed. Results saved to c:\scripts\RevokeResults.csv"
