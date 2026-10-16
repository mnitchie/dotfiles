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
        # Git shortcuts are abbreviations, so they expand in place and I see the full command before it runs.
        # _abbr_expand records each expansion so the reminder in 16-cli.fish only nags about commands I typed out.
        function _abbr_expand
            for entry in $_abbr_map
                set -l parts (string split -m1 : -- $entry)
                if test "$parts[1]" = "$argv[1]"
                    set -ga _abbr_expanded $parts[2]
                    printf '%s\n' $parts[2]
                    return
                end
            end
        end

        function _gabbr
            set -ga _abbr_map "$argv[1]:$argv[2]"
            abbr --add $argv[1] --function _abbr_expand
        end

        _gabbr gco 'git checkout'
        _gabbr gcb 'git checkout -b'
        _gabbr gst 'git status'
        _gabbr gp 'git push'
        _gabbr gl 'git pull'
        _gabbr gd 'git diff'
        _gabbr ga 'git add'
        _gabbr gcm 'git commit -m'
        _gabbr glog "git log --graph --date=short --pretty=format:'%C(auto)%h %C(green)%ad%C(auto)%d %s %C(dim)(%an)%C(reset)'"

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
