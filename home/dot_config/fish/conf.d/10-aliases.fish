if status is-interactive
    if command -q bat
        alias cat 'bat --paging=never'
    end

    if command -q eza
        alias ls 'eza --icons=always'
    end

    if command -q tree
        alias tree 'tree -C'
    end

    if command -q chezmoi
        alias editf 'chezmoi edit --apply ~/.config/fish/config.fish'
    end

    alias reloadf 'exec fish'

    functions --copy history _fish_history
    function history --wraps history
        if not set -q argv[1]
            _fish_history --show-time='%F %T  '
        else
            _fish_history $argv
        end
    end

    if command -q uv
        alias manage 'uv run python manage.py'
    end

    if command -q git
        function gitacp
            if test (count $argv) -lt 1
                echo 'usage: gitacp <message>' >&2
                return 2
            end
            git add --all && git commit -m $argv[1] && git push
        end
    end

    if command -q sed; and command -q column; and command -q less
        function csv
            sed 's/,/ ,/g' $argv | column -t -s ',' | less -S
        end
    end
end
