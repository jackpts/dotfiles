# 00-env.fish
# Loaded early. Environment variables, universal vars and PATH.

# Theme (kept commented for reference)
# set -g theme_display_git yes
# set -g theme_display_git_untracked yes
# set -g theme_display_git_master_branch yes
# set -g theme_title_use_abbreviated_path no
# set -g fish_prompt_pwd_dir_length 0
# set -g theme_project_dir_length 0
# set -g theme_newline_cursor yes

# PNPM
set -gx PNPM_HOME "/home/jacky/.local/share/pnpm"
if not string match -q -- $PNPM_HOME $PATH
    set -gx PATH "$PNPM_HOME" $PATH
end

# NVM (commented; enable if needed)
# bash /usr/share/nvm/init-nvm.sh
# set -gx NVM_DIR (printf %s "$HOME/.nvm")
# test -s "$NVM_DIR/nvm.sh"; and source "$NVM_DIR/nvm.sh"

# Proton / Graphics (commented out for stability)
# set -gx WLR_BACKEND vulkan
# set -gx __VK_LAYER_NV_optimus NVIDIA_only
# set -gx VK_ICD_FILENAMES /usr/share/vulkan/icd.d/nvidia_icd.json
# set -gx MESA_LOADER_DRIVER_OVERRIDE zink

# History and general settings
set HISTSIZE -1
set HISTFILESIZE -1
set HISTCONTROL ignoreboth

# Universal vars
set -U -x TERMINAL kitty
set -U XDG_DATA_HOME $HOME/.local/share

# AI / Aider
set -gx OLLAMA_API_BASE http://127.0.0.1:11434
set -gx AIDER_DARK_MODE true

# Editors and apps
set -gx VISUAL nvim
set -gx EDITOR $VISUAL
set -gx BROWSER zen

# Path tweaks
if not contains /opt/nvim-linux64/bin $PATH
    fish_add_path /opt/nvim-linux64/bin
end
fish_add_path ~/.volta/bin

# Locale and TTY
set -gx LANG en_US.UTF-8
set -gx LC_ALL en_US.UTF-8
set -gx TERM_EMULATOR kitty
set -gx TERM xterm-kitty

# Wayland (commented out for safety; set per-app if needed)
# set -gx MOZ_ENABLE_WAYLAND 1
# set -gx QT_QPA_PLATFORM wayland
# set -gx GDK_BACKEND wayland

# DISPLAY tweaks (commented out)
# echo $DISPLAY
# set -e DISPLAY
# set -gx DISPLAY eDP-1
# set -gx DISPLAY $WAYLAND_DISPLAY  # do not override DISPLAY globally

# Misc
set -gx XDG_SCREENSHOTS_DIR "$HOME/Pictures/Screenshots"
set -gx MANPAGER 'nvim +Man!'

set PATH "$HOME/.local/bin:$PATH"
