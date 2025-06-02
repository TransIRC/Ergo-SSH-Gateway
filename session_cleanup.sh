#!/bin/bash

while true; do
  tmux_sessions=$(tmux list-sessions -F "#{session_name}" 2>/dev/null)
  readarray -t session_array <<<"$tmux_sessions"

  session_exists() {
    local session="$1"
    for s in "${session_array[@]}"; do
      if [[ "$s" == "$session" ]]; then
        return 0
      fi
    done
    return 1
  }

  for dir in /mnt/sessions/*; do
    [[ -d "$dir" ]] || continue
    session_name=$(basename "$dir")

    if ! session_exists "$session_name"; then
      echo "Removing stale session folder: $dir"
      rm -rf "$dir"
    fi
  done

  sleep 10
done
