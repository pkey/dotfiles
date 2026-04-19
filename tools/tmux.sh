# Auto-launch tmux for interactive shells
if command -v tmux &> /dev/null && [ -z "$TMUX" ] && [[ $- == *i* ]]; then
    tmux attach -t default 2>/dev/null || tmux new -s default
fi
