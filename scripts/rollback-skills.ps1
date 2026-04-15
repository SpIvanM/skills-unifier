[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory = $false)]
    [string]$KnownLocationsPath,
    [switch]$RemoveBackup
)

$modulePath = Join-Path $PSScriptRoot 'SkillsUnifier.psm1'
Import-Module $modulePath -Force

if (-not $KnownLocationsPath) {
    $KnownLocationsPath = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\config\known-locations.psd1'))
}

Invoke-SkillsUnifierRollback -KnownLocationsPath $KnownLocationsPath -RemoveBackup:$RemoveBackup
