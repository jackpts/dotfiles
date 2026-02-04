export FZF_DEFAULT_COMMAND="fd --hidden --strip-cwd-prefix --exclude .git"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND="fd --type=d --hidden --strip-cwd-prefix --exclude .git"
export FZF_CTRL_T_OPTS="--preview 'bat -n --color=always --line-range :500 {}'"
export FZF_ALT_C_OPTS="--preview 'eza --tree --color=always {} | head -200'"

_fzf_compgen_path() {
  fd --hidden --exclude .git . "$1"
}

_fzf_comprun() {
  local command="$1"
  shift

  case "$command" in
    cd) fzf --preview 'eza --tree --color=always {} | head -200' "$@" ;;
    ssh) fzf --preview "eval 'echo \$' {}" "$@" ;;
    *) fzf --preview "bat -n --color=always --line-range :500 {}" "$@" ;;
  esac
}

if command -v yay >/dev/null 2>&1; then
  aurhelper=yay
elif command -v paru >/dev/null 2>&1; then
  aurhelper=paru
fi

if [[ -n "${aurhelper:-}" ]]; then
  alias un='${aurhelper} -Rns'
  alias u2='${aurhelper} -Suyy --noconfirm'
fi

alias q_start='quickshell -p "$HOME/dotfiles/.config/quickshell/jackbar"'

q_reload() {
  quickshell kill -p "$HOME/dotfiles/.config/quickshell/jackbar" || true
  local i
  for i in {1..50}; do
    quickshell list -p "$HOME/dotfiles/.config/quickshell/jackbar" >/dev/null 2>&1 || break
    sleep 0.1
  done
  quickshell -d -n -p "$HOME/dotfiles/.config/quickshell/jackbar"
}

q_reload_dbg() {
  quickshell kill -p "$HOME/dotfiles/.config/quickshell/jackbar" || true
  local i
  for i in {1..50}; do
    quickshell list -p "$HOME/dotfiles/.config/quickshell/jackbar" >/dev/null 2>&1 || break
    sleep 0.1
  done
  QS_PANEL_DEBUG=1 quickshell -d -n -p "$HOME/dotfiles/.config/quickshell/jackbar" -vv
}

alias q_reload='q_reload'
alias q_reload_dbg='q_reload_dbg'
