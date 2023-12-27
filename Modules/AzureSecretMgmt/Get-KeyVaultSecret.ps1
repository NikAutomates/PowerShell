<#
.AUTHOR
    Nik Chikersal
.SYNOPSIS
    This function is used to Download and Retrieve Secrets from Azure Keyvault
.EXAMPLE
    Set-DefaultKeyVault -VaultName 'MyAzureVaultName'
    This example shows how to set the default vault 

    Get-KeyvaultSecret -SecretName 'MySecret' -DownloadSecret
    This example shows how to download a secret from the default vault

    Get-KeyvaultSecret -SecretName 'MySecret' -KeyVaultName 'MyAzureVaultName'
    This example shows how to download a secret from a specified vault

    Get-KeyvaultSecret -SecretName 'MySecret' -KeyVaultName 'MyAzureVaultName' -DownloadSecret
    This example shows how to download a secret from a specified vault
#>
function Get-KeyVaultSecret {
    [CmdletBinding()]
    [Alias('Set-DefaultKeyVault')]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$SecretName,
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$KeyVaultName,
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$DefaultKeyVaultName,
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [switch]$DownloadSecret
    )
 
$MacXML = "/Users/$env:USER/Defaults.Xml"
$WindowsXML = "$env:USERPROFILE\Defaults.Xml"

    If ($DefaultKeyVaultName) { 
        If ($IsMacOS) {
            Out-File -InputObject $DefaultKeyVaultName -FilePath $MacXML -Force
            If (Test-Path $MacXML) {
               Write-Host "Default KeyVault has been set to $($DefaultKeyVaultName)" -ForegroundColor Green
            }
            Return
        }
        Elseif ($IsWindows) {
            Out-File -InputObject $DefaultKeyVaultName -FilePath $WindowsXML -Force
            if (Test-Path $WindowsXML) {
                Write-Host "Default KeyVault has been set to $($DefaultKeyVaultName)" -ForegroundColor Green
            }
            Return
         }
    }

If ((Test-Path -Path $WindowsXML -ErrorAction SilentlyContinue) -or (Test-Path -Path $MacXML -ErrorAction SilentlyContinue) -and [string]::IsNullOrEmpty($KeyVaultName)) { 
     Switch ($IsMacOS) {
        $true  { $KeyVaultName = (Get-Content -Path $MacXML) }
        $false { $KeyVaultName = (Get-Content -Path $WindowsXML) }
      }
    }
    Elseif (-not [string]::IsNullOrEmpty($KeyVaultName)) { $KeyVaultName = $KeyVaultName }

    If (([string]::IsNullOrEmpty($KeyVaultName))) {
        Write-Warning "No values were specified. Please specify a valid valult name or a set a default vault"
        Write-Output "To Set Default Vault: Get-KeyVaultSecret -SetDefaultKeyVault <VaultName>"
        Write-Output "To specifiy a Vault: Get-KeyVaultSecret -KeyVaultName <VaultName>"
        return
    }
    Elseif (-not (Get-AzKeyVault -VaultName $KeyVaultName)) {
        Write-Warning "KeyVault: $($KeyVaultName) was not found"
        Write-Output "To Set Default Vault: Get-KeyVaultSecret -SetDefaultKeyVault <VaultName>"
        Write-Output "To Specifiy a Vault: Get-KeyVaultSecret -KeyVaultName <VaultName>"
        return
    }
       $SecretResult = Get-AzKeyVaultSecret -VaultName $KeyVaultName -Name $SecretName -AsPlainText
          If ([string]::IsNullOrEmpty($SecretResult)) {
                Write-Warning "Secret $($SecretName) not found in $($KeyVaultName)"
                Start-Sleep -Seconds 3
                Try {
                    Get-AzKeyVaultSecret -VaultName $KeyVaultName | Select-Object @{N='ExistingSecrets'; E={$_.Name}}  
                }
                Catch {
                    Write-Warning "$($Error.Exception.Message)[0]"
                }
            }
            Elseif (-not ([string]::IsNullOrEmpty($SecretResult))) {
                    If ($DownloadSecret) {
                        Try {
                            Get-AzKeyVaultSecret -VaultName $KeyVaultName -Name $SecretName -AsPlainText | Out-File "$($SecretName).txt"
                            Write-Host "$($SecretName) has been downloaded to $(Get-Location)" -ForegroundColor Yellow
                        }
                        Catch {
                            Write-Warning "$($Error.Exception.Message)[0]"
                        }
                    }
                    Else 
                    {
                        Return $SecretResult
                       }
                    }
                }
         
