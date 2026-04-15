# Skills Unifier

Централизованное управление папкой `skills` для нескольких AI-инструментов на Windows.

Проект заменяет локальные папки `skills` на ссылку к единому источнику и сохраняет исходные данные в `skills-backup` с возможностью отката.

## Что входит

- [scripts/SkillsUnifier.psm1](scripts/SkillsUnifier.psm1) - общая логика установки и rollback.
- [scripts/install-skills.ps1](scripts/install-skills.ps1) - универсальный установщик.
- [scripts/rollback-skills.ps1](scripts/rollback-skills.ps1) - откат изменений.
- [config/known-locations.psd1](config/known-locations.psd1) - allowlist известных мест установки.
- [private/](private/) - локальные обертки, которые не публикуются в GitHub.
- [tests/poc/SkillsUnifier.Poc.Tests.ps1](tests/poc/SkillsUnifier.Poc.Tests.ps1) - PoC-проверка.
- [tests/final/SkillsUnifier.Final.Tests.ps1](tests/final/SkillsUnifier.Final.Tests.ps1) - финальные тесты.

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
.\scripts\install-skills.ps1 -SourcePath 'C:\Path\To\skills'
```

### Откат

```powershell
.\scripts\rollback-skills.ps1
```

Удалить `skills-backup` после восстановления:

```powershell
.\scripts\rollback-skills.ps1 -RemoveBackup
```

### Локальная обертка

Если нужен локальный wrapper с жестко заданным source path, храните его в `private/` и запускайте оттуда.

## Поддерживаемые места

Скрипты работают только по allowlist из [config/known-locations.psd1](config/known-locations.psd1):

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

- [ARCHITECTURE.md](ARCHITECTURE.md) - принятые архитектурные решения.
- [ts.md](ts.md) - актуализированное техническое задание.
- [done.md](done.md) - журнал выполненных работ.
