
# Grant Read/Write access to Container 

function Get-Ri.StorageAccess {

    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [string] $scope,
        [Parameter(Mandatory=$true)]
        [string] $role,
        [Parameter(Mandatory=$true)]
        [string] $objectID
    )

    Process
    {
        # Get-AzRoleAssignment -Scope $scope
        $roleAssignements = Get-AzRoleAssignment -Scope $scope

        if(($roleAssignements.ObjectId -eq $objectID) -and ($roleAssignements.RoleDefinitionName -eq $role))
        {
            # Assignment exists
            $false
        }
        else 
        {
            # Assignment exists
            $true
        }
    }
} # End Get-Ri.StorageAccess

function New-RI.ContainerAccess {

    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [string] $servicePrincipalName , 
        
        [Parameter(Mandatory=$true)]
        [ValidateSet('Storage Blob Data Contributor','Storage Blob Data Reader')]
        [string] $role,

        [Parameter(Mandatory=$true)]
        [string] $resourceGroupName ,

        [Parameter(Mandatory=$true)]
        [string] $storageAccountName,

        [Parameter(Mandatory=$true)]
        [string] $containerName
    )

    Process
    {
        $ErrorActionPreference = 'Stop'

        $servicePrincipal =  Get-AzADServicePrincipal  -DisplayName $servicePrincipalName 
        $subscriptionID = Get-AzContext
        $scope = "/subscriptions/$($subscriptionID.Subscription.Id)/resourceGroups/$resourceGroupName/providers/Microsoft.Storage/storageAccounts/$storageAccountName/blobServices/default/containers/$containerName"
        

        # Check if the role is already assigned 
        if(Get-Ri.StorageAccess -scope $scope `
                                -role $role `
                                -objectID $servicePrincipal.AppId)
        {
            New-AzRoleAssignment -ApplicationId $servicePrincipal.AppId `
                                -RoleDefinitionName $role `
                                -Scope $scope
        }
        else 
        {
            Write-Output "Assignment: [$servicePrincipalName] for container [$storageAccountName]/[$containerName] already exists, skipping.."    
        }
    }
} # End New-RI.ContainerAccess

# Grant Write access to Queue 
function New-RI.QueueAccess {

    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [string] $servicePrincipalName , 
        
        [Parameter(Mandatory=$true)]
        [ValidateSet('Storage Queue Data Contributor')]
        [string] $role ,

        [Parameter(Mandatory=$true)]
        [string] $resourceGroupName ,

        [Parameter(Mandatory=$true)]
        [string] $storageAccountName,

        [Parameter(Mandatory=$true)]
        [string] $queueName
    )
    Process
    {
        $ErrorActionPreference = 'Stop'

        $servicePrincipal =  Get-AzADServicePrincipal -DisplayName $servicePrincipalName 
        $subscriptionID = Get-AzContext
        $scope = "/subscriptions/$($subscriptionID.Subscription.Id)/resourceGroups/$resourceGroupName/providers/Microsoft.Storage/storageAccounts/$storageAccountName/queueServices/default/queues/$queueName"
        
        # Check if the role is already assigned 
        if(Get-Ri.StorageAccess -scope $scope `
                                -role $role `
                                -objectID $servicePrincipal.AppId)
        {
            New-AzRoleAssignment -ApplicationId $servicePrincipal.AppId `
                                 -RoleDefinitionName $role `
                                 -Scope $scope
        }
        else 
        {
            Write-Output "Assignment: [$servicePrincipalName] for qeueue [$storageAccountName]/[$queueName] already exists, skipping.."    
        }
    }
} # End New-RI.QueueAccess


