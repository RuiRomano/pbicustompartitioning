param (
$serverName = "powerbi://api.powerbi.com/v1.0/myorg/CustomPartitioning"
, $databaseName = "Contoso-Partitioned"
, $years = (2018..2022)
)
$ErrorActionPreference = "Stop"

$currentPath = (Split-Path $MyInvocation.MyCommand.Definition -Parent)

Import-Module "$currentPath\TOMHelper.psm1" -Force

$partitions = @()

foreach ($year in $years)
{
    foreach($month in @(1..12))
    {        
        $partitions += @{
            TableName = "Sales"
            ;
            Name = "Sales_$($year)_$($month.ToString("D2"))"
            ;
            Type = "M"
            ;
            Query = "
            let
                Source = Sql.Database(Server, Database),
                dbo_Sales = Source{[Schema=""dbo"",Item=""Sales""]}[Data],
                #""Removed Other Columns"" = Table.SelectColumns(dbo_Sales,{""Order Date"", ""Delivery Date"", ""CustomerKey"", ""StoreKey"", ""ProductKey"", ""Quantity"", ""Unit Price"", ""Net Price"", ""Unit Cost"", ""Currency Code"", ""Exchange Rate""}),
                #""Filtered Rows"" = Table.SelectRows(#""Removed Other Columns"", each  Date.Year([Order Date]) = $year and Date.Month([Order Date]) = $month)
            in
            #""Filtered Rows"""
            }
    }
}

Add-ASTablePartition -serverName $serverName -databaseName $databaseName -partitions $partitions -removeDefaultPartition