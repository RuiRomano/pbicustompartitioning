#Requires -Modules @{ ModuleName="MicrosoftPowerBIMgmt"; ModuleVersion="1.2.1026" }

param(
    $workspaceId = "3abcd67b-ea43-4bb1-8be4-f31d106f0b70"
    ,
    $datasetId = "db060979-5667-4cd9-8197-606d09b56cb1"
)

$ErrorActionPreference = "Stop"

$currentPath = (Split-Path $MyInvocation.MyCommand.Definition -Parent)

# Get running refreshes, only 1 operation is allowed "Only one refresh operation at a time is accepted for a dataset. If there's a current running refresh operation and another is submitted"

Connect-PowerBIServiceAccount

$refreshes = Invoke-PowerBIRestMethod -url "groups/$workspaceId/datasets/$datasetId/refreshes?`$top=5" -method Get | ConvertFrom-Json | select -ExpandProperty value

$refreshes | Format-Table