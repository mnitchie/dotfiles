if status is-interactive
    function _nudge
        begin
            set_color FFD700
            printf '%s\n' $argv
            set_color normal
        end >&2
    end

    if command -q fd
        function fd --wraps fd
            command fd --hidden $argv
            set -l fd_status $status
            printf '%s\n' 'fd: add --no-ignore to include files excluded by .gitignore and other ignore rules.' >&2
            return $fd_status
        end

        function find --wraps find
            _nudge 'find: try fd'
            command find $argv
        end
    end

    if command -q rg
        function grep --wraps grep
            _nudge 'grep: try rg'
            command grep --color=auto $argv
        end
    end

    if command -q duf
        function df --wraps df
            _nudge 'df: try duf'
            command df $argv
        end
    end

    if command -q dust
        function du --wraps du
            _nudge 'du: try dust'
            command du $argv
        end
    end
end
