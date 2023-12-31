function Get-GraphAccessToken {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [switch]$UseMSI
    )

    if ($UseMSI) {
        Try {
            [void](Connect-AzAccount -Identity)
            $ResourceURL = "https://graph.microsoft.com"
            $global:BearerToken = [string](Get-AzAccessToken -ResourceUrl $ResourceURL).Token 
            return $global:BearerToken      
        }
        Catch {
            Write-Warning $Error.Exception[0]
        }
    }
    Else {
        Try {
            If (Get-Command -Name Connect-AzAccount) {
                 [void](Connect-AzAccount)
                 $ResourceURL = "https://graph.microsoft.com"
                 $global:BearerToken = [string](Get-AzAccessToken -ResourceUrl $ResourceURL).Token
                 return $global:BearerToken    
            }
        }
        Catch {
            Write-Warning $Error.Exception[0]
        }
    }
}

    