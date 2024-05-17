#Requires -Version 3.0

[CmdletBinding()]
Param(
    [Parameter(Mandatory=$false)]
	[string] $ResourceGroupLocation = 'UK South',
    [Parameter(Mandatory=$false)]
    [string] $TemplateFile = 'subnet.json',
	[Parameter(Mandatory=$false)]
    [string] $TemplateParametersFile = 'subnet-Web-Linux.parameters.json',
	[Parameter(Mandatory=$false)]
    [string] $subscription = '695132ff-350b-4751-bb31-cd23cf410c6e',
    [Parameter(Mandatory=$false)]
    [switch] $ValidateOnly
)

try {
    [Microsoft.Azure.Common.Authentication.AzureSession]::ClientFactory.AddUserAgent("VSAzureTools-$UI$($host.name)".replace(' ','_'), '3.0.0')
} catch { }

Clear-Host

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 3

function Format-ValidationOutput {
    param ($ValidationOutput, [int] $Depth = 0)
    Set-StrictMode -Off
    return @($ValidationOutput | Where-Object { $_ -ne $null } | ForEach-Object { @('  ' * $Depth + ': ' + $_.Message) + @(Format-ValidationOutput @($_.Details) ($Depth + 1)) })
}

$ResourceGroupName = Split-Path $PSScriptRoot -Leaf
$TemplateFile = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, "$TemplateFile"))
$TemplateParametersFile = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, $TemplateParametersFile))


if ((Get-AzContext).Subscription.id -eq $subscription)
{
    Write-Host "You are deploying to the destiantion Resource Group: [$ResourceGroupName]. `nPress any key to continue..." -ForegroundColor Magenta 
    $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null
    
    # Create or update the resource group using the specified template file and template parameters file
    New-AzResourceGroup -Name $ResourceGroupName -Location $ResourceGroupLocation -Verbose -Force
}
else 
{
    Write-Warning "Current subscription parameter subscription don't much."
    break;
}

if ($ValidateOnly) {
    $ErrorMessages = Format-ValidationOutput (Test-AzResourceGroupDeployment -TemplateFile $TemplateFile `
                                                                                  -TemplateParameterFile $TemplateParametersFile `
																				  -ResourceGroupName $ResourceGroupName `
																				  )
    if ($ErrorMessages) {
        Write-Output '', 'Validation returned the following errors:', @($ErrorMessages), '', 'Template is invalid.'
    }
    else {
        Write-Output '', 'Template is valid.'
    }
}

else {
    New-AzResourceGroupDeployment -Name ((Get-ChildItem $TemplateFile).BaseName + '-' + ((Get-Date).ToUniversalTime()).ToString('MMdd-HHmm')) `
                                       -TemplateFile $TemplateFile `
                                       -TemplateParameterFile $TemplateParametersFile `
                                       -ResourceGroupName $ResourceGroupName `
									   -Force -Verbose `
                                       -ErrorVariable ErrorMessages
    if ($ErrorMessages) {
        Write-Output '', 'Template deployment returned the following errors:', @(@($ErrorMessages) | ForEach-Object { $_.Exception.Message.TrimEnd("`r`n") })
    }
}