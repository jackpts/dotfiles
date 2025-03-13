# config.nu
#
# Installed by:
# version = "0.102.0"
#
# This file is used to override default Nushell settings, define
# (or import) custom commands, or run any other startup tasks.
# See https://www.nushell.sh/book/configuration.html
#
# This file is loaded after env.nu and before login.nu
#
# You can open this file in your default editor using:
# config nu
#
# See `help config nu` for more options
#
# You can remove these comments if you want or leave
# them for future reference.


$env.config = {
  table: {
# basic, compact, compact_double, light, thin, with_love, rounded, reinforced, heavy, none, psql
    mode: "compact"
# index_mode: never # "always" show indexes, "never" show indexes, "auto" = show indexes when a table has "index" column
    index_mode: "auto"
  }
  # edit_mode:  "vi"
  footer_mode: "never"
  error_style: "plain"
}

alias c = clear
alias q = exit
alias l = eza -lF --time-style=long-iso --icons
alias ll = eza -h --git --icons --color=auto --group-directories-first -s extension
alias gcld = git clone --depth 1

# starship init
mkdir ($nu.data-dir | path join "vendor/autoload")
starship init nu | save -f ($nu.data-dir | path join "vendor/autoload/starship.nu")
