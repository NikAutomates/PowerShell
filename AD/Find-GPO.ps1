<#
.SCRIPT 
  Find-GPO.ps1

.SYNOPSIS
  This script is used to find GPO's from Keywords

.DESCRIPTION
  Script will examine XML files from every Linked GPO & Match it to your custom keyword that is followed by the -GPOSetting Parameter

.NOTES
  Version:        1.0
  Author:         Nik Chikersal
  Creation Date:  04/08/2022
#>
Function Find-GPO
{

Param
(
[Parameter(Mandatory = $true)]
[String]$GPOSetting

)              

$GPOs = Get-GPO -All | Sort-Object displayname | Where-Object { If ( $_ | Get-GPOReport -ReportType XML | Select-String -AllMatches "<LinksTo>" | Select-String -AllMatches "<Enabled>true</Enabled>" ) {$_.DisplayName } }
Write-Host "Checking" $GPOs.Count "GPOs..Please wait" -ForegroundColor Cyan

$GPODisplayName = @()
$1 = 1
$GPOsCount = $GPOs.Count
foreach ($GPO In $GPOs)  {
$XML = Get-GPOReport -name $GPO.DisplayName -ReportType XML    

if ($XML -match $GPOSetting)
{
     $GPODisplayName += $GPO.DisplayName 

}
else
{

}                       

Write-Host "Parsing XML from GPO $1 of $($GPOs.count)" -ForegroundColor Blue
$1++
}


Start-Sleep -Seconds 3

$XMLs = Get-GPOReport -All -ReportType Xml
Clear-Host

if ($XMLs -match $GPOSetting) {
Write-Host "LINKED" -F Yellow -nonewline; Write-Host " GPOs that contain your Keyword ----> " -F Green -NoNewline; Write-Host " $GPOSetting" -F Cyan
Write-Host " "
Write-Host " "
$GPODisplayName
Write-Host " "
Write-Host " "
                         }
                         Else
                         {

Write-Warning "GPOSetting $GPOSetting could not be matched to any XML from GPOs"

                       }
                       }