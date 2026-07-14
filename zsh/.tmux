
echo "Loaded TMUX config!!"

alias txsess="$DOTFILE_HOME/tmux/tmux-session.sh"

# Kick off the hourly session autosave for the running tmux server. The loop is
# guarded (one per server) and detached so it keeps saving after this shell
# exits; harmless no-op when no server is running.
(nohup "$HOME/Dev/dotfiles/tmux/tmux-autosave.sh" >/dev/null 2>&1 &) 2>/dev/null
alias tx="tmux"
alias txa="tmux attach -t"
alias txls="tmux ls"
alias txn="tmux new -s"
alias txk="tmux kill-session -t"

# nw <name>: start a new workstream. Creates a tmux session and a cmux
# workspace both named <name>, with the cmux workspace attached to the
# session.
nw() {
  if [ -z "$1" ]; then
    echo "Usage: nw <workstream-name>" >&2
    return 1
  fi
  local name="$1"

  # Inside tmux, cmux's per-surface socket credentials aren't in our env
  # (tmux only forwards an allowlist), so the cmux CLI can't reach the app.
  # Recover them from the tmux session env, which .tmux.conf's
  # update-environment repopulates on each attach.
  if [ -n "$TMUX" ]; then
    local var val
    for var in CMUX_SOCKET_PASSWORD CMUX_WORKSPACE_ID CMUX_SURFACE_ID; do
      [ -n "${(P)var}" ] && continue
      val="$(tmux show-environment "$var" 2>/dev/null)"
      [ "${val%%=*}" = "$var" ] && export "$var=${val#*=}"
    done
    [ -z "$CMUX_SOCKET_PASSWORD" ] && echo "nw: no cmux socket creds in tmux env; detach and re-attach this session once from a cmux tab so they propagate." >&2
  fi

  # Reuse the tmux session if it already exists, else create it detached.
  tmux has-session -t "=$name" 2>/dev/null || tmux new-session -d -s "$name"
  # Open a cmux workspace whose terminal attaches to that session.
  cmux new-workspace --name "$name" --focus true --command "tmux attach -t $name"
}
alias tmux-grid='
session=$(tmux display-message -p "#S"); \
first_window=$(tmux list-windows -F "#{window_index}" -t "$session" | head -n1); \
first_name=$(tmux list-windows -F "#{window_name}" -t "${session}:${first_window}"); \
tmux rename-window -t "${session}:${first_window}" "Grid"; \
# Set first window pane title
tmux select-pane -t "${session}:${first_window}.0" -T "$first_name"; \
for win in $(tmux list-windows -F "#{window_index}" -t "$session"); do \
  if [[ "$win" != "$first_window" ]]; then \
    win_name=$(tmux list-windows -F "#{window_name}" -t "${session}:${win}"); \
    tmux join-pane -s "${session}:${win}" -t "${session}:${first_window}" -d; \
    last_pane=$(tmux list-panes -t "${session}:${first_window}" -F "#{pane_index}" | tail -n1); \
    tmux select-pane -t "${session}:${first_window}.${last_pane}" -T "$win_name"; \
    tmux kill-window -t "${session}:${win}"; \
  fi; \
done; \
tmux select-layout -t "${session}:${first_window}" tiled
'
alias tmux-ungird='
session=$(tmux display-message -p "#S"); \
grid_window=$(tmux display-message -p "#{window_index}"); \
for pane in $(tmux list-panes -t "${session}:${grid_window}" -F "#{pane_index}"); do \
  pane_title=$(tmux display-message -p -t "${session}:${grid_window}.${pane}" "#{pane_title}"); \
  tmux break-pane -s "${session}:${grid_window}.${pane}" -n "$pane_title"; \
done; \
tmux kill-window -t "${session}:${grid_window}"
'

