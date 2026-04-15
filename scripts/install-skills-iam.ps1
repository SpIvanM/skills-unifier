[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [string]$SourcePath = 'c:\Users\ivanm\Documents\MD\Technology\iam-skills\skills',
    [Parameter(Mandatory = $false)]
    [string]$KnownLocationsPath
)

$modulePath = Join-Path $PSScriptRoot 'SkillsUnifier.psm1'
Import-Module $modulePath -Force

if (-not $KnownLocationsPath) {
    $KnownLocationsPath = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\config\known-locations.psd1'))
}

Invoke-SkillsUnifierInstall -SourcePath $SourcePath -KnownLocationsPath $KnownLocationsPath
