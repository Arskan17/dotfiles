# Managed by https://github.com/Arskan17/dotfiles - history + suggestions config.
# Sourced from ~/.bashrc (bottom block). Edits here are overwritten by install.sh.

# ~/.local/bin holds the fzf binary when it was installed without a package manager
case ":$PATH:" in
  *":$HOME/.local/bin:"*) ;;
  *) PATH="$HOME/.local/bin:$PATH" ;;
esac

# --- History: large, timestamped, shared across sessions ---
HISTCONTROL=ignoreboth
HISTSIZE=100000
HISTFILESIZE=200000
HISTTIMEFORMAT='%F %T '
shopt -s histappend
case "${PROMPT_COMMAND-}" in
  *"history -a"*) ;;
  *) PROMPT_COMMAND="history -a${PROMPT_COMMAND:+; $PROMPT_COMMAND}" ;;
esac

# --- fzf: Ctrl-R fuzzy history, Ctrl-T file picker, Alt-C cd ---
if command -v fzf >/dev/null 2>&1; then
  if fzf --bash >/dev/null 2>&1; then
    eval "$(fzf --bash)"
  else
    for _f in /usr/share/doc/fzf/examples/key-bindings.bash \
              /usr/share/fzf/key-bindings.bash \
              /usr/share/fzf/shell/key-bindings.bash; do
      [ -f "$_f" ] && { . "$_f"; break; }
    done
    unset _f
  fi
fi
