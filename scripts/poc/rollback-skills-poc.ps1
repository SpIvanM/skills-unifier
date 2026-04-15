[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string[]]$TargetRoots
)

$modulePath = Join-Path $PSScriptRoot 'SkillsUnifier.Poc.psm1'
Import-Module $modulePath -Force

Invoke-SkillsUnifierRollback -TargetRoots $TargetRoots
