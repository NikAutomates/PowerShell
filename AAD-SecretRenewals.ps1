<#
.SYNOPSIS
    Secret-Renewals.ps1
    Automatically Renew oAuth & API App Reg Secrets that will expire soon

.DESCRIPTION
    This Script is intended to be used in an Azure Automation Runbook.
    Ensure to use a PowerShell 7.2 Runbook and Encrypt the Client Secret

    A Combination of REST API and the Graph SDK is used. 
    This is to ensure the original App Reg will not break or hault REST API

.NOTES
    Version: V.1.0.0
    Date Written: 08/27/2023
    Written By: Nik Chikersal
    CopyRight: Nik Chikersal

    Change Log:
    N/A
#>

Connect-MgGraph -Identity -NoWelcome | Out-Null

$clientid = "Private"
$Secret = Get-AutomationVariable -Name 'ClientSecret-Graph-Automation'
$TenantName = 'SomethingDomain.com'

$Body = @{
    Grant_Type    = "client_credentials"
    Scope         = "https://graph.microsoft.com/.default"
    client_Id     = $clientID
    Client_Secret = $Secret
}

$TokenArgs = @{
       Uri    = "https://login.microsoftonline.com/$TenantName/oauth2/v2.0/token" 
       Method = 'POST'
       Body   = $Body
}

$BearerToken = (Invoke-RestMethod @TokenArgs).access_token

$AppSplatArgs = @{
    Headers =  @{Authorization = "Bearer $($BearerToken)"}
    Uri     =  'https://graph.microsoft.com/v1.0/applications'
    Method  =  'GET'
}

$Results = [System.Collections.ArrayList]@()

$Date     = Get-Date
$Tomorrow = $Date.AddDays(1).ToString().Split(" ")[0]
$Today    = $Date.ToString().Split(" ")[0]
$Time     = Get-Date -Format hh:mm

(Invoke-RestMethod @AppSplatArgs).Value | 
    Where-Object {$_.PasswordCredentials.Enddatetime.count -gt "0"} | ForEach-Object {
      $AppReg = $_
      $AppReg.PasswordCredentials.Enddatetime | 
        ForEach-Object { $_.ToString("M/dd/yyy") | 
          ForEach-Object {
           $SecretExpiryDate = $_

           $AppOwnerSplatArgs = @{
            Headers =  @{Authorization = "Bearer $($BearerToken)"}
            Uri     =  "https://graph.microsoft.com/v1.0/applications/$($AppReg.ID)/Owners"
            Method  =  'GET'
        }
        
        (Invoke-RestMethod @AppownerSplatArgs).Value | ForEach-Object {

            $AppRegOwnerSMTP = $_
       
        $CustomObject = [PSCustomObject]@{
            AppName          = $AppReg.DisplayName
            SecretName       = $AppReg.PasswordCredentials.DisplayName
            SecretExpiryDate = $SecretExpiryDate
            SecretKeyID      = $AppReg.PasswordCredentials.KeyID
            AppID            = $AppReg.ID
            AppOwner        = $AppRegOwnerSMTP.mail
        }
       [void]$Results.Add($CustomObject)
      }
    }
  }
}
      $ExpiringSecrets = [System.Collections.ArrayList]@()

      $Results | Where-Object {$_.SecretExpiryDate.Equals($Tomorrow)} | ForEach-Object {
      $Expiring = $_

         $Object = [PSCustomObject][Ordered]@{
             AppName          = $Expiring.AppName 
             SecretName       = $Expiring.SecretName 
             SecretExpiryDate = $Expiring.SecretExpiryDate
             SecretKeyID      = $Expiring.SecretKeyID 
             AppID            = $Expiring.AppID
             AppOwner         = $Expiring.AppOwner
         }
        $ExpiringSecrets.Add($Object)
      }
      
      If ($ExpiringSecrets -ne $null) {
        Write-Output "The following Secrets are expiring soon:"
        $ExpiringSecrets | Format-Table -AutoSize
       }
        Else { 
         Write-Warning "There are no App Registrations with Secrets close to Expiry"
       }
        
$ExpiringSecrets | ForEach-Object {
    $SecretToRemove = $_
    [Array]$SecretToRemove.SecretKeyID | ForEach-Object {
        $SecretKeyID = $_    

        $RemoveSecretParams = @{
            KeyId = $SecretKeyID
        }

        Try {
            Write-Output "Removing Secret: $SecretKeyID from $($SecretToRemove.AppName)"
            Start-Sleep -Seconds 10

          $SecretRemovalArgs = @{
                ApplicationId = $SecretToRemove.AppID
                BodyParameter = $RemoveSecretParams
                ErrorAction   = 'STOP'
            }
            Remove-MgApplicationPassword @SecretRemovalArgs 
        } 
        Catch {
            Write-Output "Failed to remove secret $($Error[0].Exception.Message)"
        }
    }
}
$RenewedSecretsResultsArray = [System.Collections.ArrayList]@()

$ExpiringSecrets | ForEach-Object {
    $SecretToRenew = $_
    $SecretToRenew.SecretName | ForEach-Object {
    $SecretName = $_
    
$TrimmedOldSecret = [System.Text.RegularExpressions.Regex]::Replace($SecretName, ": Renewed.*", "")

  $RenewSecretParams = @{
      passwordCredential = @{
          DisplayName = "$($TrimmedOldSecret): Renewed $Today - $Time"
          EndDateTime = (Get-Date).AddMonths(3)
      }
  }

   Try {
     $SecretRenewalArgs = @{
         ApplicationId = $SecretToRenew.AppID
         BodyParameter = $RenewSecretParams
      }
      Start-Sleep -Seconds 14
      Write-Output "Renewing Secrets for $($Expiring.AppName): $($Expiring.AppID)"
      $Result = Add-MgApplicationPassword @SecretRenewalArgs
      $RenewedSecretsResultsArray += $Result
    }
    Catch {
        Write-Output "There was an Error renewing the Secret for $($Expiring.AppName)"
           [PSCustomObject][Ordered]@{
            Failure           = $Error.Exception.Message
            AdditionalDetails = $Error.FullyQualifiedErrorId
            ErrorID           = $Error.Errors
            $ErrorDetails     = $Error.ErrorDetails
           }
        }
    }
}

    Try {
      Connect-AzAccount -Identity -Subscription 'AH-Prod' | Out-Null
      $RenewedSecretsResultsArray | ForEach-Object {
      $KeyVaultSecret = $_
      
      $SecretNamePrefix      = $KeyVaultSecret.DisplayName.Split(" ").Replace(" ", "").Replace(":", "")[0]
      $SecretType            = "-" + $KeyVaultSecret.DisplayName.Replace(":", "").Split(" ")[1]
      $ConstructedSecretName = $SecretToRenew.AppName + "-" + $SecretNamePrefix + $SecretType
      $EncryptedSecret = ConvertTo-SecureString -String $KeyVaultSecret.SecretText -AsPlainText -Force
    
      $KeyVaultArgs = @{
          VaultName   = 'AH-SecretRenewal'
          Name        = $ConstructedSecretName
          SecretValue = $EncryptedSecret
      }
        Set-AzKeyVaultSecret @KeyVaultArgs | ForEach-Object {

        Write-Output ""
        Write-Output ""
        Write-Output "Creating Secret $($_.Name) in $($KeyVaultArgs.VaultName)"
        }
    }
}   Catch {
        Write-Output "There was an Error renewing the Secret for $($Expiring.AppName)"
           [PSCustomObject][Ordered]@{
             Failure           = $Error.Exception.Message
             AdditionalDetails = $Error.FullyQualifiedErrorId
             ErrorID           = $Error.Errors
             $ErrorDetails     = $Error.ErrorDetails
           }
           $TeamsError = $Expiring.AppName | Out-String 
           
           $JsonBody = [PSCustomObject][Ordered]@{
            "@type"      = "MessageCard"
            "@context"   = "http://schema.org/extensions"
            "summary"    = "One or More Application Registrations have failed to Renew Secrets"
            "themeColor" = "0078D7"
            "title"      = "One or More Application Registrations have failed to Renew Secrets"
            "text"       = "Application Registration Failed to Renew One or More Secrets: 
            App Reg Name: $($TeamsError)"
           }

           $TeamMessageBody = ConvertTo-Json $JsonBody -Depth 100
           $WebhookArgs = @{
             "URI"         = Get-AutomationVariable -Name 'Teams-WebHook-AD'
             "Method"      = 'POST'
             "Body"        = $TeamMessageBody
             "ContentType" = 'application/json'
        }
      Invoke-RestMethod @WebhookArgs -ErrorAction SilentlyContinue
    }
      
      if ($ExpiringSecrets -ne $null) {
      $EmailOutput = $ExpiringSecrets | 
                     Select-Object AppName, SecretExpiryDate, 
                     @{N='Secrets'; E={($_.SecretName -join ', ')} } | 
                     ConvertTo-Html -Fragment | 
                     Out-String -Width 10

     $Headers = @{
        "Authorization" = "Bearer $BearerToken"
        "Content-type"  = "application/json"
     }

     $ExpiringSecrets | 
     Where-Object {$_.AppOwner -ne $null} | ForEach-Object { 
     $AppOwnerPrimarySMTP = $_.AppOwner
     $MailboxSender       = "OneID@apex4health.com"
     $Subject             =  "Alert: One or More App Registration Secrets are Expiring" 
 
    
$URLsend = "https://graph.microsoft.com/v1.0/users/$MailBoxSender/sendMail"
$JsonBodyEmail = @"
{
  "message": {
    "subject": "$subject",
    "body": {
      "contentType": "HTML",
      "content": "The following App Registration Secrets will expire in under 24 hours <br>
      <br>
      <br> Warning: The below App Registration Secrets will be Renewed within 60 Seconds: <br>
      $Emailoutput <br>

      <br>
      <br>
      THIS IS AN AUTOMATED MESSAGE, DO NOT REPLY DIRECTLY TO THIS MESSAGE AS IT IS SENT FROM AN UNMONITORED MAILBOX <br>
     
      "
    },
    "toRecipients": [
      {
        "emailAddress": {
          "address": "$AppOwnerPrimarySMTP"
        }
      }
    ]
  },
  "saveToSentItems": "false"
}
"@

     $EmailSendArgs = @{
            Method  = 'POST'
            Uri     = $URLsend
            Headers = $headers
            Body    = $JsonBodyEmail
        }
        Invoke-RestMethod @EmailSendArgs
    }
}
