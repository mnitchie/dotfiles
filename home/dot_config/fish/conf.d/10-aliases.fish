# Fish sources conf.d for every process, including `fish -c`. Keep these
# interactive-only so a non-interactive fish stays a plain command runner.

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
