# 30-integrations.fish
# Tool integrations and dynamic detections.

# FZF integration (guarded)
# if type -q fzf
    # fzf --fish | source
# end

# FZF environment and previews
set -gx FZF_DEFAULT_COMMAND "fd --hidden --strip-cwd-prefix --exclude .git"
set -gx FZF_CTRL_T_COMMAND "$FZF_DEFAULT_COMMAND"
set -gx FZF_ALT_C_COMMAND "fd --type=d --hidden --strip-cwd-prefix --exclude .git"
set -gx FZF_CTRL_T_OPTS "--preview 'bat -n --color=always --line-range :500 {}'"
set -gx FZF_ALT_C_OPTS "--preview 'eza --tree --color=always {} | head -200'"

# FZF completion helpers
function _fzf_compgen_path
    fd --hidden --exclude .git . $argv[1]
end

function _fzf_comprun
    set -l command $argv[1]
    set -e argv[1]

    switch $command
        case cd
            fzf --preview 'eza --tree --color=always {} | head -200' $argv
        case ssh
            fzf --preview "eval 'echo \$' {}" $argv
        case '*'
            fzf --preview "bat -n --color=always --line-range :500 {}" $argv
    end
end

# zoxide
if type -q zoxide
    zoxide init fish | source
end

# Prompt (kept commented)
# if type -q starship
#     starship init fish | source
# end

# Detect AUR wrapper
if type -q yay
    set aurhelper yay
else if type -q paru
    set aurhelper paru
end

