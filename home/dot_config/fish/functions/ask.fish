function ask --description 'Turn a plain-English request into a shell command to review and run'
    set -l q (string join ' ' -- $argv)
    if test -z "$q"
        echo 'usage: ask <what you want to do>' >&2
        return 2
    end

    set -l cmd (llm --no-log -m gemma4:12b -o think false \
        -s "Output exactly one fish shell command for "(uname -s)". No markdown, no explanation, no code fences." \
        -- "$q" | string trim | string collect)
    if test -z "$cmd"
        echo 'ask: no command returned' >&2
        return 1
    end

    # Prefilled, editable prompt: Enter runs it, Ctrl+C cancels.
    read --shell --command "$cmd" --prompt-str '❯ ' edited; or return
    test -z "$edited"; and return

    history append -- $edited
    eval $edited
end
