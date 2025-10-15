#!/usr/bin/env bash
# description: browse and install packages interactively with fzf

main() {
  local mode_arg
  [[ "$mode" == "install" ]] && mode_arg="remove" || mode_arg="install"
  
  fzf_args=(
    --multi
    --prompt "$mode | "
    --preview 'pacman -Sii {1}'
    --preview-label='alt-p: toggle description, alt-j/k: scroll, alt-m: mode-toggle, tab: multi-select'
    --preview-label-pos='bottom'
    --preview-window 'down:65%:wrap'
    --bind 'alt-p:toggle-preview'
    --bind "alt-m:become($0 $mode_arg)"
    --bind 'alt-d:preview-half-page-down,alt-u:preview-half-page-up'
    --bind 'alt-k:preview-up,alt-j:preview-down'
    --color 'pointer:#cba6f7,marker:#b4befe,prompt:#a6e3a1,border:#cba6f7,info:#f5e0dc,bg+:#45475a,fg+:#f5e0dc:bold'
  )

  installed_pkgs=$(pacman -Qq)

  pkgs=$(pacman -Sl | awk -v installed="$installed_pkgs" '
  BEGIN {
    # put installed packages into a hash for O(1) lookups
    n=split(installed, arr, "\n")
    for (i=1; i<=n; i++) inst[arr[i]]=1
  }
  {
    if (inst[$2]) {
      status="\033[1;32m[installed]\033[0m"  # green
    } else {
      status=""
    }
    print $2, status
  }' | fzf --ansi "${fzf_args[@]}")

  if [[ -z "$pkgs" ]]; then
    log_warning "No packages selected."
    exit 0
  fi

}

do_install() {
  local mode="install"
  main
  log_info "Installing selected packages..."
  echo "$pkgs" | awk '{print $1}' | tr '\n' ' ' | xargs sudo pacman -S --needed --noconfirm \
  && log_success "Package installation complete." || log_error "Package failed to install"
}

do_remove() {
  local mode="remove"
  main
  log_info "Uninstalling selected packages..."
  echo "$pkgs" | awk '{print $1}' | tr '\n' ' ' | xargs sudo pacman -Rsn --noconfirm \
  && log_success "Package removal complete." || log_error "Package failed to remove"
}

case "$#" in
  0) do_install ;;
  1)
    case "$1" in
      *remove | -r) do_remove ;;
      *install | -i) do_install ;;
      *)
        log_error "unknown argument $1"
        echo
        usage
        exit 1
        ;;
    esac
    ;;
  *)
    log_error "too many arguments"
    echo
    usage
    exit 1
    ;;
esac
