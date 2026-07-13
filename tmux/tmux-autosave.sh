#!/usr/bin/env bash
# Periodically run `tmux-session.sh save` so `txsess restore` stays current.
#
# One loop runs per tmux server: it saves the session layout, waits an hour,
# and repeats for as long as the server is alive, then exits. A server-scoped
# PID guard (@autosave-pid) keeps duplicate loops from piling up, so this can
# be started freely from both .tmux.conf (fresh servers) and zsh/.tmux
# (already-running servers) without spawning more than one saver.
#
# Override the cadence with TMUX_AUTOSAVE_INTERVAL (seconds).

INTERVAL="${TMUX_AUTOSAVE_INTERVAL:-3600}"
SAVE="$(cd "$(dirname "$0")" && pwd)/tmux-session.sh"

# Nothing to save without a running server.
tmux list-sessions >/dev/null 2>&1 || exit 0

# Guard: bail out if a live autosave loop already owns this server.
existing="$(tmux show-option -gqv @autosave-pid 2>/dev/null)"
if [[ -n "$existing" ]] && kill -0 "$existing" 2>/dev/null; then
  exit 0
fi
tmux set-option -g @autosave-pid "$$" 2>/dev/null || exit 0

while tmux list-sessions >/dev/null 2>&1; do
  # Step aside if another loop took ownership (e.g. after a server restart).
  [[ "$(tmux show-option -gqv @autosave-pid 2>/dev/null)" == "$$" ]] || exit 0
  "$SAVE" save >/dev/null 2>&1 || true
  sleep "$INTERVAL"
done
