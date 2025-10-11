# ---- Initialize

set -g fish_greeting

if status is-interactive
  set -g fish_key_bindings fish_vi_key_bindings
end

if status is-login
  if not set -q TMUX; and uwsm check may-start
    exec uwsm start hyprland.desktop
  end
end

if test -f "$HOME/.ssh/id_ed25519"
  if type -q ssh; and not pgrep -u (id -u) ssh-agent >/dev/null
    eval (ssh-agent -c) >/dev/null 2>&1
  end
  if type -q keychain; and status is-interactive
    keychain --eval --agents ssh id_ed25519 --quiet --nogui 2>/dev/null | source
  end
end

# ---- Functions

function bwu
  if type -q bw
    set -gx BW_SESSION (bw unlock --raw)
  else
    echo "bitwardencli not installed..."
  end
end

function y
  if type -q yazi
    set tmp (mktemp -t "yazi-cwd.XXXXXX")
    yazi $argv --cwd-file="$tmp"
    if read -z cwd < "$tmp"; and [ -n "$cwd" ]; and [ "$cwd" != "$PWD" ]
      builtin cd -- "$cwd"
    end
    rm -f -- "$tmp"
  else
    echo "yazi not installed..."
  end
end

function yy
  if type -q yazi
    set tmp (mktemp -t "yazi-cwd.XXXXXX")
    sudo yazi $argv --cwd-file="$tmp"
    if read -z cwd < "$tmp"; and [ -n "$cwd" ]; and [ "$cwd" != "$PWD" ]
      builtin cd -- "$cwd"
    end
    rm -f -- "$tmp"
  else
    echo "yazi not installed..."
  end
end

function t
  if type -q tmux
    set sessions (tmux list-sessions -F "#{session_name}" 2>/dev/null | grep -E '^session-[0-9]+$')
    set amount (count $sessions)
    if test $amount -eq 0
      set next 1
    else
      set next (math "$amount + 1")
    end
    while tmux has-session -t "session-$next" 2>/dev/null
        set next (math "$next + 1")
    end
    set new "session-$next"
    switch $argv[1]
    case -s
      if test $amount -gt 0
        if test $amount -gt 1
          if type -q gum
            set target (printf '%s\n' $sessions | gum choose)
          else if type -q fzf
            set target (printf '%s\n' $sessions | fzf --color 'pointer:#cba6f7,marker:#b4befe,prompt:#a6e3a1,border:#cba6f7,info:#f5e0dc,bg+:#45475a,fg+:#f5e0dc:bold')
          else
            echo "neither gum nor fzf installed..."
          end
          if test -z "$target"
            return 1
          else
            if set -q TMUX
              tmux switch-client -t $target
            else
              tmux attach -t $target
            end
          end
        else
          if set -q TMUX
            tmux switch -t (printf '%s\n' $sessions)
          else
            tmux attach
          end
        end
      else
        echo "no sessions found"
      end
    case -k
      tmux list-sessions -F "#{session_name}" 2>/dev/null | while read -l name
        tmux kill-session -t $name
      end
    case '*'
      if set -q TMUX
        tmux detach-client
      else
        tmux new-session -s $new
      end
    end
  else
    echo "tmux not installed..."
  end
end

# ----  Aliases

alias fp='faillock --user $USER --reset'
alias chia='chezmoi init --apply'
alias tka='tmux kill-sessions -a'
alias tkt='tmux kill-session -t'
alias ff='clear;fastfetch'
alias cha='chezmoi apply'
alias gca='git commit -am'
alias cha='chezmoi init'
alias chc='chezmoi cd'
alias gb='git branch'
alias gc='git clone'
alias gpl='git pull'
alias gps='git push'
alias gd='git diff'
alias gi='git init'
alias ga='git add'
alias tl='tmux ls'
alias ch='chezmoi'
alias cc='clear'
alias mp='mkdir -p'

if type -q eza
  alias ll='eza -lha --icons=auto --sort=name --group-directories-first'
  alias lt='eza --icons=auto --tree'
  alias ld='eza -lhD --icons=auto'
  alias l='eza -lh --icons=auto'
  alias ls='eza -1 --icons=auto'
end

# ---- Abbreviations

abbr mkdir 'mkdir -p'
abbr .5 'z ../../../../..'
abbr .4 'z ../../../..'
abbr .3 'z ../../..'
abbr ... 'z ../..'
abbr .. 'z ..'

# ---- Finalize

if type -q starship; and status is-interactive
  test -z "$STARSHIP_CONFIG"; and set -gx STARSHIP_CONFIG $XDG_CONFIG_HOME/starship/starship.toml
  test -z "$STARSHIP_CACHE"; and set -gx STARSHIP_CACHE $XDG_CACHE_HOME/starship
  starship init fish | source
end

if type -q zoxide; and status is-interactive
  zoxide init fish | source
end
