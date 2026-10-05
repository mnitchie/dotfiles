function fish_greeting --description 'Show one random keyboard shortcut at shell startup'
    # https://fishshell.com/docs/current/interactive.html#shared-bindings
    # Shared and default Emacs bindings, adjusted for our Alt+L and fzf bindings.
    random choice \
        'Fish tip: Tab (or Ctrl+I) completes the token under the cursor.' \
        'Fish tip: Shift+Tab opens searchable completions (fzf when enabled).' \
        'Fish tip: Left and Right move the cursor one character.' \
        'Fish tip: Right at the end of the line accepts the whole autosuggestion.' \
        'Fish tip: Enter runs a complete command, or adds a newline to an unfinished one.' \
        'Fish tip: Alt+Enter inserts a newline, even when the command is complete.' \
        'Fish tip: Alt+Left and Alt+Right move one word at a time.' \
        'Fish tip: On an empty command line, Alt+Left and Alt+Right navigate directory history.' \
        'Fish tip: Alt+Right (or Alt+F) at the end accepts one word of an autosuggestion.' \
        'Fish tip: Ctrl+Left and Ctrl+Right move by shell tokens, or accept one suggested token.' \
        'Fish tip: Shift+Left and Shift+Right move by whole words, ignoring punctuation.' \
        'Fish tip: Up and Down search history for commands containing what you already typed.' \
        'Fish tip: On an empty command line, Up and Down browse all command history.' \
        'Fish tip: Alt+Up and Alt+Down search history arguments matching the current token.' \
        'Fish tip: After a space, Alt+Up inserts a previous argument; Alt+Down goes forward again.' \
        'Fish tip: Alt+. inserts a previous argument; press again to go further back.' \
        'Fish tip: Ctrl+C interrupts a running command or cancels the current command line.' \
        'Fish tip: Ctrl+D deletes the next character; on an empty line, it exits Fish.' \
        'Fish tip: Ctrl+U cuts from the start of the line to the cursor.' \
        'Fish tip: Ctrl+L clears and redraws the screen while keeping output in scrollback.' \
        'Fish tip: Ctrl+W cuts the previous path component, stopping at /, : or @.' \
        'Fish tip: Ctrl+X copies the command line to the system clipboard.' \
        'Fish tip: Ctrl+V pastes from the system clipboard.' \
        'Fish tip: Alt+D cuts the next word. Use Ctrl+A first to replace the command name.' \
        'Fish tip: Ctrl+Delete cuts the next word (the next argument on macOS).' \
        'Fish tip: Alt+D on an empty command line shows directory history.' \
        'Fish tip: Alt+Delete cuts the next argument (the next word on macOS).' \
        'Fish tip: Shift+Delete removes the current history entry or autosuggestion from history.' \
        'Fish tip: Alt+H (or F1) opens the manual for the command under the cursor.' \
        'Fish tip: Alt+L lists all files with details in the directory under the cursor, or the current directory.' \
        'Fish tip: Alt+O opens the file under the cursor in a pager.' \
        'Fish tip: Alt+O over a script in command position opens that script in your editor.' \
        'Fish tip: Alt+P appends a pipe to your pager, using less by default.' \
        'Fish tip: Alt+W shows a short description of the command under the cursor.' \
        'Fish tip: Alt+E (or Alt+V) opens the command line in your VISUAL or EDITOR.' \
        'Fish tip: Alt+S adds sudo to the current command; on an empty line, it recalls the last command with sudo.' \
        'Fish tip: Ctrl+Space inserts a space without expanding an abbreviation.' \
        'Fish tip: Home (or Ctrl+A) moves to the beginning of the line.' \
        'Fish tip: End (or Ctrl+E) moves to the end; press there to accept an autosuggestion.' \
        'Fish tip: Ctrl+B and Ctrl+F move one character; Ctrl+F at the end accepts an autosuggestion.' \
        'Fish tip: Alt+B and Alt+F move by words, or navigate directory history on an empty line.' \
        'Fish tip: Ctrl+P and Ctrl+N browse command history, like Up and Down.' \
        'Fish tip: Delete removes the next character; Backspace (or Ctrl+H) removes the previous one.' \
        'Fish tip: Alt+Backspace cuts the previous word; Ctrl+Backspace cuts the previous argument.' \
        'Fish tip: Alt+< jumps to the start of the command line; Alt+> jumps to the end.' \
        'Fish tip: Ctrl+K cuts from the cursor to the end of the line.' \
        'Fish tip: Esc (or Ctrl+G) cancels the current operation, or undoes an unambiguous completion.' \
        'Fish tip: Alt+C capitalizes a word; with fzf enabled, it opens a directory picker instead.' \
        'Fish tip: Alt+U uppercases the word under the cursor.' \
        'Fish tip: Ctrl+T swaps two characters; with fzf enabled, it opens a file picker instead.' \
        'Fish tip: Alt+T swaps two words.' \
        'Fish tip: Ctrl+Z (or Ctrl+_) undoes the last command-line edit; some terminals also accept Ctrl+/.' \
        'Fish tip: Alt+/ (or Ctrl+Shift+Z) redoes an undone command-line edit.' \
        'Fish tip: Ctrl+R searches command history, using fzf when enabled.' \
        'Fish tip: In the built-in history pager, Ctrl+R searches older entries and Ctrl+S searches newer ones.'
end
