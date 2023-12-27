<#
.SYNOPSIS
    This script is an assortment of functions to ease EOL tasks

.DESCRIPTION
    The EOL module will automatically Install pre-functions
    If the EOL Module exists, individual functions can be executed

.NOTES
    Version: V.1.0.0
    Date Written: 6/5/2023
    Written By: Nik Chikersal

    Change Log:
    N/A
#>

#Check if the Graph SDK module is installed and install it if required

Function Install-EOLModule {


    $Module = Get-InstalledModule -Name "ExchangeOnlineManagement" -ErrorAction SilentlyContinue
    $ModulePath = 'C:\Program Files\WindowsPowerShell\Modules\ExchangeOnlineManagement'
    
    If (!($Module)) {
    
        Write-Host "Installing Module: Exchange Online Management" -ForegroundColor Cyan
        Install-Module -Name ExchangeOnlineManagement -Force -AllowClobber 
    
        If (Test-Path -Path $ModulePath) { 
            Write-Host "Module: Exchange Online Management Installed Successfully" -ForegroundColor Green
        }
        Else{
             Write-Warning "There was an error Installing the Module"
    
               [PSCustomObject][Ordered]@{
                  Error   = $Error.Exception[0].ToString().TrimStart("System.ArgumentException:")
                  Failure = $Error.Exception.Failure
                }
            }
        }
    }
    
     Install-EOLModule
    
    Function Delegate-MB {
        
        [CmdletBinding()]
        Param (
        
            [Parameter(Mandatory = $true)]
            [String]$MailBox,
            [Parameter(Mandatory = $true)]
            [String]$User,
            [Parameter(Mandatory = $true)]
            [String]$PermissionLevel #FullAccess, ReadPermission
        )
    
    If (Test-Path -Path 'C:\Program Files\WindowsPowerShell\Modules\ExchangeOnlineManagement') {
       Connect-ExchangeOnline
    
       try {
        
        Add-MailboxPermission -Identity $MailBox -User $User -AccessRights $PermissionLevel
    }
    Catch {
    
        Write-Warning "There was an error delegating Permissions"
        [PSCustomObject]@{
            Error   = $Error.Exception[0]
            Failure = $Error.Exception.Failure
    
    } 
      } 
        }
          }
    
    Function Set-MBForwarding {
    
    [CmdletBinding()]
    Param (
        
            [Parameter(Mandatory = $true)]
            [String]$SourceMailbox,
            [Parameter(Mandatory = $true)]
            [String]$DestinationMailbox,
            [Parameter(Mandatory = $true)]
            [Bool]$DeliverToMailAndForward
         )
    
        If (Test-Path -Path 'C:\Program Files\WindowsPowerShell\Modules\ExchangeOnlineManagement') {
        Connect-ExchangeOnline
    
        $ForwardingArgs = @{
    
        Identity                   = $SourceMailbox
        ForwardingSMTPAddress      = $DestinationMailbox
        DeliverToMailboxAndForward = $DeliverToMailAndForward
    
        }
    
        Set-Mailbox @ForwardingArgs 
        
        Get-Mailbox -Identity $SourceMailbox |
        Select-Object @{N='SourceMB'; E={$SourceMailbox}}, 
        ForwardingSMTPAddress, DeliverToMailboxAndForward
    
     } 
       }
    
    Function Remove-MBForwarding {
    
    [CmdletBinding()]
    Param (
    
            [Parameter(Mandatory = $true)]
            [String]$Mailbox
        )
    
         If (Test-Path -Path 'C:\Program Files\WindowsPowerShell\Modules\ExchangeOnlineManagement') {
        Connect-ExchangeOnline
        Set-Mailbox -Identity $Mailbox -ForwardingAddress $null -ForwardingSmtpAddress $null -DeliverToMailboxAndForward $false
    
        Get-Mailbox -Identity $Mailbox | 
        Select-Object @{N='ForwardingAddress'; E={If ($_.ForwardingAddress -eq $null) {"NotSet"}}}, 
        @{N='ForwardingSMTPAddress'; E={If ($_.ForwardingSMTPAddress -eq $null) {"NotSet"}}}, DeliverToMailBoxAndForward
    
    
       }
         }
    
    Function Trace-InboundMBMessages {
    
    [CmdletBinding()]
    Param (
        
            [Parameter(Mandatory = $True)]
            [String]$Recipient,
            [Parameter(Mandatory = $True)]
            [INT]$Days #Maximum of 10 days old
        )
    
        If (Test-Path -Path 'C:\Program Files\WindowsPowerShell\Modules\ExchangeOnlineManagement') {
        Connect-ExchangeOnline
    
        $Today = (Get-Date).ToString().Split(" ")[0]
        $StartDate  = (Get-Date).AddDays(-$($Days)).ToString().Split(" ")[0]
    
        Get-MessageTrace -RecipientAddress $Recipient -StartDate $StartDate -EndDate $Today
    }
      }
    Function Trace-OutboundMBMessages {
    
    [CmdletBinding()]
    Param (
        
            [Parameter(Mandatory = $True)]
            [String]$Sender,
            [Parameter(Mandatory = $True)]
            [INT]$Days #Maximum of 10 days old
        )
    
        If (Test-Path -Path 'C:\Program Files\WindowsPowerShell\Modules\ExchangeOnlineManagement') {
        Connect-ExchangeOnline
    
        $Today = (Get-Date).ToString().Split(" ")[0]
        $StartDate  = (Get-Date).AddDays(-$($Days)).ToString().Split(" ")[0]
    
        Get-MessageTrace -SenderAddress $Sender -StartDate $StartDate -EndDate $Today
    }
      }
    Function Trace-BiDirectionalMBMessages {
    
    [CmdletBinding()]
    Param (
        
            [Parameter(Mandatory = $True)]
            [String]$Recipient,
            [Parameter(Mandatory = $True)]
            [String]$Sender,
            [Parameter(Mandatory = $True)]
            [INT]$Days #Maximum of 10 days old
        )
    
        If (Test-Path -Path 'C:\Program Files\WindowsPowerShell\Modules\ExchangeOnlineManagement') {
        Connect-ExchangeOnline
    
        $Today = (Get-Date).ToString().Split(" ")[0]
        $StartDate  = (Get-Date).AddDays(-$($Days)).ToString().Split(" ")[0]

        Get-MessageTrace -RecipientAddress $Recipient -SenderAddress $Sender -StartDate $StartDate -EndDate $Today
    
       
    }
      }

      Function Convert-MBToShared { 

        [CmdletBinding()]
    Param (
        
            [ValidateNotNullOrEmpty()]
            [Parameter(Mandatory = $True)]
            [String]$Mailbox 
            
          )
          
          If (Test-Path -Path 'C:\Program Files\WindowsPowerShell\Modules\ExchangeOnlineManagement') {
            Connect-ExchangeOnline

      Try {
        
          Set-Mailbox -Identity $Mailbox -Type Shared

          If (Get-Mailbox -Identity $Mailbox |  
          Where-Object {$_.RecipientTypeDetails -eq "SharedMailbox"}) {

          Write-Host "" 
          Exit 1
        }
            While (Get-Mailbox -Identity $Mailbox |  
            Where-Object {$_.RecipientTypeDetails -ne "SharedMailbox"}) {
            Start-Sleep -Seconds 5
            Write-Host "Converting $($Mailbox) to Type Shared in EOL" -ForegroundColor Cyan
      }
          If (Get-Mailbox -Identity $Mailbox |  
            Where-Object {$_.RecipientTypeDetails -eq "SharedMailbox"}) {
            Write-Host "Mailbox: $($Mailbox) Converted to Shared" -ForegroundColor Green
            
           }
        }
        Catch {
                Write-Warning "There was an error converting the Mailbox to Shared"

                   [PSCustomObject][Ordered]@{
                    Error   = $Error.Exception[0]
                    Failure = $Error.Failure
                    Message = $Error.Exception.Message[0]
                }
            }
        }
    }
    

Export-ModuleMember -Function 'Delegate-MB', 'Set-MBForwarding', 'Remove-MBForwarding', 'Trace-InboundMBMessages', 'Trace-outboundMBMessages', 'Trace-BiDirectionalMBMessages', 'Convert-MBToShared'
