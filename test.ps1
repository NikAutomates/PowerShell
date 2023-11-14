$Clock = [System.Diagnostics.Stopwatch]::new()
$Clock.Start()

$URI      = '' #Uri for List
$ListName = 'zzzz-test'
Connect-PnPOnline -Url $URI -DeviceLogin #Change this with .NET Class and SVC Account in Playbook

#Store SPO data in a hashtable to use for comparison
$ListData = @{}
Get-PnPListItem -List $ListName1 -PageSize 1000 | ForEach-Object { $ListData.Add($_.FieldValues.ID, $_.FieldValues) }
$HDWData = Import-Csv ./values.csv #Change me

$ItemsToAddToSPO = [System.Collections.ArrayList]::new()

#Loop through CSV HWD Data, perform a boolean switch accross nested loops
foreach ($CSV_Value in $HDWData) 
{
    $match = $false
#Loop through SPO List data
    foreach ($SPO_Value in $ListData.Values) 
    {
#If te COMIT_IT value in the SPO List and CSV do not match, define a variable to bool $true and break out loop
        if ($CSV_Value.COMIT_ID -eq $SPO_Value.COMIT_ID) 
        {
            $match = $true
            break
        }
    }
#If boolean remains false, append the collections array list to the looped HDW CSV Automatic variable
    if (!($match)) 
    {
        [void]$ItemsToAddToSPO.Add($CSV_Value) #Object 1 - Add new SamAccounts
    }
}

#Loop through the new appended array and write the object to the SPO List
if (([string]::IsNullOrEmpty(($ItemsToAddToSPO)))) { Exit 1}

$ItemsToAddToSPO | ForEach-Object {
$ValueToAdd = $_

  Add-PnPListItem -List "zzzz-test" -Values @{
     "COMIT_ID"     = $ValueToAdd.COMIT_ID; 
     "SEGMENT_NAME" = $ValueToAdd.SEGMENT_NAME; 
     "AIM_NUMBER"   = $ValueToAdd.AIM_NUMBER
    
  } 
    }

#Important, if a regular array is used, the .ADD Method will NOT working while appending the Array to the CSV Variable
$ItemsToUpdateToSPO = [System.Collections.ArrayList]::new()

#Nested loop through the original SPO and HDW CSV Data values
    foreach ($SPO_Value in $ListData.values) 
    {
        foreach ($CSV_Value in $HDWData) 
        {

#If any value does not match in SPO and HDW CSV, while the COMIT_ID Remains the same, update the values
  if ($CSV_Value.SEGMENT_NAME -ne $SPO_Value.SEGMENT_NAME -or $CSV_Value.AIM_NUMBER -ne 
      $SPO_Value.AIM_NUMBER -and $CSV_Value.COMIT_ID -eq $SPO_Value.COMIT_ID) 
      {

#CSV object will not contain the "SPO ID" Property, add Noteproperty as a member on the object
      $CSV_Value | Add-Member -MemberType NoteProperty -Name 'ID' -Value $SPO_Value.ID -Force

       [void]$ItemsToUpdateToSPO.Add($CSV_Value) #Object - Update values on EXISTING SamAccounts
      }
   }
}

#Loop through the new appended array and update the existing SPO object with the partial CSV Object
$ItemsToUpdateToSPO | ForEach-Object {
if (([string]::IsNullOrEmpty(($ItemsToUpdateToSPO)))) { Exit 1 }

    Set-PnPListItem -Identity $ValueToUpdate.ID -List $ListName -Values @{

        "SEGMENT_NAME" = $ValueToUpdate.SEGMENT_NAME; 
        "AIM_NUMBER"   = $ValueToUpdate.AIM_NUMBER
       
          } 
       }
$Clock.Stop()
$Clock.Elapsed.TotalMinutes

#If it takes over 10minutes, send an alert to Splunk
If ($Clock.Elapsed.TotalMinutes -gt "10") {

    Write-Warning "Script took over 10mins" #Insert write-log to splunk here
}

@('$ItemsToAddToSPO', '$ItemsToUpdateToSPO') | % { Get-Variable -Name $_ | Remove-Variable }

#Check for duplicate values.....


#Add Error handling......
