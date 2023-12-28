function Invoke-GraphAPIRequest {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)][ValidateNotNullOrEmpty()]
        [ValidateSet("directoryObjects", "invitations", "users", "activitystatistics", "applicationTemplates", "servicePrincipals", "authenticationMethodConfigurations", "bookingBusinesses", "bookingCurrencies", "devices", "identityProviders", "deviceLocalCredentials", "administrativeUnits", "allowedDataLocations", "applications", "appRoleAssignments", "certificateBasedAuthConfiguration", "contacts", "contracts", "directoryRoles", "directoryRoleTemplates", "directorySettingTemplates", "domainDnsRecords", "domains", "groups", "oauth2PermissionGrants", "organization", "permissionGrants", "scopedRoleMemberships", "settings", "subscribedSkus", "places", "drives", "shares", "sites", "messageEvents", "messageRecipients", "messageTraces", "schemaExtensions", "onPremisesPublishingProfiles", "groupLifecyclePolicies", "filterOperators", "functions", "accessReviewDecisions", "accessReviews", "approvalWorkflowProviders", "businessFlowTemplates", "programControls", "programControlTypes", "programs", "agreementAcceptances", "agreements", "riskDetections", "riskyUsers", "mobilityManagementPolicies", "governanceResources", "governanceRoleAssignmentRequests", "governanceRoleAssignments", "governanceRoleDefinitions", "governanceRoleSettings", "governanceSubjects", "privilegedAccess", "privilegedApproval", "privilegedOperationEvents", "privilegedRoleAssignmentRequests", "privilegedRoleAssignments", "privilegedRoles", "privilegedSignupStatus", "commands", "payloadResponse", "dataPolicyOperations", "subscriptions", "connections", "chats", "teams", "teamsTemplates", "teamTemplateDefinition", "identityGovernance", "auditLogs", "reports", "solutions", "authenticationMethodsPolicy", "identity", "deviceManagement", "roleManagement", "privacy", "security", "compliance", "trustFramework", "dataClassification", "informationProtection", "monitoring", "conditionalAccess", "directory", "me", "policies", "tenantRelationships", "admin", "education", "drive", "employeeExperience", "termStore", "communications", "identityProtection", "deviceAppManagement", "search", "financials", "planner", "print", "threatSubmission", "app", "external", "appCatalogs", "teamwork", "networkAccess")]
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
            Write-Warning $Error.Exception[0]
        } 
    }
    elseif (!$UseMSI) {
         Try {
            $global:BearerToken = Get-GraphAccessToken
         }
         Catch {
            Write-Warning $Error.Exception[0]
         }
       }
    }
    $SplatArgs = @{
        Headers = @{Authorization = "Bearer $($global:BearerToken)"}
        Uri     = "https://graph.microsoft.com/Beta/$($GraphResource)" 
        Method  = 'GET'
    } 
    Try {
        (Invoke-RestMethod @SplatArgs).Value     
    }
    Catch {
        [PSCustomObject]@{
            Reason = "Ensure you have the correct permissions on Scope: $($GraphResource)"
        }
         If (!$UseMSI) { Start-Sleep -Seconds 5 ; [System.Diagnostics.Process]::Start("C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe","https://learn.microsoft.com/en-us/graph/permissions-reference") } 
          Else { Write-Output "Please Visit: https://learn.microsoft.com/en-us/graph/permissions-reference" }
    }
}
