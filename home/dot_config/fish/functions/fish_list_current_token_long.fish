function fish_list_current_token_long --description 'List all files with details in the directory under the cursor'
    set -l target "$(commandline -t | string unescape | string replace -r '^~' "$HOME")"
    if not test -d "$target"
        set target (dirname -- "$target")
    end
    if not test -d "$target"
        set target .
    end
    __fish_echo ls -al -- "$target"
end
