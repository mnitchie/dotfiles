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

    # Remind me of an alias when I type out the command it expands to. The command still runs as typed,
    # and the reminder prints after its output.
    function _alias_reminder --on-event fish_postexec
        if not set -q _alias_reminder_map
            set -g _alias_reminder_map
            for name in (functions --names)
                set -l desc (functions --details --verbose $name 2>/dev/null)[5]
                # The description is "alias <name> <expansion>"; the "alias name=value" form (zoxide) is skipped.
                set -l expansion (string replace -r -- '^alias \S+ (.+)$' '$1' $desc)
                if string match -q -- 'alias *' $desc; and test "$expansion" != "$desc"
                    # Skip aliases that just re-run themselves (e.g. a wrapped command).
                    if test "$expansion" != "$name"; and not string match -q -- "$name *" $expansion
                        set -a _alias_reminder_map "$name:$expansion"
                    end
                end
            end
            # Abbreviations from 10-aliases.fish are suggested the same way as aliases.
            set -a _alias_reminder_map $_abbr_map
        end

        # Prefer the longest matching expansion, so `git checkout -b` suggests gcb rather than gco.
        set -l cmd (string trim -- $argv[1])
        set -l best_name
        set -l best_expansion
        for entry in $_alias_reminder_map
            set -l name (string split -m1 : -- $entry)[1]
            set -l expansion (string split -m1 : -- $entry)[2]
            if test "$cmd" = "$expansion"; or string match -q -- "$expansion *" $cmd
                if test (string length -- $expansion) -gt (string length -- "$best_expansion")
                    set best_name $name
                    set best_expansion $expansion
                end
            end
        end
        # Stay quiet when the abbreviation itself produced the command.
        if test -n "$best_name"; and not contains -- $best_expansion $_abbr_expanded
            _nudge "$best_name: use the alias instead of '$best_expansion'"
        end
        set -e _abbr_expanded
    end
end
