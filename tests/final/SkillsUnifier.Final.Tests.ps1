$ErrorActionPreference = 'Stop'

function New-FinalTestLayout {
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

    Set-Content -Path (Join-Path $sourceOne 'skills.txt') -Value 'source-one'
    Set-Content -Path (Join-Path $sourceTwo 'skills.txt') -Value 'source-two'
    Set-Content -Path (Join-Path $targetOne 'legacy.txt') -Value 'legacy-one'
    Set-Content -Path (Join-Path $targetTwo 'legacy.txt') -Value 'legacy-two'

    [pscustomobject]@{
        SourceOne = $sourceOne
        SourceTwo = $sourceTwo
        Targets   = @($targetOne, $targetTwo)
    }
}

function New-KnownLocationsConfig {
    param(
        [string]$Path,
        [string[]]$Targets
    )

    $lines = @(
        '@{'
        '  KnownSkillRoots = @('
    )

    foreach ($target in $Targets) {
        $lines += "    '$target'"
    }

    $lines += @(
        '  )'
        '}'
    )

    Set-Content -Path $Path -Value ($lines -join [Environment]::NewLine)
}

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$installScript = Join-Path $repoRoot 'scripts\install-skills.ps1'
$wrapperScript = Join-Path $repoRoot 'scripts\install-skills-iam.ps1'
$rollbackScript = Join-Path $repoRoot 'scripts\rollback-skills.ps1'

Describe 'Skills Unifier final scripts' {
    It 'installs junctions based on the supplied known-locations config' {
        $layout = New-FinalTestLayout -BasePath (Join-Path $TestDrive 'install')
        $configPath = Join-Path $TestDrive 'known-locations.psd1'
        New-KnownLocationsConfig -Path $configPath -Targets $layout.Targets

        & $installScript -SourcePath $layout.SourceOne -KnownLocationsPath $configPath

        foreach ($target in $layout.Targets) {
            $backupPath = Join-Path (Split-Path -Parent $target) 'skills-backup'

            (Get-Item $target).Attributes.HasFlag([IO.FileAttributes]::ReparsePoint) | Should Be $true
            (Get-Content -Path (Join-Path $target 'skills.txt')) | Should Be 'source-one'
            (Test-Path $backupPath) | Should Be $true
            (Get-Content -Path (Join-Path $backupPath 'legacy.txt')) | Should Match '^legacy-'
        }
    }

    It 'is idempotent and updates the source when run again' {
        $layout = New-FinalTestLayout -BasePath (Join-Path $TestDrive 'repeat')
        $configPath = Join-Path $TestDrive 'known-locations-repeat.psd1'
        New-KnownLocationsConfig -Path $configPath -Targets $layout.Targets

        & $installScript -SourcePath $layout.SourceOne -KnownLocationsPath $configPath
        & $installScript -SourcePath $layout.SourceTwo -KnownLocationsPath $configPath

        foreach ($target in $layout.Targets) {
            $backupPath = Join-Path (Split-Path -Parent $target) 'skills-backup'
            $markerPath = Join-Path $backupPath '.skills-unifier\state.json'
            $marker = Get-Content -Path $markerPath -Raw | ConvertFrom-Json

            (Get-Content -Path (Join-Path $target 'skills.txt')) | Should Be 'source-two'
            $marker.SourcePath | Should Be $layout.SourceTwo
            $marker.TargetPath | Should Be $target
            (Test-Path (Join-Path $backupPath 'legacy.txt')) | Should Be $true
        }
    }

    It 'rolls back managed targets and keeps backups by default' {
        $layout = New-FinalTestLayout -BasePath (Join-Path $TestDrive 'rollback')
        $configPath = Join-Path $TestDrive 'known-locations-rollback.psd1'
        New-KnownLocationsConfig -Path $configPath -Targets $layout.Targets

        & $installScript -SourcePath $layout.SourceOne -KnownLocationsPath $configPath
        & $rollbackScript -KnownLocationsPath $configPath

        foreach ($target in $layout.Targets) {
            $backupPath = Join-Path (Split-Path -Parent $target) 'skills-backup'

            (Get-Item $target).Attributes.HasFlag([IO.FileAttributes]::ReparsePoint) | Should Be $false
            (Get-Content -Path (Join-Path $target 'legacy.txt')) | Should Match '^legacy-'
            (Test-Path (Join-Path $target 'skills.txt')) | Should Be $false
            (Test-Path $backupPath) | Should Be $true
        }
    }

    It 'wrapper forwards the source path to the universal installer' {
        $layout = New-FinalTestLayout -BasePath (Join-Path $TestDrive 'wrapper')
        $configPath = Join-Path $TestDrive 'known-locations-wrapper.psd1'
        New-KnownLocationsConfig -Path $configPath -Targets $layout.Targets

        & $wrapperScript -SourcePath $layout.SourceTwo -KnownLocationsPath $configPath

        foreach ($target in $layout.Targets) {
            (Get-Content -Path (Join-Path $target 'skills.txt')) | Should Be 'source-two'
        }
    }
}
