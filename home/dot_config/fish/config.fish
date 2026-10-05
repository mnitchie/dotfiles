# Login fish sets PATH in conf.d/00-env.fish. Do not reorder PATH here; a
# non-login fish keeps the inherited order, including a virtualenv at the front.

if status is-interactive
    # The default greeting prints before the prompt.
    function fish_greeting
    end

    if command -q uv
        uv generate-shell-completion fish | source
    end

    if command -q op
        op completion fish | source
    end

    # Key bindings need a terminal.
    if command -q fzf; and isatty stdin
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

    # Not managed by chezmoi. Sourced last so it can override the above.
    if test -r "$__fish_config_dir/local.fish"
        source "$__fish_config_dir/local.fish"
    end
end
