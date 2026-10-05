if status is-interactive
    bind \el fish_list_current_token_long

    if command -q uv
        uv generate-shell-completion fish | source
    end

    if command -q op
        op completion fish | source
    else if command -q op.exe
        op.exe completion fish | source
    end

    # Key bindings need a terminal.
    if command -q fzf; and isatty stdin
        set -g FZF_CTRL_R_OPTS '--with-nth=1,3..'
        fzf --fish | source
    end

    if command -q zoxide
        zoxide init fish --cmd cd | source
    end

    if command -q fnm
        fnm env --use-on-cd --shell fish | source
    end

    if command -q starship
        starship init fish | source
    end

    # Unmanaged local overrides.
    if test -r "$__fish_config_dir/local.fish"
        source "$__fish_config_dir/local.fish"
    end
end
