[CmdletBinding()]
param(
    [string]$SourcePath = 'c:\Users\ivanm\Documents\MD\Technology\iam-skills\skills',
    [Parameter(Mandatory = $true)]
    [string[]]$TargetRoots
)

$modulePath = Join-Path $PSScriptRoot 'SkillsUnifier.Poc.psm1'
Import-Module $modulePath -Force

Invoke-SkillsUnifierInstall -SourcePath $SourcePath -TargetRoots $TargetRoots
