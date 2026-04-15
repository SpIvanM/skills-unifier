# Skills Unifier

Централизованное управление папкой `skills` для нескольких AI-инструментов на Windows.
Centralized management of the `skills` folder for multiple AI tools on Windows.

## Русская версия

### Что входит
- [scripts/SkillsUnifier.psm1](scripts/SkillsUnifier.psm1) - общая логика установки и rollback.
- [scripts/install-skills.ps1](scripts/install-skills.ps1) - универсальный установщик.
- [scripts/rollback-skills.ps1](scripts/rollback-skills.ps1) - откат изменений.
- [config/known-locations.psd1](config/known-locations.psd1) - allowlist известных мест установки.
- [private/](private/) - локальные обертки, которые не публикуются в GitHub.
- [tests/final/SkillsUnifier.Final.Tests.ps1](tests/final/SkillsUnifier.Final.Tests.ps1) - финальные тесты.

### Проблема
У каждого AI-agent инструмента свой путь к `skills`. В итоге:

- обновления приходится делать вручную в нескольких местах;
- источники быстро расходятся по версиям;
- сложно понять, где лежит актуальная копия;
- откат становится рискованным.

### Решение
Скрипты проекта:

- работают только по заранее известным и разрешенным путям;
- сохраняют локальную папку `skills` в `skills-backup`;
- создают `Junction` на единый источник;
- безопасно повторяются;
- умеют откатывать изменения назад;
- поддерживают snapshot-режим, если `skills-backup` уже занят.

### Запуск

#### Универсальная установка
```powershell
.\scripts\install-skills.ps1 -SourcePath 'C:\Path\To\skills'
```

#### Установка с альтернативным списком мест
```powershell
.\scripts\install-skills.ps1 -SourcePath 'C:\Path\To\skills' -KnownLocationsPath 'C:\Path\To\known-locations.psd1'
```

#### Откат
```powershell
.\scripts\rollback-skills.ps1
```

#### Откат с удалением backup
```powershell
.\scripts\rollback-skills.ps1 -RemoveBackup
```

#### Локальная обертка
Если нужен локальный wrapper с жестко заданным source path, храните его в `private/` и запускайте оттуда.

Оба скрипта поддерживают `-WhatIf` и `-Confirm`.

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

### Проверка
Финальные тесты запускаются через Pester:

```powershell
Invoke-Pester -Path .\tests\final\SkillsUnifier.Final.Tests.ps1 -EnableExit
```

### Документация
- [ARCHITECTURE.md](ARCHITECTURE.md) - принятые архитектурные решения.
- [ts.md](ts.md) - актуализированное техническое задание.
- [done.md](done.md) - журнал выполненных работ.

## English version

### What's included
- [scripts/SkillsUnifier.psm1](scripts/SkillsUnifier.psm1) - shared install and rollback logic.
- [scripts/install-skills.ps1](scripts/install-skills.ps1) - universal installer.
- [scripts/rollback-skills.ps1](scripts/rollback-skills.ps1) - rollback script.
- [config/known-locations.psd1](config/known-locations.psd1) - allowlist of known install locations.
- [private/](private/) - local wrappers that are not published to GitHub.
- [tests/final/SkillsUnifier.Final.Tests.ps1](tests/final/SkillsUnifier.Final.Tests.ps1) - final test suite.

### Problem
Every AI tool keeps its own `skills` path. That leads to:

- manual updates in multiple places;
- version drift across tools;
- unclear source of truth;
- risky rollback.

### Solution
The project scripts:

- only touch pre-approved locations;
- preserve the local `skills` folder in `skills-backup`;
- create a `Junction` to a single source of truth;
- are safe to run repeatedly;
- can roll changes back cleanly;
- fall back to snapshot mode when `skills-backup` already exists.

### Usage

#### Universal install
```powershell
.\scripts\install-skills.ps1 -SourcePath 'C:\Path\To\skills'
```

#### Install with a custom location list
```powershell
.\scripts\install-skills.ps1 -SourcePath 'C:\Path\To\skills' -KnownLocationsPath 'C:\Path\To\known-locations.psd1'
```

#### Rollback
```powershell
.\scripts\rollback-skills.ps1
```

#### Rollback and remove the backup
```powershell
.\scripts\rollback-skills.ps1 -RemoveBackup
```

#### Local wrapper
If you need a local wrapper with a hardcoded source path, keep it in `private/` and run it from there.

Both scripts support `-WhatIf` and `-Confirm`.

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

### Validation
Final tests run through Pester:

```powershell
Invoke-Pester -Path .\tests\final\SkillsUnifier.Final.Tests.ps1 -EnableExit
```

### Documentation
- [ARCHITECTURE.md](ARCHITECTURE.md) - architecture decisions.
- [ts.md](ts.md) - updated technical specification.
- [done.md](done.md) - work log.
