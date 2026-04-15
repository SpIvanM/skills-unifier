Set-StrictMode -Version Latest

function Get-SkillsUnifierDefaultConfigPath {
    return [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\config\known-locations.psd1'))
}

function Resolve-SkillsUnifierPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $providerPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)
    return [System.IO.Path]::GetFullPath($providerPath)
}

function Normalize-SkillsUnifierPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $fullPath = Resolve-SkillsUnifierPath -Path $Path
    if ($fullPath.Length -gt 3) {
        $fullPath = $fullPath.TrimEnd('\', '/')
    }

    return $fullPath
}

function Test-SkillsUnifierPathEqual {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Left,
        [Parameter(Mandatory = $true)]
        [string]$Right
    )

    return [string]::Equals(
        (Normalize-SkillsUnifierPath -Path $Left),
        (Normalize-SkillsUnifierPath -Path $Right),
        [System.StringComparison]::OrdinalIgnoreCase
    )
}

function Get-SkillsUnifierKnownTargets {
    param(
        [Parameter(Mandatory = $false)]
        [string]$KnownLocationsPath
    )

    if (-not $KnownLocationsPath) {
        $KnownLocationsPath = Get-SkillsUnifierDefaultConfigPath
    }

    $resolvedConfigPath = Resolve-SkillsUnifierPath -Path $KnownLocationsPath
    if (-not (Test-Path -LiteralPath $resolvedConfigPath)) {
        throw "Known locations config not found: $resolvedConfigPath"
    }

    $config = Import-PowerShellDataFile -Path $resolvedConfigPath
    if ($null -eq $config -or -not ($config -is [System.Collections.IDictionary])) {
        throw "Known locations config could not be loaded as a hashtable: $resolvedConfigPath"
    }

    if (-not $config.ContainsKey('KnownSkillRoots')) {
        throw "Config file is missing KnownSkillRoots: $resolvedConfigPath"
    }

    $targets = foreach ($root in @($config.KnownSkillRoots)) {
        if ($null -ne $root -and $root.ToString().Trim()) {
            Normalize-SkillsUnifierPath -Path $root
        }
    }

    return $targets | Sort-Object -Unique
}

function Get-SkillsUnifierBackupRoot {
    param(
        [Parameter(Mandatory = $true)]
        [string]$TargetRoot
    )

    return Join-Path (Split-Path -Parent $TargetRoot) 'skills-backup'
}

function Get-SkillsUnifierManagementRoot {
    param(
        [Parameter(Mandatory = $true)]
        [string]$BackupRoot
    )

    return Join-Path $BackupRoot '.skills-unifier'
}

function Get-SkillsUnifierStatePath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$BackupRoot
    )

    return Join-Path (Get-SkillsUnifierManagementRoot -BackupRoot $BackupRoot) 'state.json'
}

function Get-SkillsUnifierSnapshotRoot {
    param(
        [Parameter(Mandatory = $true)]
        [string]$BackupRoot
    )

    return Join-Path (Get-SkillsUnifierManagementRoot -BackupRoot $BackupRoot) 'snapshots'
}

function Get-SkillsUnifierTimestamp {
    return (Get-Date).ToString('yyyyMMdd-HHmmss-fff')
}

function New-SkillsUnifierSnapshotPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$BackupRoot
    )

    $snapshotsRoot = Get-SkillsUnifierSnapshotRoot -BackupRoot $BackupRoot
    $null = New-Item -ItemType Directory -Path $snapshotsRoot -Force

    $timestamp = Get-SkillsUnifierTimestamp
    $candidate = Join-Path $snapshotsRoot $timestamp
    $suffix = 0

    while (Test-Path -LiteralPath $candidate) {
        $suffix++
        $candidate = Join-Path $snapshotsRoot ("{0}-{1}" -f $timestamp, $suffix)
    }

    return $candidate
}

function Read-SkillsUnifierState {
    param(
        [Parameter(Mandatory = $true)]
        [string]$BackupRoot
    )

    $statePath = Get-SkillsUnifierStatePath -BackupRoot $BackupRoot
    if (-not (Test-Path -LiteralPath $statePath)) {
        return $null
    }

    return Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json
}

function Write-SkillsUnifierState {
    param(
        [Parameter(Mandatory = $true)]
        [string]$BackupRoot,
        [Parameter(Mandatory = $true)]
        [string]$TargetRoot,
        [Parameter(Mandatory = $true)]
        [string]$SourcePath,
        [Parameter(Mandatory = $true)]
        [string]$SnapshotMode,
        [AllowNull()]
        [string]$SnapshotPath
    )

    $managementRoot = Get-SkillsUnifierManagementRoot -BackupRoot $BackupRoot
    $null = New-Item -ItemType Directory -Path $managementRoot -Force

    $existing = Read-SkillsUnifierState -BackupRoot $BackupRoot
    $createdAt = if ($existing -and $existing.CreatedAt) { $existing.CreatedAt } else { (Get-Date).ToString('o') }

    $state = [ordered]@{
        Managed     = $true
        SourcePath  = (Normalize-SkillsUnifierPath -Path $SourcePath)
        TargetPath  = (Normalize-SkillsUnifierPath -Path $TargetRoot)
        BackupRoot  = (Normalize-SkillsUnifierPath -Path $BackupRoot)
        SnapshotMode = $SnapshotMode
        SnapshotPath = $SnapshotPath
        LinkType    = 'Junction'
        CreatedAt   = $createdAt
        UpdatedAt   = (Get-Date).ToString('o')
    }

    $statePath = Get-SkillsUnifierStatePath -BackupRoot $BackupRoot
    $state | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $statePath -Encoding UTF8
}

function Test-SkillsUnifierJunctionTarget {
    param(
        [Parameter(Mandatory = $true)]
        [string]$TargetRoot,
        [Parameter(Mandatory = $true)]
        [string]$SourcePath
    )

    if (-not (Test-Path -LiteralPath $TargetRoot)) {
        return $false
    }

    $item = Get-Item -LiteralPath $TargetRoot -Force
    if (-not $item.Attributes.HasFlag([System.IO.FileAttributes]::ReparsePoint)) {
        return $false
    }

    $resolvedTarget = Resolve-SkillsUnifierPath -Path (Resolve-Path -LiteralPath $TargetRoot).Path
    $resolvedSource = Resolve-SkillsUnifierPath -Path $SourcePath
    return Test-SkillsUnifierPathEqual -Left $resolvedTarget -Right $resolvedSource
}

function Move-SkillsUnifierTargetToBackup {
    param(
        [Parameter(Mandatory = $true)]
        [string]$TargetRoot,
        [Parameter(Mandatory = $true)]
        [string]$BackupRoot
    )

    if (-not (Test-Path -LiteralPath $BackupRoot)) {
        $null = Move-Item -LiteralPath $TargetRoot -Destination $BackupRoot
        return [pscustomobject]@{
            SnapshotMode = 'Root'
            SnapshotPath = (Normalize-SkillsUnifierPath -Path $BackupRoot)
        }
    }

    if (-not (Test-Path -LiteralPath $BackupRoot -PathType Container)) {
        throw "Backup path exists and is not a directory: $BackupRoot"
    }

    $snapshotPath = New-SkillsUnifierSnapshotPath -BackupRoot $BackupRoot
    $snapshotParent = Split-Path -Parent $snapshotPath
    $null = New-Item -ItemType Directory -Path $snapshotParent -Force
    $null = Move-Item -LiteralPath $TargetRoot -Destination $snapshotPath

    return [pscustomobject]@{
        SnapshotMode = 'SnapshotFolder'
        SnapshotPath = (Normalize-SkillsUnifierPath -Path $snapshotPath)
    }
}

function Copy-SkillsUnifierSnapshotContents {
    param(
        [Parameter(Mandatory = $true)]
        [string]$SnapshotPath,
        [Parameter(Mandatory = $true)]
        [string]$TargetRoot,
        [switch]$ExcludeManagementRoot
    )

    $null = New-Item -ItemType Directory -Path $TargetRoot -Force

    $items = Get-ChildItem -LiteralPath $SnapshotPath -Force
    if ($ExcludeManagementRoot) {
        $items = $items | Where-Object { $_.Name -ne '.skills-unifier' }
    }

    foreach ($item in $items) {
        $null = Copy-Item -LiteralPath $item.FullName -Destination $TargetRoot -Recurse -Force
    }
}

function Invoke-SkillsUnifierInstall {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory = $true)]
        [string]$SourcePath,
        [Parameter(Mandatory = $false)]
        [string]$KnownLocationsPath
    )

    if (-not $KnownLocationsPath) {
        $KnownLocationsPath = Get-SkillsUnifierDefaultConfigPath
    }

    $resolvedSource = Normalize-SkillsUnifierPath -Path $SourcePath
    if (-not (Test-Path -LiteralPath $resolvedSource)) {
        throw "Source path not found: $resolvedSource"
    }

    $targets = Get-SkillsUnifierKnownTargets -KnownLocationsPath $KnownLocationsPath
    $results = New-Object System.Collections.Generic.List[object]

    foreach ($targetRoot in $targets) {
        $targetParent = Split-Path -Parent $targetRoot
        $backupRoot = Get-SkillsUnifierBackupRoot -TargetRoot $targetRoot
        $existingState = Read-SkillsUnifierState -BackupRoot $backupRoot
        $snapshotMode = 'None'
        $snapshotPath = $null

        $null = New-Item -ItemType Directory -Path $targetParent -Force

        if (Test-SkillsUnifierJunctionTarget -TargetRoot $targetRoot -SourcePath $resolvedSource) {
            if ($existingState) {
                Write-SkillsUnifierState -BackupRoot $backupRoot -TargetRoot $targetRoot -SourcePath $resolvedSource -SnapshotMode $existingState.SnapshotMode -SnapshotPath $existingState.SnapshotPath
            }

            $results.Add([pscustomobject]@{
                TargetPath = $targetRoot
                Action     = 'Skipped'
                Details    = 'Already linked to the requested source'
            })
            continue
        }

        if (Test-Path -LiteralPath $targetRoot) {
            $item = Get-Item -LiteralPath $targetRoot -Force
            if ($item.Attributes.HasFlag([System.IO.FileAttributes]::ReparsePoint)) {
                $null = Remove-Item -LiteralPath $targetRoot -Force
            }
            else {
                $snapshotInfo = Move-SkillsUnifierTargetToBackup -TargetRoot $targetRoot -BackupRoot $backupRoot
                $snapshotMode = $snapshotInfo.SnapshotMode
                $snapshotPath = $snapshotInfo.SnapshotPath
            }
        }
        elseif ($existingState) {
            $snapshotMode = $existingState.SnapshotMode
            $snapshotPath = $existingState.SnapshotPath
        }

        $null = New-Item -ItemType Junction -Path $targetRoot -Target $resolvedSource

        if (-not $snapshotMode -or $snapshotMode -eq 'None') {
            if ($existingState) {
                $snapshotMode = $existingState.SnapshotMode
                $snapshotPath = $existingState.SnapshotPath
            }
        }

        Write-SkillsUnifierState -BackupRoot $backupRoot -TargetRoot $targetRoot -SourcePath $resolvedSource -SnapshotMode $snapshotMode -SnapshotPath $snapshotPath

        $results.Add([pscustomobject]@{
            TargetPath = $targetRoot
            Action     = 'Installed'
            Details    = $resolvedSource
        })
    }

    return $results
}

function Invoke-SkillsUnifierRollback {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory = $false)]
        [string]$KnownLocationsPath,
        [switch]$RemoveBackup
    )

    if (-not $KnownLocationsPath) {
        $KnownLocationsPath = Get-SkillsUnifierDefaultConfigPath
    }

    $targets = Get-SkillsUnifierKnownTargets -KnownLocationsPath $KnownLocationsPath
    $results = New-Object System.Collections.Generic.List[object]

    foreach ($targetRoot in $targets) {
        $backupRoot = Get-SkillsUnifierBackupRoot -TargetRoot $targetRoot
        $managementRoot = Get-SkillsUnifierManagementRoot -BackupRoot $backupRoot
        $state = Read-SkillsUnifierState -BackupRoot $backupRoot

        if (-not $state -or -not $state.Managed) {
            $results.Add([pscustomobject]@{
                TargetPath = $targetRoot
                Action     = 'Skipped'
                Details    = 'No managed state found'
            })
            continue
        }

        if (Test-Path -LiteralPath $targetRoot) {
            $item = Get-Item -LiteralPath $targetRoot -Force
            if ($item.Attributes.HasFlag([System.IO.FileAttributes]::ReparsePoint)) {
                $null = Remove-Item -LiteralPath $targetRoot -Force
            }
            else {
                $capturesRoot = Join-Path $managementRoot 'captures'
                $null = New-Item -ItemType Directory -Path $capturesRoot -Force
                $capturePath = Join-Path $capturesRoot ('rollback-' + (Get-SkillsUnifierTimestamp))
                $null = Move-Item -LiteralPath $targetRoot -Destination $capturePath
            }
        }

        if ($state.SnapshotMode -eq 'Root') {
            Copy-SkillsUnifierSnapshotContents -SnapshotPath $backupRoot -TargetRoot $targetRoot -ExcludeManagementRoot
        }
        elseif ($state.SnapshotMode -eq 'SnapshotFolder' -and $state.SnapshotPath -and (Test-Path -LiteralPath $state.SnapshotPath)) {
            Copy-SkillsUnifierSnapshotContents -SnapshotPath $state.SnapshotPath -TargetRoot $targetRoot
        }
        else {
            $null = New-Item -ItemType Directory -Path $targetRoot -Force
        }

        if ($RemoveBackup) {
            $null = Remove-Item -LiteralPath $backupRoot -Recurse -Force
        }

        $results.Add([pscustomobject]@{
            TargetPath = $targetRoot
            Action     = 'Restored'
            Details    = $state.SnapshotMode
        })
    }

    return $results
}

Export-ModuleMember -Function Invoke-SkillsUnifierInstall, Invoke-SkillsUnifierRollback
