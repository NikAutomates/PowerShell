.$PSScriptRoot\Get-GraphAccessToken.ps1
.$PSScriptRoot\Send-GraphEmail.ps1
.$PSScriptRoot\Update-ClientSecrets.ps1
.$PSScriptRoot\Get-KeyVaultSecret.ps1
.$PSScriptRoot\Invoke-GraphAPIRequest.ps1
.$PSScriptRoot\Set-KeyVaultSecret.ps1
.$PSScriptRoot\Connect-Azure.ps1

Function Show-AvailableCommands {
    $ShowAvailableCommands = [System.Collections.ArrayList]::new()    
        $global:Module = "AzureSecrets"
        Get-Command -Module $Module | Where-Object {$_.Name -Ne "Show-AvailableCommands"} | ForEach-Object {
           [void]$ShowAvailableCommands.Add([PSCustomObject]@{
                Command = $_.Name | Sort-Object Command
                Type    = $_.CommandType | Sort-Object CommandType
                Module  = $_.Source
            })
        } 
        Write-Host "$($ShowAvailableCommands | Format-Table -AutoSize | Out-String)" -ForegroundColor Yellow
    }
    