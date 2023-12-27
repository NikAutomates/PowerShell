function Get-GraphAccessToken {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [switch]$UseMSI
    )
    
    if ($UseMSI) {
        Connect-AzAccount -Identity | Out-Null
        $ResourceURL = "https://graph.microsoft.com"
        [string](Get-AzAccessToken -ResourceUrl $ResourceURL).Token 
    }
    Else {
        If (Get-Command -Name Connect-AzAccount) {
            Connect-AzAccount | Out-Null 
            $ResourceURL = "https://graph.microsoft.com"
            [string](Get-AzAccessToken -ResourceUrl $ResourceURL).Token
        }
    }
}