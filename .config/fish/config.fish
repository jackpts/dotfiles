# Fish config split into conf.d parts.
# Fish automatically sources files under ~/.config/fish/conf.d/*.fish
# in lexicographic order for every shell start.
# This file remains minimal on purpose.

# If you need to temporarily bypass conf.d loading for troubleshooting,
# you can start a clean shell:
#   env -u XDG_CONFIG_HOME fish --no-config

# Local overrides can be added here if absolutely necessary.
# Otherwise, edit files under conf.d/:
#  - 00-env.fish          environment variables, PATH, locales
#  - 10-aliases_abbr.fish aliases and abbreviations
#  - 20-functions.fish    user functions only
#  - 30-integrations.fish tool integrations (fzf, zoxide, etc.)
#  - 99-interactive.fish  greeting, keybindings, interactive UX

set -x PATH $HOME/.local/bin $PATH

# string match -q "$TERM_PROGRAM" "kiro" and . (kiro --locate-shell-integration-path fish)

