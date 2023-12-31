 <#
.AUTHOR
    Nik Chikersal
.SYNOPSIS
    This function is used to make Graph REST API Requests to Microsoft Graph with automatic bearer token retrieval
.EXAMPLE
    Invoke-GraphAPIRequest -GraphResource 'groups' -UseMSI
    Invoke-GraphAPIRequest -GraphResource 'groups'
.NOTES
Validate set within function is being worked on to include entity sets, rather than just the ones listed below.
#>
function Invoke-GraphAPIRequest {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)][ValidateNotNullOrEmpty()]
        #Needswork to include entity sets [ValidateSet("directoryObjects", "invitations", "users", "activitystatistics", "applicationTemplates", "servicePrincipals", "authenticationMethodConfigurations", "bookingBusinesses", "bookingCurrencies", "devices", "identityProviders", "deviceLocalCredentials", "administrativeUnits", "allowedDataLocations", "applications", "appRoleAssignments", "certificateBasedAuthConfiguration", "contacts", "contracts", "directoryRoles", "directoryRoleTemplates", "directorySettingTemplates", "domainDnsRecords", "domains", "groups", "oauth2PermissionGrants", "organization", "permissionGrants", "scopedRoleMemberships", "settings", "subscribedSkus", "places", "drives", "shares", "sites", "messageEvents", "messageRecipients", "messageTraces", "schemaExtensions", "onPremisesPublishingProfiles", "groupLifecyclePolicies", "filterOperators", "functions", "accessReviewDecisions", "accessReviews", "approvalWorkflowProviders", "businessFlowTemplates", "programControls", "programControlTypes", "programs", "agreementAcceptances", "agreements", "riskDetections", "riskyUsers", "mobilityManagementPolicies", "governanceResources", "governanceRoleAssignmentRequests", "governanceRoleAssignments", "governanceRoleDefinitions", "governanceRoleSettings", "governanceSubjects", "privilegedAccess", "privilegedApproval", "privilegedOperationEvents", "privilegedRoleAssignmentRequests", "privilegedRoleAssignments", "privilegedRoles", "privilegedSignupStatus", "commands", "payloadResponse", "dataPolicyOperations", "subscriptions", "connections", "chats", "teams", "teamsTemplates", "teamTemplateDefinition", "identityGovernance", "auditLogs", "reports", "solutions", "authenticationMethodsPolicy", "identity", "deviceManagement", "roleManagement", "privacy", "security", "compliance", "trustFramework", "dataClassification", "informationProtection", "monitoring", "conditionalAccess", "directory", "me", "policies", "tenantRelationships", "admin", "education", "drive", "employeeExperience", "termStore", "communications", "identityProtection", "deviceAppManagement", "search", "financials", "planner", "print", "threatSubmission", "app", "external", "appCatalogs", "teamwork", "networkAccess")]
        [String]$GraphResource,
        [Parameter(Mandatory = $false)][ValidateNotNullOrEmpty()]
        [switch]$UseMSI  
    )

    If ([string]::IsNullOrEmpty($global:BearerToken)) {
       If ($UseMSI) {
         Try {
            $global:BearerToken = Get-GraphAccessToken -UseMSI
         }
         Catch {
            Write-Warning $Error.Exception.Message[0]
        } 
    }
    elseif (!$UseMSI) {
         Try {
            $global:BearerToken = Get-GraphAccessToken
         }
         Catch {
            Write-Warning $Error.Exception.Message[0]
          }
       }
    }
    $global:Results = [System.Collections.ArrayList]::new()
    [hashtable]$SplatArgs = @{
        Headers = @{Authorization = "Bearer $($global:BearerToken)"}
        Uri     = "https://graph.microsoft.com/Beta/$($GraphResource)" 
        Method  = 'GET'
   }
    Try {
         do {
            $GraphResponse = Invoke-RestMethod @SplatArgs 
            foreach ($Response in $GraphResponse.Value) {
                [void]$Results.Add($Response)
            }
            $SplatArgs.Uri = $GraphResponse."@odata.nextLink"
        } while ($SplatArgs.Uri)
           If (![string]::IsNullOrEmpty($Results)) {
            return $global:results
        }        
    }
    Catch {
        [PSCustomObject]@{
            Exception = $($Error.Exception.Message)[0]
        }
         If ($IsWindows) { 
          Start-Sleep -Seconds 3 ; [System.Diagnostics.Process]::Start("C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe","https://learn.microsoft.com/en-us/graph/permissions-reference")
          [PSCustomObject][Ordered]@{
            Error = $($Error.Exception.Message)[0]
            Msg   = "Please Visit: https://learn.microsoft.com/en-us/graph/permissions-reference"
        }
    }
    elseif ($IsMacOS -or $UseMSI) {
            Write-Output "Please Visit: https://learn.microsoft.com/en-us/graph/permissions-reference" 
        }
    }

[string]$PermissionsConsent = Read-Host "Would you like to consent to Graph Permissions? Type 'Y' to consent or 'N' to exit"
  Switch ($PermissionsConsent) {
      'Y' { $SetPermissions = Read-Host "Enter the permissions you would like to consent to. Example: 'User.Read, Group.ReadWrite.All'"
          If (![string]::IsNullOrEmpty($SetPermissions)) {
            Try {
                $ConsentCheck = Connect-MgGraph -Scopes $SetPermissions -ErrorAction STOP
                If (($ConsentCheck | Select-String -Pattern "Welcome to Microsoft Graph!")) {
                    Write-Host "Permissions have been consented successfully: $($SetPermissions)" -ForegroundColor Green
                }
            }
           Catch {
                If (($Error[0] | Select-String -Pattern "User declined to consent to access the app")) {
                Write-Warning "Permissions were not consented because the prompt was canceled or consent isn't allowed"
             }
             Elseif (($Error[0] | Select-String -Pattern "that doesn't exist on the resource" )) {
                Write-Warning "Permissions were not consented because the permissions you entered are not valid"
                Start-Sleep -Seconds 10; Exit 1
               }
               ElseIf (($Error[0] | Select-String -Pattern "that doesn't exist on the resource") -or ($Error[0] | 
                 Select-String -Pattern "User declined to consent to access the app" -NotMatch)) {
                 Write-Warning "$($SetPermissions): is not a valid permission. Please visit: https://docs.microsoft.com/en-us/graph/permissions-reference"
                 Start-Sleep -Seconds 10; Exit 1
               }
            }
        }
    }
    'N' { Write-Warning "Exiting..."}
    default {Write-Warning "Exiting..."}}
    $Error.Clear() }

   
  











 
