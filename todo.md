# Cursor user settings cleanup

Do this in `~/Library/Application Support/Cursor/User/settings.json` before that file is added to chezmoi.

## Do:

Make the integrated terminal shell fish.

## Remove: Cursor no longer registers these

- [ ] `cursor.composer.agentLoopOnLints`
- [ ] `cursor.agent_layout_browser_beta_setting`
- [ ] `cursor.enable_git_worktrees_setting`
- [ ] `cursor.chat.showSuggestedFiles`
- [ ] `cursor.composer.shouldAllowCustomModes`
- [ ] `cursor.composer.collapsePaneInputBoxPills`

## Remove: the extension is not installed

- [ ] `github.copilot.enable` and `github.copilot.editor.enableAutoCompletions`
- [ ] All `circleci.*` settings
- [ ] `codeviz.autoUpdate`
- [ ] `flake8.enabled`
- [ ] `markdown-pdf.displayHeaderFooter`
- [ ] All `sonarlint.*` settings
- [ ] `gotoNextPreviousMember.symbolKinds` and `gotoNextPreviousMember.symbolPosition`

## Remove: Pylance leftovers

Pylance is not installed. Cursor Pyright reads `cursorpyright.analysis.*` and already defaults `python.languageServer` to `None`.

- [ ] `python.languageServer`
- [ ] Every `python.analysis.*` key

Keep the existing `cursorpyright.analysis.*` entries. `python.analysis.completeFunctionParens`, `python.analysis.fixAll`, and `python.analysis.inlayHints.pytestParameters` have no Cursor Pyright equivalent.

## Remove: no effect, or a footgun

- [ ] `files.autoSaveDelay` (autosave is `onFocusChange`; the delay only applies to `afterDelay`)
- [ ] `terminal.integrated.profiles.linux` (stock profile list)
- [ ] `diffEditor.ignoreTrimWhitespace` inside `[python]` (the global value is already `false`)
- [ ] `workbench.preferredDarkColorTheme` (auto-detect is off, and the value is `Default High Contrast` rather than CHC Dark)
- [ ] `python.experiments.optInto` with `pythonTestAdapter`

## Leave out of the shared file

- [ ] `ruff.lint.ignore` (belongs in the project's Ruff config; with `filesystemFirst` it still applies to every project that has no Ruff config)
- [ ] `search.exclude` for `**/trs/**`
- [ ] `sqltools.*` (extension is not installed; `sqltools.connections` is one local database entry and includes a password)
- [ ] `dev.containers.defaultExtensions` (trim or drop this stale extension list before it becomes a dotfile)
- [ ] `gitlens.advanced.blame.customArguments` (keep only if every repo has `.git-blame-ignore-revs`)

## Drop the debug switches

- [ ] `ruff.logLevel`: `debug`
- [ ] `djangointellisense.debugMessages`: `true`

## Keep

Editor and files: whitespace rendering, rulers at 120, sticky scroll, bracket guides, minimap, linked editing, smooth scrolling, the multicursor limit, format-on-save for modifications, autosave on focus change, trailing-whitespace and final-newline trimming, venv and pytest cache excludes, the `*.mdc` association.

Workbench: CHC Dark, Material icons, sidebar on the right, no startup editor, the line-highlight colors.

Terminal: `terminal.integrated.fontFamily`, the large scrollback, and the extra `docker-desktop` link scheme.

Git and privacy: `git.openRepositoryInParentFolders` never, GitLens code-lens scopes, GitLens and Red Hat telemetry off, flat pull-request file list.

Python: the `[python]` Ruff formatter and organize-imports actions, `ruff.nativeServer` on, `ruff.configurationPreference` filesystem-first, the `cursorpyright.analysis.*` block, pytest discovery, and `debugpy.debugJustMyCode` false.

Formatters still installed: Prettier, djLint, the SQL formatter, and the built-in JSON formatter, plus Emmet and HTML templating for Django templates.

Cursor settings that still exist: `cursor.cpp.disabledLanguages`, `cursor.cpp.enablePartialAccepts`, themed diff background, the completion chime, usage summary, queue-message behavior, and the window-switcher hover setting.

Ports: auto-forward off, source hybrid. Compact folders off.
