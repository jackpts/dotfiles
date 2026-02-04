export PNPM_HOME="$HOME/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;; 
  *) export PATH="$PNPM_HOME:$PATH" ;;
 esac

export HISTSIZE=-1
export HISTFILESIZE=-1
export HISTCONTROL=ignoreboth

export TERMINAL="kitty"
export XDG_DATA_HOME="$HOME/.local/share"

export OLLAMA_API_BASE="http://127.0.0.1:11434"
export AIDER_DARK_MODE="true"

export VISUAL="nvim"
export EDITOR="$VISUAL"
export BROWSER="zen"

case ":$PATH:" in
  *":/opt/nvim-linux64/bin:"*) ;;
  *) export PATH="/opt/nvim-linux64/bin:$PATH" ;;
 esac

case ":$PATH:" in
  *":$HOME/.volta/bin:"*) ;;
  *) export PATH="$HOME/.volta/bin:$PATH" ;;
 esac

export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"
export TERM_EMULATOR="kitty"
export TERM="xterm-kitty"

export XDG_SCREENSHOTS_DIR="$HOME/Pictures/Screenshots"
export MANPAGER='nvim +Man!'
