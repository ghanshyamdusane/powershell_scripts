param(
[parameter(Mandatory=$false)]
[string] $environmentName = "AzureCloud",   
 
[parameter(Mandatory=$true)]
[string] $resourceGroupName,
 
[parameter(Mandatory=$false)]
[string] $azureRunAsConnectionName = "AzureRunAsConnection",
 
[parameter(Mandatory=$true)]
[string] $serverName,
 
[parameter(Mandatory=$true)]
[string] $databaseName,
 
[parameter(Mandatory=$true)]
[string] $scalingSchedule,
 
[parameter(Mandatory=$false)]
[string] $scalingScheduleTimeZone = "W. Europe Standard Time",
 
[parameter(Mandatory=$false)]
[string] $defaultEdition = "Standard",
 
[parameter(Mandatory=$false)]
[string] $defaultTier = "S0"
)
 
filter timestamp {"[$(Get-Date -Format G)]: $_"}
 
Write-Output "Script started." | timestamp
 
$VerbosePreference = "Continue"
$ErrorActionPreference = "Stop"
 
#Authenticate with Azure Automation Run As account (service principal)
$runAsConnectionProfile = Get-AutomationConnection -Name $azureRunAsConnectionName
$environment = Get-AzureRmEnvironment -Name $environmentName
Add-AzureRmAccount -Environment $environment -ServicePrincipal `
-TenantId $runAsConnectionProfile.TenantId `
-ApplicationId $runAsConnectionProfile.ApplicationId `
-CertificateThumbprint ` $runAsConnectionProfile.CertificateThumbprint | Out-Null
Write-Output "Authenticated with Automation Run As Account."  | timestamp
 
#Get current date/time and convert to $scalingScheduleTimeZone
$stateConfig = $scalingSchedule | ConvertFrom-Json
$startTime = Get-Date
Write-Output "Azure Automation local time: $startTime." | timestamp
$toTimeZone = [System.TimeZoneInfo]::FindSystemTimeZoneById($scalingScheduleTimeZone)
Write-Output "Time zone to convert to: $toTimeZone." | timestamp
$newTime = [System.TimeZoneInfo]::ConvertTime($startTime, $toTimeZone)
Write-Output "Converted time: $newTime." | timestamp
$startTime = $newTime
 
#Get current day of week, based on converted start time
$currentDayOfWeek = [Int]($startTime).DayOfWeek
Write-Output "Current day of week: $currentDayOfWeek." | timestamp
 
# Get the scaling schedule for the current day of week
$dayObjects = $stateConfig | Where-Object {$_.WeekDays -contains $currentDayOfWeek } `
|Select-Object Edition, Tier, `
@{Name="StartTime"; Expression = {[datetime]::ParseExact(($startTime.ToString("yyyy:MM:dd")+”:”+$_.StartTime),"yyyy:MM:dd:HH:mm:ss", [System.Globalization.CultureInfo]::InvariantCulture)}}, `
@{Name="StopTime"; Expression = {[datetime]::ParseExact(($startTime.ToString("yyyy:MM:dd")+”:”+$_.StopTime),"yyyy:MM:dd:HH:mm:ss", [System.Globalization.CultureInfo]::InvariantCulture)}}
 
# Get the database object
$sqlDB = Get-AzureRmSqlDatabase `
-ResourceGroupName $resourceGroupName `
-ServerName $serverName `
-DatabaseName $databaseName
Write-Output "DB name: $($sqlDB.DatabaseName)" | timestamp
Write-Output "Current DB status: $($sqlDB.Status), edition: $($sqlDB.Edition), tier: $($sqlDB.CurrentServiceObjectiveName)" | timestamp
 
if($dayObjects -ne $null) { # Scaling schedule found for this day
    # Get the scaling schedule for the current time. If there is more than one available, pick the first
    $matchingObject = $dayObjects | Where-Object { ($startTime -ge $_.StartTime) -and ($startTime -lt $_.StopTime) } | Select-Object -First 1
    if($matchingObject -ne $null)
    {
        Write-Output "Scaling schedule found. Check if current edition/tier is matching..." | timestamp
        if($sqlDB.CurrentServiceObjectiveName -ne $matchingObject.Tier -or $sqlDB.Edition -ne $matchingObject.Edition)
        {
            Write-Output "DB is not in the edition and/or tier of the scaling schedule. Changing!" | timestamp
            $sqlDB | Set-AzureRmSqlDatabase -Edition $matchingObject.Edition -RequestedServiceObjectiveName $matchingObject.Tier | out-null
            Write-Output "Change to edition/tier as specified in scaling schedule initiated..." | timestamp
            $sqlDB = Get-AzureRmSqlDatabase -ResourceGroupName $resourceGroupName -ServerName $serverName -DatabaseName $databaseName
            Write-Output "Current DB status: $($sqlDB.Status), edition: $($sqlDB.Edition), tier: $($sqlDB.CurrentServiceObjectiveName)" | timestamp
        }
        else
        {
            Write-Output "Current DB tier and edition matches the scaling schedule already. Exiting..." | timestamp
        }
    }
    else { # Scaling schedule not found for current time
        Write-Output "No matching scaling schedule time slot for this time found. Check if current edition/tier matches the default..." | timestamp
        if($sqlDB.CurrentServiceObjectiveName -ne $defaultTier -or $sqlDB.Edition -ne $defaultEdition)
        {
            Write-Output "DB is not in the default edition and/or tier. Changing!" | timestamp
            $sqlDB | Set-AzureRmSqlDatabase -Edition $defaultEdition -RequestedServiceObjectiveName $defaultTier | out-null
            Write-Output "Change to default edition/tier initiated." | timestamp
            $sqlDB = Get-AzureRmSqlDatabase -ResourceGroupName $resourceGroupName -ServerName $serverName -DatabaseName $databaseName
            Write-Output "Current DB status: $($sqlDB.Status), edition: $($sqlDB.Edition), tier: $($sqlDB.CurrentServiceObjectiveName)" | timestamp
        }
        else
        {
            Write-Output "Current DB tier and edition matches the default already. Exiting..." | timestamp
        }
    }
}
else # Scaling schedule not found for this day
{
    Write-Output "No matching scaling schedule for this day found. Check if current edition/tier matches the default..." | timestamp
    if($sqlDB.CurrentServiceObjectiveName -ne $defaultTier -or $sqlDB.Edition -ne $defaultEdition)
    {
        Write-Output "DB is not in the default edition and/or tier. Changing!" | timestamp
        $sqlDB | Set-AzureRmSqlDatabase -Edition $defaultEdition -RequestedServiceObjectiveName $defaultTier | out-null
        Write-Output "Change to default edition/tier initiated." | timestamp
        $sqlDB = Get-AzureRmSqlDatabase -ResourceGroupName $resourceGroupName -ServerName $serverName -DatabaseName $databaseName
        Write-Output "Current DB status: $($sqlDB.Status), edition: $($sqlDB.Edition), tier: $($sqlDB.CurrentServiceObjectiveName)" | timestamp
    }
    else
    {
        Write-Output "Current DB tier and edition matches the default already. Exiting..." | timestamp
    }
}
 
Write-Output "Script finished." | timestamp