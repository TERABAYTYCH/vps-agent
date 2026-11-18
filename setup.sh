#!/bin/bash
# Claude Code на VPS одной командой: tmux + Claude Code + Remote Control. Ubuntu/Debian, под root.
#   curl -fsSL https://raw.githubusercontent.com/TERABAYTYCH/vps-agent/main/setup.sh | bash
# Повторный запуск безопасен: уже установленное пропускается, живая сессия не пересоздаётся.
set -eo pipefail

main() {
  local WORKDIR="$HOME/work"
  local HINT="Выйти, не убивая Claude: Ctrl+B, затем D"

  [ "$(id -u)" = 0 ] || { echo "Запустите под root: sudo -i, затем эту команду ещё раз."; exit 1; }

  echo "== Ставлю tmux, curl, python3"
  export DEBIAN_FRONTEND=noninteractive NEEDRESTART_MODE=a
  apt-get -o DPkg::Lock::Timeout=300 update -qq </dev/null
  apt-get -o DPkg::Lock::Timeout=300 install -y -qq tmux curl python3 </dev/null

  echo "== Ставлю Claude Code (официальный установщик Anthropic)"
  export PATH="$HOME/.local/bin:$PATH"
  if ! command -v claude >/dev/null; then
    curl -fsSL https://claude.ai/install.sh | CLAUDE_INSTALL_ALLOW_SUDO=1 bash </dev/null
  fi
  command -v claude >/dev/null || {
    echo "Claude Code не установился. Проверьте сеть и страну VPS: https://www.anthropic.com/supported-countries"
    exit 1
  }
  grep -qs '.local/bin' ~/.bashrc || echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
  local CLAUDE_BIN
  CLAUDE_BIN="$(command -v claude)"

  echo "== Включаю Remote Control для всех запусков (remoteControlAtStartup)"
  mkdir -p "$WORKDIR" ~/.claude
  python3 - <<'PY'
import json, os, shutil, sys
p = os.path.expanduser("~/.claude/settings.json")
data = {}
if os.path.exists(p):
    try:
        with open(p, encoding="utf-8") as f:
            data = json.load(f)
    except ValueError:
        sys.exit("~/.claude/settings.json повреждён — исправьте его и запустите скрипт снова")
    if not isinstance(data, dict):
        sys.exit("~/.claude/settings.json должен быть JSON-объектом { … }")
    if data.get("remoteControlAtStartup") is True:
        sys.exit(0)
    shutil.copy2(p, p + ".bak")
data["remoteControlAtStartup"] = True
tmp = p + ".tmp"
with open(tmp, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
os.replace(tmp, p)
PY

  if ! { : </dev/tty; } 2>/dev/null || [ -n "${TMUX:-}" ]; then
    echo "Нет интерактивного терминала. Войдите сами: claude auth login, затем запустите эту команду ещё раз."
    exit 0
  fi

  if ! claude auth status --json 2>/dev/null | grep -q '"loggedIn": *true'; then
    echo
    echo "== Вход в аккаунт Claude (подписка Pro, Max или выше)"
    echo "Откройте ссылку на своём компьютере, войдите, код со страницы вставьте сюда."
    claude auth login --claudeai </dev/tty
  fi

  if ! tmux has-session -t '=claude' 2>/dev/null; then
    tmux -u new -d -s claude -c "$WORKDIR" "$CLAUDE_BIN --remote-control main; exec bash"
    tmux set -t '=claude' status-right " $HINT " >/dev/null
    tmux set -t '=claude' status-right-length 60 >/dev/null
  fi

  cat <<MSG

Готово. Сейчас откроется Claude внутри tmux:
  1. Тема оформления — Enter.
  2. Доверяете папке — да. Enable Remote Control — да.
  3. Если внизу нет «Remote Control» — наберите /remote-control main
  4. $HINT
     Не набирайте /exit и не жмите Ctrl+C — это закроет Claude.
Вернуться позже: tmux attach -t claude
Сессия «main» — в приложении Claude (вкладка Code) или на claude.ai/code.

Нажмите Enter, чтобы открыть Claude.
MSG
  read -r _ </dev/tty
  exec tmux -u attach -t '=claude' </dev/tty
}

main "$@"
