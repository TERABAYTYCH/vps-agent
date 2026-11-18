# vps-agent

Claude Code на своём VPS одной командой — чтобы агент работал, когда ваш компьютер выключен, а писали вы ему с телефона.

- Ubuntu 20.04+ / Debian, 4 ГБ памяти, под root. VPS — в стране из списка https://www.anthropic.com/supported-countries
- Подписка Claude Pro, Max или выше (Team/Enterprise — если владелец включил Remote Control). По API-ключу Remote Control не работает.

```bash
sudo -i   # если вы зашли не под root
curl -fsSL https://raw.githubusercontent.com/TERABAYTYCH/vps-agent/main/setup.sh | bash
```

Не запускайте как `curl … | sudo bash` — сначала `sudo -i`.

## Что делает скрипт

1. Ставит `tmux`, `curl`, `python3` (apt) и Claude Code официальным установщиком Anthropic, дописывает PATH в `~/.bashrc`.
2. Включает Remote Control для всех запусков — один ключ `remoteControlAtStartup` в `~/.claude/settings.json` (старый файл — в `settings.json.bak`).
3. Просит войти в аккаунт Claude (`claude auth login`). Как устроен вход: https://code.claude.com/docs/en/authentication
4. Запускает `claude --remote-control main` внутри `tmux` в папке `~/work` и открывает его вам.

Больше ничего. Прочитайте `setup.sh` перед запуском — он короткий.

`tmux` нужен, потому что Claude Code живёт, пока открыт терминал: `tmux` держит терминал на сервере, даже когда вы отключились.

**Выйти, не убивая Claude: `Ctrl+B`, затем `D`.** Не набирайте `/exit` и не жмите `Ctrl+C`. Вернуться: `tmux attach -t claude`.

Сессия «main» — в приложении Claude (вкладка Code) или на claude.ai/code. Подробнее о Remote Control: https://code.claude.com/docs/en/remote-control

## Перезагрузка, остановка, удаление

- После перезагрузки сервера запустите ту же команду — она поднимет сессию заново.
- Остановить: `tmux kill-session -t claude`.
- Удалить Claude Code: `rm -f ~/.local/bin/claude; rm -rf ~/.local/share/claude`.

## Безопасность

Агент работает под root и может всё на этом сервере: не держите на нём чужих ключей и боевых проектов.
Доступ к вашему аккаунту Claude = доступ к серверу: включите двухфакторный вход.
