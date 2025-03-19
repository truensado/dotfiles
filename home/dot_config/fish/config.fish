set -g fish_greeting

if status is-interactive
    starship init fish | source
end

# yazi 
function y
	set tmp (mktemp -t "yazi-cwd.XXXXXX")
	yazi $argv --cwd-file="$tmp"
	if set cwd (command cat -- "$tmp"); and [ -n "$cwd" ]; and [ "$cwd" != "$PWD" ]
		builtin cd -- "$cwd"
	end
	rm -f -- "$tmp"
end

# Start SSH agent if not already running
if not pgrep -u (id -u) ssh-agent > /dev/null
    eval (ssh-agent -c) > /dev/null 2>&1
end

# Load SSH keys only in an interactive session
if status is-interactive
    keychain --eval --agents ssh id_ed25519 --quiet --nogui | source
end

# List Directory
alias l='eza -lh  --icons=auto' # long list
alias ls='eza -1   --icons=auto' # short list
alias ll='eza -lha --icons=auto --sort=name --group-directories-first' # long list all
alias ld='eza -lhD --icons=auto' # long list dirs
alias lt='eza --icons=auto --tree' # list folder as tree
alias ff='clear && fastfetch' # Fastfetch
alias fix-pass='faillock --user nsado --reset' # Fix Password
alias cc='clear'
alias yy='sudo EDITOR=nvim yazi'

# Handy change dir shortcuts
abbr .. 'z ..'
abbr ... 'z ../..'
abbr .3 'z ../../..'
abbr .4 'z ../../../..'
abbr .5 'z ../../../../..'
abbr mkdir 'mkdir -p'

# Zoxide Initilize
zoxide init fish | source

# Fastfetch on startup
ff
