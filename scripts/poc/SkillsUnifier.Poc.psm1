Set-StrictMode -Version Latest

function ConvertTo-SkillsUnifierFullPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $providerPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)
    return [System.IO.Path]::GetFullPath($providerPath)
}

function Get-SkillsUnifierTimestamp {
    return (Get-Date).ToString('yyyyMMdd-HHmmss-fff')
}

function Get-SkillsUnifierBackupPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$TargetRoot
    )

    return Join-Path (Split-Path -Parent $TargetRoot) 'skills-backup'
}

function Get-SkillsUnifierMarkerPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$BackupPath
    )

    return Join-Path $BackupPath 'skills-unifier.state.json'
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

    $resolvedTarget = ConvertTo-SkillsUnifierFullPath -Path (Resolve-Path -LiteralPath $TargetRoot).Path
    $resolvedSource = ConvertTo-SkillsUnifierFullPath -Path $SourcePath
    return $resolvedTarget -eq $resolvedSource
}

function Write-SkillsUnifierMarker {
    param(
        [Parameter(Mandatory = $true)]
        [string]$BackupPath,
        [Parameter(Mandatory = $true)]
        [string]$TargetRoot,
        [Parameter(Mandatory = $true)]
        [string]$SourcePath
    )

    $markerPath = Get-SkillsUnifierMarkerPath -BackupPath $BackupPath
    $marker = [ordered]@{
        Managed    = $true
        SourcePath = (ConvertTo-SkillsUnifierFullPath -Path $SourcePath)
        TargetPath = (ConvertTo-SkillsUnifierFullPath -Path $TargetRoot)
        BackupPath = (ConvertTo-SkillsUnifierFullPath -Path $BackupPath)
        LinkType   = 'Junction'
        UpdatedAt  = (Get-Date).ToString('o')
    }

    $null = New-Item -ItemType Directory -Path $BackupPath -Force
    $marker | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $markerPath -Encoding UTF8
}

function Read-SkillsUnifierMarker {
    param(
        [Parameter(Mandatory = $true)]
        [string]$BackupPath
    )

    $markerPath = Get-SkillsUnifierMarkerPath -BackupPath $BackupPath
    if (-not (Test-Path -LiteralPath $markerPath)) {
        return $null
    }

    return Get-Content -LiteralPath $markerPath -Raw | ConvertFrom-Json
}

function Move-SkillsUnifierDirectoryToBackup {
    param(
        [Parameter(Mandatory = $true)]
        [string]$TargetRoot,
        [Parameter(Mandatory = $true)]
        [string]$BackupPath
    )

    if (-not (Test-Path -LiteralPath $BackupPath)) {
        $null = Move-Item -LiteralPath $TargetRoot -Destination $BackupPath
        return
    }

    $capturesRoot = Join-Path $BackupPath 'captures'
    $null = New-Item -ItemType Directory -Path $capturesRoot -Force
    $capturePath = Join-Path $capturesRoot ('capture-' + (Get-SkillsUnifierTimestamp))
    $null = Move-Item -LiteralPath $TargetRoot -Destination $capturePath
}

function Copy-SkillsUnifierSnapshotToTarget {
    param(
        [Parameter(Mandatory = $true)]
        [string]$BackupPath,
        [Parameter(Mandatory = $true)]
        [string]$TargetRoot
    )

    $null = New-Item -ItemType Directory -Path $TargetRoot -Force

    $items = Get-ChildItem -LiteralPath $BackupPath -Force | Where-Object {
        $_.Name -ne 'skills-unifier.state.json' -and $_.Name -ne 'captures'
    }

    foreach ($item in $items) {
        $null = Copy-Item -LiteralPath $item.FullName -Destination $TargetRoot -Recurse -Force
    }
}

function Invoke-SkillsUnifierInstall {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$SourcePath,
        [Parameter(Mandatory = $true)]
        [string[]]$TargetRoots
    )

    $resolvedSource = ConvertTo-SkillsUnifierFullPath -Path $SourcePath
    if (-not (Test-Path -LiteralPath $resolvedSource)) {
        throw "Source path not found: $resolvedSource"
    }

    $results = New-Object System.Collections.Generic.List[object]

    foreach ($targetRootRaw in $TargetRoots) {
        $targetRoot = ConvertTo-SkillsUnifierFullPath -Path $targetRootRaw
        $targetParent = Split-Path -Parent $targetRoot
        $backupPath = Get-SkillsUnifierBackupPath -TargetRoot $targetRoot

        $null = New-Item -ItemType Directory -Path $targetParent -Force

        if (Test-SkillsUnifierJunctionTarget -TargetRoot $targetRoot -SourcePath $resolvedSource) {
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
                Move-SkillsUnifierDirectoryToBackup -TargetRoot $targetRoot -BackupPath $backupPath
            }
        }

        $null = New-Item -ItemType Junction -Path $targetRoot -Target $resolvedSource
        Write-SkillsUnifierMarker -BackupPath $backupPath -TargetRoot $targetRoot -SourcePath $resolvedSource

        $results.Add([pscustomobject]@{
            TargetPath = $targetRoot
            Action     = 'Installed'
            Details    = $resolvedSource
        })
    }

    return $results
}

function Invoke-SkillsUnifierRollback {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$TargetRoots
    )

    $results = New-Object System.Collections.Generic.List[object]

    foreach ($targetRootRaw in $TargetRoots) {
        $targetRoot = ConvertTo-SkillsUnifierFullPath -Path $targetRootRaw
        $backupPath = Get-SkillsUnifierBackupPath -TargetRoot $targetRoot
        $marker = Read-SkillsUnifierMarker -BackupPath $backupPath

        if (-not $marker) {
            $results.Add([pscustomobject]@{
                TargetPath = $targetRoot
                Action     = 'Skipped'
                Details    = 'No managed backup marker found'
            })
            continue
        }

        if (Test-Path -LiteralPath $targetRoot) {
            $item = Get-Item -LiteralPath $targetRoot -Force
            if ($item.Attributes.HasFlag([System.IO.FileAttributes]::ReparsePoint)) {
                $null = Remove-Item -LiteralPath $targetRoot -Force
            }
            else {
                $capturesRoot = Join-Path $backupPath 'captures'
                $null = New-Item -ItemType Directory -Path $capturesRoot -Force
                $capturePath = Join-Path $capturesRoot ('rollback-' + (Get-SkillsUnifierTimestamp))
                $null = Move-Item -LiteralPath $targetRoot -Destination $capturePath
            }
        }

        Copy-SkillsUnifierSnapshotToTarget -BackupPath $backupPath -TargetRoot $targetRoot

        $results.Add([pscustomobject]@{
            TargetPath = $targetRoot
            Action     = 'Restored'
            Details    = $backupPath
        })
    }

    return $results
}

Export-ModuleMember -Function Invoke-SkillsUnifierInstall, Invoke-SkillsUnifierRollback
