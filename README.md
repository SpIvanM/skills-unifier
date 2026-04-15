# Skills Unifier

Centralized management of `skills` for multiple AI tools on Windows.
Централизованное управление `skills` для нескольких AI-инструментов на Windows.

[Русская версия](#русская-версия) | [English version](#english-version)

## At a glance

- One source of truth via `SourcePath`.
- Allowlist-only targeting from [config/known-locations.psd1](config/known-locations.psd1).
- `skills` is replaced with a `Junction`.
- Local data is preserved in `skills-backup`.
- Re-running the scripts is safe.
- Final validation uses Pester.

## Platform support / Поддержка платформ

Windows 10/11 is the only supported runtime. macOS and Linux are documentation-only.
Windows 10/11 - единственная поддерживаемая среда выполнения. macOS и Linux - только для чтения документации.

| OS | Status | Installation and use |
| --- | --- | --- |
| Windows 10/11 | Supported | Install PowerShell 5.1 or PowerShell 7, then use the commands in the sections below. |
| macOS | Not supported | You can clone the repository and read the docs, but the automation does not run here. |
| Linux | Not supported | You can clone the repository and read the docs, but the automation does not run here. |

The scripts rely on Windows paths and NTFS `Junction`, so there is no safe cross-platform install path.
Скрипты завязаны на Windows-пути и NTFS `Junction`, поэтому безопасного кроссплатформенного сценария установки нет.

<details open>
<summary>Русская версия</summary>

### Что входит
- [scripts/SkillsUnifier.psm1](scripts/SkillsUnifier.psm1) - общая логика установки и rollback.
- [scripts/install-skills.ps1](scripts/install-skills.ps1) - универсальный установщик.
- [scripts/rollback-skills.ps1](scripts/rollback-skills.ps1) - откат изменений.
- [config/known-locations.psd1](config/known-locations.psd1) - allowlist известных мест установки.
- [private/](private/) - локальные обертки, которые не публикуются в GitHub.
- [tests/final/SkillsUnifier.Final.Tests.ps1](tests/final/SkillsUnifier.Final.Tests.ps1) - финальные тесты.

### Быстрый старт
```powershell
.\scripts\install-skills.ps1 -SourcePath 'C:\Path\To\skills'
.\scripts\rollback-skills.ps1
Invoke-Pester -Path .\tests\final\SkillsUnifier.Final.Tests.ps1 -EnableExit
```

### Полезные параметры
- `-KnownLocationsPath` - альтернативный список разрешенных мест.
- `-RemoveBackup` - удалить backup после отката.
- `-WhatIf` и `-Confirm` - поддерживаются обоими скриптами.

### Поддерживаемые места
Скрипты работают только по allowlist из [config/known-locations.psd1](config/known-locations.psd1):

- `~/.claude/skills`
- `~/.windsurf/skills`
- `~/.codex/skills`
- `~/.github/skills`
- `~/.gemini/skills`
- `~/.opencode/skills`
- `~/.gemini/antigravity/skills`

### Поведение
- Если `skills` уже указывает на нужный source, путь пропускается.
- Если `skills` является обычной папкой, она уходит в `skills-backup`.
- Если `skills-backup` уже существует, управление переходит в snapshot-режим внутри `.skills-unifier`.
- Rollback восстанавливает только те места, где найдено управляемое состояние.
- Повторный запуск обновляет уже известные места и не ломает их состояние.

### Документация
- [ARCHITECTURE.md](ARCHITECTURE.md) - принятые архитектурные решения.
- [ts.md](ts.md) - актуализированное техническое задание.
- [done.md](done.md) - журнал выполненных работ.

</details>

<details>
<summary>English version</summary>

### What's included
- [scripts/SkillsUnifier.psm1](scripts/SkillsUnifier.psm1) - shared install and rollback logic.
- [scripts/install-skills.ps1](scripts/install-skills.ps1) - universal installer.
- [scripts/rollback-skills.ps1](scripts/rollback-skills.ps1) - rollback script.
- [config/known-locations.psd1](config/known-locations.psd1) - allowlist of known install locations.
- [private/](private/) - local wrappers that are not published to GitHub.
- [tests/final/SkillsUnifier.Final.Tests.ps1](tests/final/SkillsUnifier.Final.Tests.ps1) - final test suite.

### Quick start
```powershell
.\scripts\install-skills.ps1 -SourcePath 'C:\Path\To\skills'
.\scripts\rollback-skills.ps1
Invoke-Pester -Path .\tests\final\SkillsUnifier.Final.Tests.ps1 -EnableExit
```

### Useful parameters
- `-KnownLocationsPath` - alternate allowlist of locations.
- `-RemoveBackup` - delete the backup after rollback.
- `-WhatIf` and `-Confirm` - supported by both scripts.

### Supported locations
The scripts only operate on the allowlist in [config/known-locations.psd1](config/known-locations.psd1):

- `~/.claude/skills`
- `~/.windsurf/skills`
- `~/.codex/skills`
- `~/.github/skills`
- `~/.gemini/skills`
- `~/.opencode/skills`
- `~/.gemini/antigravity/skills`

### Behavior
- If `skills` already points to the requested source, the path is skipped.
- If `skills` is a normal folder, it is moved to `skills-backup`.
- If `skills-backup` already exists, management switches to snapshot mode inside `.skills-unifier`.
- Rollback restores only locations with managed state.
- Re-running the scripts updates known locations without breaking existing state.

### Documentation
- [ARCHITECTURE.md](ARCHITECTURE.md) - architecture decisions.
- [ts.md](ts.md) - updated technical specification.
- [done.md](done.md) - work log.

</details>
