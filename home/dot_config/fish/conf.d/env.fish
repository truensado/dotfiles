# ~/.config/fish/conf.d/env.fish
# Base editor
set -Ux EDITOR nvim

# Initialization flag (likely set internally)
# set -Ux __fish_initialized 3800

# Core fish behavior
set -Ux fish_key_bindings fish_default_key_bindings

# Fish colors
set -Ux fish_color_autosuggestion 6c7086
set -Ux fish_color_cancel f38ba8
set -Ux fish_color_command 89b4fa
set -Ux fish_color_comment 7f849c
set -Ux fish_color_cwd f9e2af
set -Ux fish_color_cwd_root red
set -Ux fish_color_end fab387
set -Ux fish_color_error f38ba8
set -Ux fish_color_escape eba0ac
set -Ux fish_color_gray 6c7086
set -Ux fish_color_history_current --bold
set -Ux fish_color_host 89b4fa
set -Ux fish_color_host_remote a6e3a1
set -Ux fish_color_keyword f38ba8
set -Ux fish_color_normal cdd6f4
set -Ux fish_color_operator f5c2e7
set -Ux fish_color_option a6e3a1
set -Ux fish_color_param f2cdcd
set -Ux fish_color_quote a6e3a1
set -Ux fish_color_redirection f5c2e7
set -Ux fish_color_search_match --background=313244
set -Ux fish_color_selection --background=313244
set -Ux fish_color_status f38ba8
set -Ux fish_color_user 94e2d5
set -Ux fish_color_valid_path --underline

# Pager colors
set -Ux fish_pager_color_completion cdd6f4
set -Ux fish_pager_color_description 6c7086
set -Ux fish_pager_color_prefix f5c2e7
set -Ux fish_pager_color_progress 6c7086

# Pure prompt configuration
set -Ux pure_begin_prompt_with_current_directory true
set -Ux pure_check_for_new_release false
set -Ux pure_enable_aws_profile true
set -Ux pure_enable_container_detection true
set -Ux pure_enable_git true
set -Ux pure_enable_virtualenv true
set -Ux pure_enable_k8s false
set -Ux pure_enable_nixdevshell false
set -Ux pure_enable_single_line_prompt false
set -Ux pure_reverse_prompt_symbol_in_vimode true
set -Ux pure_separate_prompt_on_error false
set -Ux pure_shorten_prompt_current_directory_length 0
set -Ux pure_shorten_window_title_current_directory_length 0
set -Ux pure_show_jobs false
set -Ux pure_show_prefix_root_prompt false
set -Ux pure_show_subsecond_command_duration false
set -Ux pure_show_system_time false
set -Ux pure_threshold_command_duration 5
set -Ux pure_truncate_prompt_current_directory_keeps -1
set -Ux pure_truncate_window_title_current_directory_keeps -1

# Pure prompt colors
set -Ux pure_color_primary blue
set -Ux pure_color_success magenta
set -Ux pure_color_danger red
set -Ux pure_color_warning yellow
set -Ux pure_color_info cyan
set -Ux pure_color_normal normal
set -Ux pure_color_light white
set -Ux pure_color_dark black
set -Ux pure_color_mute brblack

# Pure prompt symbols
set -Ux pure_symbol_git_dirty '*'
set -Ux pure_symbol_git_stash '≡'
set -Ux pure_symbol_git_unpulled_commits '⇣'
set -Ux pure_symbol_git_unpushed_commits '⇡'
set -Ux pure_symbol_k8s_prefix '☸'
set -Ux pure_symbol_nixdevshell_prefix '❄️'
set -Ux pure_symbol_prefix_root_prompt '#'
set -Ux pure_symbol_prompt '❯'
set -Ux pure_symbol_reverse_prompt '❮'
set -Ux pure_symbol_title_bar_separator '-'

# Optional: unset empty/unneeded ones
set -e pure_symbol_aws_profile_prefix
set -e pure_symbol_container_prefix
set -e pure_symbol_ssh_prefix
set -e pure_symbol_virtualenv_prefix
