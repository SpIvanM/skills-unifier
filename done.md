# Done

## Что сделано

- [x] Активирован git и создан локальный репозиторий.
- [x] Подготовлен `README.md` с описанием проблемы, решения и способов запуска.
- [x] Добавлена лицензия `MIT`.
- [x] Репозиторий опубликован как публичный на GitHub.
- [x] Актуализировано техническое задание в `ts.md`.
- [x] Зафиксирована архитектура решения в `ARCHITECTURE.md`.
- [x] Собран и проверен PoC-набор скриптов.
- [x] Собран и проверен финальный набор скриптов.
- [x] Актуализирована документация проекта.
- [x] Персональные wrapper-скрипты вынесены в `private/`, который игнорируется git.

## Реализованные файлы

- [README.md](README.md)
- [LICENSE](LICENSE)
- [ts.md](ts.md)
- [ARCHITECTURE.md](ARCHITECTURE.md)
- [config/known-locations.psd1](config/known-locations.psd1)
- [scripts/SkillsUnifier.psm1](scripts/SkillsUnifier.psm1)
- [scripts/install-skills.ps1](scripts/install-skills.ps1)
- [scripts/rollback-skills.ps1](scripts/rollback-skills.ps1)
- [scripts/poc/SkillsUnifier.Poc.psm1](scripts/poc/SkillsUnifier.Poc.psm1)
- [scripts/poc/install-skills-poc.ps1](scripts/poc/install-skills-poc.ps1)
- [scripts/poc/rollback-skills-poc.ps1](scripts/poc/rollback-skills-poc.ps1)
- [tests/poc/SkillsUnifier.Poc.Tests.ps1](tests/poc/SkillsUnifier.Poc.Tests.ps1)
- [tests/final/SkillsUnifier.Final.Tests.ps1](tests/final/SkillsUnifier.Final.Tests.ps1)

## Проверки

- `Invoke-Pester -Path .\tests\poc\SkillsUnifier.Poc.Tests.ps1 -EnableExit`
  - результат: `4 passed, 0 failed`
- `Invoke-Pester -Path .\tests\final\SkillsUnifier.Final.Tests.ps1 -EnableExit`
  - результат: `4 passed, 0 failed`

## Что важно

- Установка работает только по allowlist известных мест.
- `skills` переводится на `Junction` к единому `SourcePath`.
- Исходные данные сохраняются в `skills-backup`.
- Rollback восстанавливает только управляемые каталоги.
- Решение повторно запускается без поломки уже настроенных мест.

## Итог

Проект доведен до состояния, в котором есть:

- формализованное ТЗ;
- зафиксированная архитектура;
- PoC-реализация;
- финальная реализация;
- тестовое покрытие;
- документация;
- журнал выполненных работ.

