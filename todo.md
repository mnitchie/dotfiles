# Cursor user settings cleanup

Completed on 2026-10-05. The cleaned macOS settings are managed from `home/private_Library/private_Application Support/private_Cursor/User/settings.json`. `home/.chezmoiignore` excludes `Library/` on other platforms.

## Do:

- [x] Make the integrated terminal shell fish (`/opt/homebrew/bin/fish`).

## Remove: Cursor no longer registers these

- [x] `cursor.composer.agentLoopOnLints`
- [x] `cursor.agent_layout_browser_beta_setting`
- [x] `cursor.enable_git_worktrees_setting`
- [x] `cursor.chat.showSuggestedFiles`
- [x] `cursor.composer.shouldAllowCustomModes`
- [x] `cursor.composer.collapsePaneInputBoxPills`

## Remove: the extension is not installed

- [x] `github.copilot.enable` and `github.copilot.editor.enableAutoCompletions`
- [x] All `circleci.*` settings
- [x] `codeviz.autoUpdate`
- [x] `flake8.enabled`
- [x] `markdown-pdf.displayHeaderFooter`
- [x] All `sonarlint.*` settings
- [x] `gotoNextPreviousMember.symbolKinds` and `gotoNextPreviousMember.symbolPosition`

## Remove: Pylance leftovers

Pylance is not installed. Cursor Pyright reads `cursorpyright.analysis.*` and already defaults `python.languageServer` to `None`.

- [x] `python.languageServer`
- [x] Every `python.analysis.*` key

Keep the existing `cursorpyright.analysis.*` entries. `python.analysis.completeFunctionParens`, `python.analysis.fixAll`, and `python.analysis.inlayHints.pytestParameters` have no Cursor Pyright equivalent.

## Remove: no effect, or a footgun

- [x] `files.autoSaveDelay` (autosave is `onFocusChange`; the delay only applies to `afterDelay`)
- [x] `terminal.integrated.profiles.linux` (stock profile list)
- [x] `diffEditor.ignoreTrimWhitespace` inside `[python]` (the global value is already `false`)
- [x] `workbench.preferredDarkColorTheme` (auto-detect is off, and the value is `Default High Contrast` rather than CHC Dark)
- [x] `python.experiments.optInto` with `pythonTestAdapter`

## Leave out of the shared file

- [x] `ruff.lint.ignore` (belongs in the project's Ruff config; with `filesystemFirst` it still applies to every project that has no Ruff config)
- [x] `search.exclude` for `**/trs/**`
- [x] `sqltools.*` (extension is not installed; `sqltools.connections` is one local database entry and includes a password)
- [x] `dev.containers.defaultExtensions` (trim or drop this stale extension list before it becomes a dotfile)
- [x] `gitlens.advanced.blame.customArguments` (keep only if every repo has `.git-blame-ignore-revs`)

## Drop the debug switches

- [x] `ruff.logLevel`: `debug`
- [x] `djangointellisense.debugMessages`: `true`

## Keep

Editor and files: whitespace rendering, rulers at 120, sticky scroll, bracket guides, minimap, linked editing, smooth scrolling, the multicursor limit, format-on-save for modifications, autosave on focus change, trailing-whitespace and final-newline trimming, venv and pytest cache excludes, the `*.mdc` association.

Workbench: CHC Dark, Material icons, sidebar on the right, no startup editor, the line-highlight colors.

Terminal: `terminal.integrated.fontFamily`, the large scrollback, and the extra `docker-desktop` link scheme.

Git and privacy: `git.openRepositoryInParentFolders` never, GitLens code-lens scopes, GitLens and Red Hat telemetry off, flat pull-request file list.

Python: the `[python]` Ruff formatter and organize-imports actions, `ruff.nativeServer` on, `ruff.configurationPreference` filesystem-first, the `cursorpyright.analysis.*` block, pytest discovery, and `debugpy.debugJustMyCode` false.

Formatters still installed: Prettier, djLint, the SQL formatter, and the built-in JSON formatter, plus Emmet and HTML templating for Django templates.

Cursor settings that still exist: `cursor.cpp.disabledLanguages`, `cursor.cpp.enablePartialAccepts`, themed diff background, the completion chime, usage summary, queue-message behavior, and the window-switcher hover setting.

Ports: auto-forward off (changed from `true`), source hybrid. Compact folders off.

## Maintain

Edit the source file above, then run:

```sh
chezmoi apply "$HOME/Library/Application Support/Cursor/User/settings.json"
```

If you change settings through Cursor, review them for secrets before running `chezmoi re-add "$HOME/Library/Application Support/Cursor/User/settings.json"` and committing the source changes.
