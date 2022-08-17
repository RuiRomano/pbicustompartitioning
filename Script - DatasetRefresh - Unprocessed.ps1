﻿param (
$serverName = "powerbi://api.powerbi.com/v1.0/myorg/EnhancedRefreshAPI_LogicApp"
, $databaseName = "Contoso-Partitioned"
, $maxParallelism = 10
, $batchPartitionCount = 4
)

$currentPath = (Split-Path $MyInvocation.MyCommand.Definition -Parent)

Import-Module "$currentPath\TOMHelper.psm1" -Force

$tables = Get-ASTable -serverName $serverName -databaseName $databaseName -includePartitions

$sw = [system.diagnostics.stopwatch]::StartNew()

foreach($table in $tables)
{
    try
    {
        Write-Host "Processing table: $($table.Name)"

        $unprocessedPartitions = @($table.Partitions |? State -ne "Ready")

        if ($unprocessedPartitions.Count -gt 0)
        {
            $batchSkip = 0
            
            $processOrders = @()

            do
            {
                $batchPartitions = @($unprocessedPartitions | select -First $batchPartitionCount -Skip $batchSkip)

                if ($batchPartitions.Count -gt 0)
                {
                    $processOrders +=  @{
                        Server = $serverName
                        ;
                        DatabaseName = $databaseName
                        ;
                        TableName = $table.Name
                        ;
                        Partitions = @($batchPartitions.Name)
                        ;
                        Group = "Group $batchSkip"
                    }

                    $batchSkip += $batchPartitions.Count
                }
            }
            while($batchPartitions)

            $results = Invoke-ASTableProcess -tables $processOrders -maxParallelism $maxParallelism
        }
        else
        {
            Write-Host "Table fully processed"
        }
    }
    catch
    {
        Write-Error -Message "Error on table '$($table.Name)'; Error: '$($_.Exception.Message)'" -Exception $_.Exception -ErrorAction Continue
    }
}

$sw.Stop()

Write-Host "Time: $($sw.Elapsed.TotalSeconds)s"

