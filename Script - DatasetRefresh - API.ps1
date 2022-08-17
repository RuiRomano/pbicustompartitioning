#Requires -Modules @{ ModuleName="MicrosoftPowerBIMgmt"; ModuleVersion="1.2.1026" }

param(
    $workspaceId = "3abcd67b-ea43-4bb1-8be4-f31d106f0b70"
    ,
    $datasetId = "db060979-5667-4cd9-8197-606d09b56cb1"
    ,
    $currentDate = [datetime]"2019-01-01"
)

$ErrorActionPreference = "Stop"

$currentPath = (Split-Path $MyInvocation.MyCommand.Definition -Parent)

$refreshBatches = @(
    @{ 
        "BatchName"      = "Dimensions Batch"
        ;
        "type"           = "full"
        ;
        "commitMode"     = "transactional"
        ;
        "maxParallelism" = 30
        ;
        "retryCount"     = 1
        ;
        "objects"        = @("Product", "Customer", "Store", "Calendar") |% { @{ "table" = $_ } }            
    } 
    ,
    @{ 
        "BatchName"      = "Facts Batch"
        ;
        "type"           = "full"
        ;
        "commitMode"     = "transactional"
        ;
        "maxParallelism" = 10
        ;
        "retryCount"     = 1
        ;
        "objects"        = (-2..0) | %{
            
            $relativeDate = $currentDate.AddMonths($_)

            @{
                "table" = "Sales"
                ;
                "partition" = ("Sales_{0:yyyy}_{0:MM}" -f $relativeDate)
            }
        }
    } 
)

# Get running refreshes, only 1 operation is allowed "Only one refresh operation at a time is accepted for a dataset. If there's a current running refresh operation and another is submitted"

Connect-PowerBIServiceAccount

$refreshes = Invoke-PowerBIRestMethod -url "groups/$workspaceId/datasets/$datasetId/refreshes?`$top=3" -method Get | ConvertFrom-Json | select -ExpandProperty value

if ($refreshes | ? { $_.refreshType -eq "ViaEnhancedApi" -and $_.status -iin @("Unknown", "inProgress", "notStarted") }) {
    Write-Warning "There is already a Refresh running via 'EnhancedApi', try again later."
    return
}

foreach ($refreshBatch in $refreshBatches)
{
    Write-Host "Refreshing batch '$($refreshBatch.BatchName)'"

    $executeJsonBody = $refreshBatch | select -ExcludeProperty "BatchName" | ConvertTo-Json -Depth 5

    $refreshExecution = Invoke-PowerBIRestMethod -url "groups/$workspaceId/datasets/$datasetId/refreshes" -method Post -Body $executeJsonBody

    # There is a Response header with the requestid, but the Invoke-PowerBIRestMethod dont output the response headers - https://docs.microsoft.com/en-us/power-bi/connect-data/asynchronous-refresh#response
    # Instead we need to call /refreshes with top 1 and capture the last refresh operation

    $refreshes = @(Invoke-PowerBIRestMethod -url "groups/$workspaceId/datasets/$datasetId/refreshes?`$top=1" -method Get | ConvertFrom-Json | select -ExpandProperty value)

    $refreshId = $refreshes[0].requestId

    do {
        $refreshDetails = Invoke-PowerBIRestMethod -url "groups/$workspaceId/datasets/$datasetId/refreshes/$refreshId" -method Get | ConvertFrom-Json
    
        Write-Host "Status: $($refreshDetails.status)"
        Write-Host ($refreshDetails.objects | format-table | out-string)
        Write-Host "sleeping..."
    
        Start-Sleep -Seconds 2
    
    }
    while ($refreshDetails.status -iin @("Unknown", "inProgress", "notStarted"))

    Write-Host "Refresh complete: $((([datetime]$refreshDetails.endTime) - ([datetime]$refreshDetails.startTime)).TotalSeconds)s"
}