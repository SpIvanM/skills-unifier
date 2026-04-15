# Skills Unifier

Централизованное управление папкой `skills` для нескольких AI-инструментов на Windows.

Проект заменяет локальные папки `skills` на ссылку к единому источнику и сохраняет исходные данные в `skills-backup` с возможностью отката.

## Что входит

- [scripts/SkillsUnifier.psm1](/c:/Users/ivanm/Documents/Projects/skills-unifier/scripts/SkillsUnifier.psm1) - общая логика установки и rollback.
- [scripts/install-skills.ps1](/c:/Users/ivanm/Documents/Projects/skills-unifier/scripts/install-skills.ps1) - универсальный установщик.
- [scripts/install-skills-iam.ps1](/c:/Users/ivanm/Documents/Projects/skills-unifier/scripts/install-skills-iam.ps1) - обертка для источника `c:\Users\ivanm\Documents\MD\Technology\iam-skills\skills`.
- [scripts/rollback-skills.ps1](/c:/Users/ivanm/Documents/Projects/skills-unifier/scripts/rollback-skills.ps1) - откат изменений.
- [config/known-locations.psd1](/c:/Users/ivanm/Documents/Projects/skills-unifier/config/known-locations.psd1) - allowlist известных мест установки.
- [tests/poc/SkillsUnifier.Poc.Tests.ps1](/c:/Users/ivanm/Documents/Projects/skills-unifier/tests/poc/SkillsUnifier.Poc.Tests.ps1) - PoC-проверка.
- [tests/final/SkillsUnifier.Final.Tests.ps1](/c:/Users/ivanm/Documents/Projects/skills-unifier/tests/final/SkillsUnifier.Final.Tests.ps1) - финальные тесты.

## Проблема

У каждого AI-агента или CLI-инструмента свой путь к `skills`. В итоге:

- обновления приходится делать вручную в нескольких местах;
- источники быстро расходятся по версиям;
- сложно понять, где лежит актуальная копия;
- откат становится рискованным.

## Решение

Скрипты проекта:

- работают только по заранее известным и разрешенным путям;
- сохраняют локальную папку `skills` в `skills-backup`;
- создают `Junction` на единый источник;
- безопасно повторяются;
- умеют откатывать изменения назад.

## Запуск

### Универсальная установка

```powershell
.\scripts\install-skills.ps1 -SourcePath 'c:\Users\ivanm\Documents\MD\Technology\iam-skills\skills'
```

Если нужен альтернативный allowlist-файл:

```powershell
.\scripts\install-skills.ps1 -SourcePath 'c:\Users\ivanm\Documents\MD\Technology\iam-skills\skills' -KnownLocationsPath .\config\known-locations.psd1
```

### Обертка для IAM source

```powershell
.\scripts\install-skills-iam.ps1
```

При необходимости можно передать альтернативный allowlist:

```powershell
.\scripts\install-skills-iam.ps1 -KnownLocationsPath .\config\known-locations.psd1
```

### Откат

```powershell
.\scripts\rollback-skills.ps1
```

Удалить `skills-backup` после восстановления:

```powershell
.\scripts\rollback-skills.ps1 -RemoveBackup
```

## Поддерживаемые места

Скрипты работают только по allowlist из [config/known-locations.psd1](/c:/Users/ivanm/Documents/Projects/skills-unifier/config/known-locations.psd1):

- `~/.claude/skills`
- `~/.windsurf/skills`
- `~/.codex/skills`
- `~/.github/skills`
- `~/.gemini/skills`
- `~/.opencode/skills`
- `~/.gemini/antigravity/skills`

## Поведение

- Если `skills` уже указывает на нужный source, путь пропускается.
- Если `skills` является обычной папкой, она уходит в `skills-backup`.
- Если `skills-backup` уже существует, управление переходит в snapshot-режим внутри `.skills-unifier`.
- Rollback восстанавливает только те места, где найдено управляемое состояние.
- Повторный запуск обновляет уже известные места и не ломает их состояние.

## Проверка

PoC и финальные тесты запускаются через Pester:

```powershell
Invoke-Pester -Path .\tests\poc\SkillsUnifier.Poc.Tests.ps1 -EnableExit
Invoke-Pester -Path .\tests\final\SkillsUnifier.Final.Tests.ps1 -EnableExit
```

## Документация

- [ARCHITECTURE.md](/c:/Users/ivanm/Documents/Projects/skills-unifier/ARCHITECTURE.md) - принятые архитектурные решения.
- [ts.md](/c:/Users/ivanm/Documents/Projects/skills-unifier/ts.md) - актуализированное техническое задание.

