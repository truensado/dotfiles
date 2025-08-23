# ---- General ----

set -g fish_greeting

# ---- Environment ----

if not set -q TMUX && uwsm check may-start
  exec uwsm start hyprland.desktop
end

# ---- Prompt ----

if status is-interactive
  starship init fish | source
end

# ---- Bitwarden ----

function bwu
  set -e BW_SESSION
  set -gx BW_SESSION (bw unlock --raw $argv[1])
end

# ---- Tmux ----

function tt
  set -l sessions (tmux list-sessions -F '#S' 2>/dev/null)
  set -l count (count $sessions)

  set -l target
  if test $count -gt 1
    if type -q gum
      set target (printf '%s\n' $sessions \
        | gum choose \
        | string trim \
        | string replace -r '\r$' '' \
        | string collect)
    else if type -q fzf
      set target (printf '%s\n' $sessions \
        | fzf --prompt='tmux sessions > ' --height=40% \
        | string trim \
        | string replace -r '\r$' '' \
        | string collect)
    else
      echo "needs gum or fzf installed"; return 1
    end

    if test -z "$target"
      echo "No session selected."; return 1
    end
  end

  if not set -q TMUX
    if test $count -gt 1
      tmux attach -t "$target"
    else if test $count -eq 1
      tmux attach -t (string collect $sessions[1])
    else
      tmux
    end
  else
    if test $count -gt 1
      tmux switch-client -t "$target"
    else if test $count -eq 1
      tmux switch-client -t (string collect $sessions[1])
    else
      tmux detach-client
    end
  end
end

# ---- Yazi ----

function y
    set tmp (mktemp -t "yazi-cwd.XXXXXX")
    yazi $argv --cwd-file="$tmp"
    if set cwd (cat "$tmp"); and test -n "$cwd"; and test "$cwd" != "$PWD"
        cd "$cwd"
    end
    rm -f "$tmp"
end

# ---- SSH ----

if not pgrep -u (id -u) ssh-agent >/dev/null
    eval (ssh-agent -c) >/dev/null 2>&1
end

if status is-interactive
    keychain --eval --agents ssh id_ed25519 --quiet --nogui 2>/dev/null | source
end

# ---- Aliases ----

alias l='eza -lh --icons=auto'
alias ls='eza -1 --icons=auto'
alias ll='eza -lha --icons=auto --sort=name --group-directories-first'
alias ld='eza -lhD --icons=auto'
alias lt='eza --icons=auto --tree'
alias ff='clear && fastfetch'
alias cc='clear'
alias tt='tmux'
alias tk='tmux kill-session'
alias tl='tmux ls'
alias yy='sudo EDITOR=nvim yazi'
alias fix-pass='faillock --user nsado --reset'

# ---- Abbreviations ----

abbr .. 'z ..'
abbr ... 'z ../..'
abbr .3 'z ../../..'
abbr .4 'z ../../../..'
abbr .5 'z ../../../../..'
abbr mkdir 'mkdir -p'

# ---- Zoxide ----

zoxide init fish | source
