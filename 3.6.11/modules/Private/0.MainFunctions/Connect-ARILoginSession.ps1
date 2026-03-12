<#
.Synopsis
Azure Login Session Module for Azure Resource Inventory

.DESCRIPTION
This module is used to invoke the authentication process that is handle by Azure PowerShell.

.Link
https://github.com/microsoft/ARI/Modules/Private/0.MainFunctions/Connect-LoginSession.ps1

.COMPONENT
This powershell Module is part of Azure Resource Inventory (ARI)

.NOTES
Version: 3.6.0
First Release Date: 15th Oct, 2024
Authors: Claudio Merola

#>
function Connect-ARILoginSession {
    Param($AzureEnvironment, $TenantID, $SubscriptionID, $DeviceLogin, $AppId, $Secret, $CertificatePath, $Debug)
    $DebugPreference = 'silentlycontinue'
    $ErrorActionPreference = 'Continue'

    Write-Debug ((get-date -Format 'yyyy-MM-dd_HH_mm_ss')+' - '+'Starting Connect-LoginSession function')
    Write-Host $AzureEnvironment -BackgroundColor Green
    $Context = Get-AzContext -ErrorAction SilentlyContinue
    if (!$TenantID) {
        Write-Debug ((get-date -Format 'yyyy-MM-dd_HH_mm_ss')+' - '+'Tenant ID not specified, prompting for Service Principal credentials')
        write-host "Starting Azure Resource Inventory Authentication" -ForegroundColor Cyan
        write-host "Please provide your Service Principal (App Registration) details:" -ForegroundColor Yellow
        write-host ""
        
        $AppId = Read-Host "Enter App ID"
        $Secret = Read-Host "Enter Secret Value" -AsSecureString
        $TenantID = Read-Host "Enter Tenant ID"
        $SubscriptionID = Read-Host "Enter Subscription ID (Optional, press Enter to skip)"

        write-host ""
        write-host "Authenticating Service Principal..." -ForegroundColor Cyan

        try {
            $Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $AppId, $Secret
            Connect-AzAccount -ServicePrincipal -TenantId $TenantId -Credential $Credential | Out-Null
        }
        catch {
            Write-Error "Authentication via Service Principal failed. Please check your credentials."
            throw $_
        }

        if ($SubscriptionID) {
            Set-AzContext -Subscription $SubscriptionID -ErrorAction SilentlyContinue | Out-Null
        }
    }
    else {
        Write-Debug ((get-date -Format 'yyyy-MM-dd_HH_mm_ss')+' - '+'Tenant ID was informed.')

        if($Context.Tenant.Id -ne $TenantID)
        {
            Set-AzContext -Tenant $TenantID -ErrorAction SilentlyContinue | Out-Null
            $Context = Get-AzContext -ErrorAction SilentlyContinue
        }
        $Subs = Get-AzSubscription -TenantId $TenantID -ErrorAction SilentlyContinue -WarningAction SilentlyContinue

        if($DeviceLogin.IsPresent)
            {
                Write-Debug ((get-date -Format 'yyyy-MM-dd_HH_mm_ss')+' - '+'Logging with Device Login')
                Connect-AzAccount -Tenant $TenantID -UseDeviceAuthentication -Environment $AzureEnvironment | Out-Null
            }
        elseif($AppId -and $Secret -and $CertificatePath -and $TenantID)
            {
                Write-Debug ((get-date -Format 'yyyy-MM-dd_HH_mm_ss')+' - '+'Logging with AppID and CertificatePath')
                $SecurePassword = ConvertTo-SecureString -String $Secret -AsPlainText -Force
                Connect-AzAccount -ServicePrincipal -TenantId $TenantId -ApplicationId $AppId -CertificatePath $CertificatePath -CertificatePassword $SecurePassword | Out-Null
            }            
        elseif($AppId -and $Secret -and $TenantID)
            {
                Write-Debug ((get-date -Format 'yyyy-MM-dd_HH_mm_ss')+' - '+'Logging with AppID and Secret')
                $SecurePassword = ConvertTo-SecureString -String $Secret -AsPlainText -Force
                $Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $AppId, $SecurePassword
                Connect-AzAccount -ServicePrincipal -TenantId $TenantId -Credential $Credential | Out-Null
            }
        else
            {
                if([string]::IsNullOrEmpty($Subs))
                    {
                        try 
                            {
                                Write-Debug ((get-date -Format 'yyyy-MM-dd_HH_mm_ss')+' - '+'Editing Login Experience')
                                $AZConfig = Get-AzConfig -LoginExperienceV2 -WarningAction SilentlyContinue -InformationAction SilentlyContinue
                                if ($AZConfig.value -eq 'On')
                                    {
                                        Update-AzConfig -LoginExperienceV2 Off | Out-Null
                                        Connect-AzAccount -Tenant $TenantID -Environment $AzureEnvironment | Out-Null
                                        Update-AzConfig -LoginExperienceV2 On | Out-Null
                                    }
                                else
                                    {
                                        Connect-AzAccount -Tenant $TenantID -Environment $AzureEnvironment | Out-Null
                                    }
                            }
                        catch
                            {
                                Connect-AzAccount -Tenant $TenantID -Environment $AzureEnvironment | Out-Null
                            }
                    }
                else
                    {
                        Write-Host "Already authenticated in Tenant $TenantID"
                    }
            }
    }
    return $TenantID
}