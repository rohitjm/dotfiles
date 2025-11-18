
echo "Loaded TMUX config!!"

alias txsess="$DOTFILE_HOME/tmux/tmux-session.sh"
alias tx="tmux"
alias txa="tmux attach -t"
alias txls="tmux ls"
alias txn="tmux new -s"
alias txk="tmux kill-session -t"
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

