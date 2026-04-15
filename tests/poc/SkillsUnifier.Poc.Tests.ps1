$ErrorActionPreference = 'Stop'

function New-PocLayout {
    param(
        [string]$BasePath
    )

    $sourceOne = Join-Path $BasePath 'source-one\skills'
    $sourceTwo = Join-Path $BasePath 'source-two\skills'
    $targetOne = Join-Path $BasePath 'agents\claude\skills'
    $targetTwo = Join-Path $BasePath 'agents\codex\skills'

    foreach ($path in @($sourceOne, $sourceTwo, $targetOne, $targetTwo)) {
        New-Item -ItemType Directory -Path $path -Force | Out-Null
    }

    Set-Content -Path (Join-Path $sourceOne 'source.txt') -Value 'source-one'
    Set-Content -Path (Join-Path $sourceTwo 'source.txt') -Value 'source-two'
    Set-Content -Path (Join-Path $targetOne 'legacy.txt') -Value 'legacy-one'
    Set-Content -Path (Join-Path $targetTwo 'legacy.txt') -Value 'legacy-two'

    [pscustomobject]@{
        SourceOne = $sourceOne
        SourceTwo = $sourceTwo
        Targets   = @($targetOne, $targetTwo)
    }
}

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$modulePath = Join-Path $repoRoot 'scripts\poc\SkillsUnifier.Poc.psm1'
$installScript = Join-Path $repoRoot 'scripts\poc\install-skills-poc.ps1'
$wrapperScript = Join-Path $repoRoot 'scripts\poc\install-skills-poc.ps1'
$rollbackScript = Join-Path $repoRoot 'scripts\poc\rollback-skills-poc.ps1'

Describe 'Skills Unifier PoC' {
    It 'backs up existing skills folders and creates junctions to the source' {
        Import-Module $modulePath -Force

        $layout = New-PocLayout -BasePath (Join-Path $TestDrive 'case-one')

        & $installScript -SourcePath $layout.SourceOne -TargetRoots $layout.Targets

        foreach ($target in $layout.Targets) {
            $backupPath = Join-Path (Split-Path -Parent $target) 'skills-backup'
            $markerPath = Join-Path $backupPath 'skills-unifier.state.json'
            $item = Get-Item $target

            $item.Attributes.HasFlag([IO.FileAttributes]::ReparsePoint) | Should Be $true
            (Get-Content -Path (Join-Path $target 'source.txt')) | Should Be 'source-one'
            (Test-Path $backupPath) | Should Be $true
            (Get-Content -Path (Join-Path $backupPath 'legacy.txt')) | Should BeLike 'legacy-*'
            (Test-Path $markerPath) | Should Be $true
        }
    }

    It 'is idempotent and can switch the source path on repeat install' {
        Import-Module $modulePath -Force

        $layout = New-PocLayout -BasePath (Join-Path $TestDrive 'case-two')

        & $installScript -SourcePath $layout.SourceOne -TargetRoots $layout.Targets
        & $installScript -SourcePath $layout.SourceTwo -TargetRoots $layout.Targets

        foreach ($target in $layout.Targets) {
            $backupPath = Join-Path (Split-Path -Parent $target) 'skills-backup'
            $markerPath = Join-Path $backupPath 'skills-unifier.state.json'
            $marker = Get-Content -Path $markerPath | ConvertFrom-Json

            (Get-Content -Path (Join-Path $target 'source.txt')) | Should Be 'source-two'
            (Test-Path (Join-Path $backupPath 'legacy.txt')) | Should Be $true
            $marker.SourcePath | Should Be $layout.SourceTwo
            $marker.TargetPath | Should Be $target
        }
    }

    It 'restores original folders on rollback and keeps backups by default' {
        Import-Module $modulePath -Force

        $layout = New-PocLayout -BasePath (Join-Path $TestDrive 'case-three')

        & $installScript -SourcePath $layout.SourceOne -TargetRoots $layout.Targets
        & $rollbackScript -TargetRoots $layout.Targets

        foreach ($target in $layout.Targets) {
            $backupPath = Join-Path (Split-Path -Parent $target) 'skills-backup'
            $item = Get-Item $target

            $item.Attributes.HasFlag([IO.FileAttributes]::ReparsePoint) | Should Be $false
            (Get-Content -Path (Join-Path $target 'legacy.txt')) | Should Match '^legacy-'
            (Test-Path (Join-Path $target 'source.txt')) | Should Be $false
            (Test-Path $backupPath) | Should Be $true
        }
    }

    It 'wrapper forwards a caller-provided source path' {
        Import-Module $modulePath -Force

        $layout = New-PocLayout -BasePath (Join-Path $TestDrive 'case-four')

        & $wrapperScript -SourcePath $layout.SourceTwo -TargetRoots $layout.Targets

        foreach ($target in $layout.Targets) {
            (Get-Content -Path (Join-Path $target 'source.txt')) | Should Be 'source-two'
        }
    }
}
