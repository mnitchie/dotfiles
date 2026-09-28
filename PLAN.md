# Rebuild these dotfiles on chezmoi

Status: draft for review. Nothing below has been implemented.

This branch (`cursor/chezmoi-rebuild-a64c`) replaces the bare-repo setup on `main`
with a chezmoi source repository. `main` stays untouched and is the reference for
anything worth keeping: read old files with `git show main:<path>`. Nothing is
carried over by default. Each task below names what it may port from `main`.

The tasks are written so one subagent can pick up one task with no other context
than this file. The orchestrator (the parent agent) runs the tasks, has each result
reviewed, and commits it. See "Orchestration".

## Goal

One command on a new macOS, Linux, or WSL machine installs the same tools and
produces the same shell, git, and editor behavior:

```bash
sh -c "$(curl -fsLS https://get.chezmoi.io)" -- init --apply mnitchie
```

Day to day: `chezmoi edit <file>`, `chezmoi diff`, `chezmoi apply`, and
`chezmoi update` on the other machines
(<https://www.chezmoi.io/user-guide/daily-operations/>).

## Decisions

These are fixed for every task. Changing one is a plan change, not a task decision.

1. **chezmoi, copy mode.** Files in `$HOME` are real files written by
   `chezmoi apply`. No symlinks, no bare repo, no `config` alias.
2. **`.chezmoiroot` is `home`.** The repo root holds the README, test harness, CI,
   and this plan. Only `home/` is the chezmoi source state. Every path under
   `home/` uses chezmoi source naming (`dot_`, `private_`, `.tmpl`, `run_...`).
3. **Three platforms: `darwin`, `linux`, `wsl`.** They are computed once in
   `home/.chezmoi.toml.tmpl` and stored as `.platform`. WSL is detected from
   `.chezmoi.kernel.osrelease` containing `microsoft`. Linux is either a headless
   server or a desktop with the 1Password app (`.headless`).
4. **macOS means Apple Silicon.** The current Mac is an M2 on macOS Tahoe.
   Homebrew is at `/opt/homebrew`. The config template stops with an error on an
   Intel Mac instead of supporting it.
5. **Templates never read `.chezmoi.os`, `.chezmoi.arch`, or `.chezmoi.kernel`
   directly.** Only `home/.chezmoi.toml.tmpl` does. Every other template branches
   on the data keys listed under "Template data". The test harness can then
   render the macOS and WSL variants on a Linux VM by passing a config file.
6. **Homebrew is the package manager on all three platforms.** Package lists live
   in `home/.chezmoidata/packages.yaml`. apt installs only what Homebrew itself
   needs on Linux, plus zsh.
7. **Keep `$HOME` clean with XDG.** Every tool that can be pointed at the XDG
   base directories is, following "XDG locations" below. The only zsh file in
   `$HOME` is `~/.zshenv`, which sets `ZDOTDIR=~/.config/zsh`; zsh then reads
   the rest from there. No oh-my-zsh. The prompt is Starship.
8. **Secrets come from 1Password or stay on the machine.** Nothing secret is
   committed. A template may call `onepasswordRead` when a file needs a secret.
   `~/.config/zsh/local.zsh`, `~/.config/git/local`, and `~/.ssh/config.local`
   are sourced or included if they exist and are never managed by chezmoi. On WSL,
   ssh host entries go in the Windows `%USERPROFILE%\.ssh\config`, because `ssh`
   and git use Windows `ssh.exe` there.
9. **The repo stays public.** Every task assumes anyone can read it.
10. **Store what you wrote, fetch what you didn't.** Upstream content (skills,
    plugins, themes) comes from Homebrew or `.chezmoiexternal.toml`, never pasted
    into this repo.
11. **Job-specific config lives in one place.** The current employer's shell
    settings are in `~/.config/zsh/conf.d/work.zsh`, rendered only when `.work` is
    true. When a job ends, its contents move to `conf.d/_<company>.zsh` for
    reference. The `conf.d` loader never sources files whose names start with `_`.

## XDG locations

`~/.zshenv` (Task 5) exports the XDG variables explicitly, since macOS doesn't set
them, and every relocation variable in this table. Other tasks put files at these
paths and do not export variables themselves.

| Tool | Location | How |
|---|---|---|
| XDG base dirs | `~/.config`, `~/.local/share`, `~/.local/state`, `~/.cache` | `XDG_CONFIG_HOME`, `XDG_DATA_HOME`, `XDG_STATE_HOME`, `XDG_CACHE_HOME` |
| zsh config | `~/.config/zsh/` | `ZDOTDIR` |
| zsh history | `$XDG_STATE_HOME/zsh/history` | `HISTFILE` |
| zsh completion cache | `$XDG_CACHE_HOME/zsh/zcompdump` | `compinit -d` |
| macOS zsh sessions | disabled | `SHELL_SESSIONS_DISABLE=1` (otherwise Terminal writes `$ZDOTDIR/.zsh_sessions`) |
| git, gh, chezmoi | `~/.config/<tool>/` | native |
| Starship | `~/.config/starship.toml` | native |
| vim | `~/.config/vim/vimrc` | native since Vim 9.1.0327, but only when `~/.vimrc` and `~/.vim/vimrc` don't exist; Homebrew's vim is used, so no `VIMINIT` |
| vim state | `$XDG_STATE_HOME/vim/` | `viminfofile`, `directory`, `undodir`, `backupdir` set in the vimrc |
| Python startup | `~/.config/python/pythonstartup.py` | `PYTHONSTARTUP` |
| Python REPL history | `$XDG_STATE_HOME/python/history` | `PYTHON_HISTORY` (Python 3.13+); the startup file handles older versions |
| IPython | `~/.config/ipython/` | `IPYTHONDIR` |
| less history | `$XDG_STATE_HOME/less/history` | `LESSHISTFILE` |
| npm | `~/.config/npm/npmrc`, `$XDG_CACHE_HOME/npm` | `NPM_CONFIG_USERCONFIG`, `NPM_CONFIG_CACHE` |
| fnm | `$XDG_DATA_HOME/fnm` | `FNM_DIR` (verify fnm's default first; set it only if it differs) |
| Fonts (Linux desktop) | `$XDG_DATA_HOME/fonts/` | native (fontconfig) |

These stay in `$HOME` because the tools or other programs hard-code them:
`~/.zshenv`, `~/.ssh`, `~/.aws`, `~/.agents`.

## Nerd Font

The Starship prompt uses Nerd Font symbols. The font is **JetBrainsMono Nerd
Font** (<https://www.nerdfonts.com/>). It has to be installed where the terminal
runs, which is not always where the shell runs:

- `darwin`: Homebrew cask `font-jetbrains-mono-nerd-font` (Task 4).
- `linux` desktop: the `JetBrainsMono.tar.xz` release archive from
  `ryanoasis/nerd-fonts`, extracted into `$XDG_DATA_HOME/fonts/JetBrainsMonoNerdFont`
  by `.chezmoiexternal` (Task 11), then `fc-cache` (Task 4).
- `wsl`: the terminal is Windows Terminal, so the font goes on Windows. The README
  gives the Windows install command and the Windows Terminal setting (Task 12).
- `linux` server: nothing. The font belongs on the machine you connect from.

Selecting the font in the terminal app is a manual step on every platform; the
README says how.

## Target layout

```text
.chezmoiroot                      # contains: home
.gitignore                        # ignores .bin/
README.md
PLAN.md                           # deleted in the last task
scripts/
  install-test-tools.sh           # installs chezmoi, zsh, shellcheck for the harness
  test.sh                         # renders every profile and runs checks
tests/profiles/
  darwin.toml                     # chezmoi config files with fixed [data]
  linux-server.toml
  linux-desktop.toml
  wsl.toml
.github/workflows/test.yml
home/
  .chezmoi.toml.tmpl              # computes machine data at `chezmoi init`
  .chezmoiignore                  # whole-directory exclusions only
  .chezmoidata/packages.yaml
  .chezmoiexternal.toml.tmpl      # upstream skills
  .chezmoiscripts/
    run_once_before_00-install-homebrew.sh.tmpl
    run_onchange_before_10-install-packages.sh.tmpl
    run_once_after_90-set-login-shell.sh.tmpl
  dot_zshenv.tmpl                 # the only zsh file in $HOME
  dot_config/zsh/
    dot_zprofile.tmpl
    dot_zshrc.tmpl
    conf.d/
      10-aliases.zsh
      15-aws.zsh
      20-darwin.zsh.tmpl
      40-wsl.zsh.tmpl
      work.zsh.tmpl
  dot_config/starship.toml
  dot_config/git/config.tmpl
  dot_config/git/work.tmpl
  dot_config/git/ignore
  dot_config/gh/config.yml
  dot_config/vim/vimrc
  dot_config/python/pythonstartup.py
  dot_config/ipython/profile_default/ipython_config.py
  private_dot_ssh/private_config.tmpl
```

`~/.agents/skills/` and the Linux desktop font directory have no files in the
source tree. Task 11 fills them from `.chezmoiexternal.toml.tmpl`.

## Template data

`home/.chezmoi.toml.tmpl` (Task 3) defines exactly these keys under `[data]`. The
test profiles in `tests/profiles/` hold fixed values for the same keys. A task
that needs another key reports that back; it does not add the key itself.

| Key | Type | Values / meaning | Prompt text (exact) |
|---|---|---|---|
| `platform` | string | `darwin`, `linux`, or `wsl` | computed |
| `brewPrefix` | string | `/opt/homebrew` on `darwin`; `/home/linuxbrew/.linuxbrew` on `linux` and `wsl` | computed |
| `headless` | bool | Linux without the 1Password desktop app, so no SSH agent and no commit signing. Prompted on `linux`; `false` on `darwin` and `wsl` | `Headless Linux (no 1Password app)` |
| `work` | bool | This machine is used for the current job | `Work machine` |
| `workEmail` | string | Commit email for work repos. Prompted when `work` is true, otherwise empty | `Work email` |
| `windowsUser` | string | Windows profile directory name (for `/mnt/c/Users/<name>/...`). Prompted on `wsl`, otherwise empty | `Windows user folder name` |
| `name` | string | `Mike Nitchie` | constant |
| `email` | string | `mikenitchie@gmail.com` | constant |
| `signingKey` | string | Personal SSH public key, from `main:.config/git/config` | constant |
| `workSigningKey` | string | Work SSH public key, from `main:.config/git/config` | constant |

Use `promptBoolOnce` and `promptStringOnce` so `chezmoi init` asks only the first
time. Non-interactive runs (tests, CI, Task 14) answer by prompt text, for example
`--promptBool 'Work machine=false' --promptString 'Work email='`, so the prompt
strings above must match the template exactly.

## Orchestration

The orchestrator does not write task code itself. For each task:

1. **Implement.** Start one subagent with this file's path, the task's heading,
   and anything learned from earlier tasks. Use `composer-2.5` for the mechanical
   tasks (T1, T10, T11, T12, T15) and `grok-4.7-high` for the rest. No other models
   may be used for subagents.
2. **Review.** Start a separate `grok-4.7-high` subagent with: the path to this
   file and the task's heading; the chezmoi docs (<https://www.chezmoi.io/>, in
   particular the user guide, the reference for special files and prefixes, and
   the template functions); the upstream docs the task names; the task's diff
   (`git diff` plus new files); and the implementer's test output. It checks the
   diff against the task's "Done when", the rules below, and the decisions above,
   re-runs `scripts/test.sh`, and returns findings ordered by severity. It does not
   edit files.
3. **Fix.** Resume the implementer with the findings. Repeat review at most twice;
   anything still open goes to the user.
4. **Commit.** The orchestrator commits the task as one commit and pushes.

Tasks in the same wave run in parallel. They share the working tree, so they must
stay inside the files they own, and the harness writes to a fresh temporary
directory on every run.

## Rules for every task

- Work in `/workspace` on branch `cursor/chezmoi-rebuild-a64c`. Do not switch
  branches, commit, or push. Leave your changes in the working tree.
- Edit only the files your task says it owns. If another file needs a change,
  say so in your report.
- Never write to the real `$HOME` of the VM. Test with the harness, which renders
  into a temporary destination. Task 14 is the one exception, and it uses a
  throwaway user account.
- Read old content with `git show main:<path>`. Port behavior, not text: drop dead
  settings, commented-out blocks, and anything a tool now does by default.
- Confirm tool behavior against current documentation, not memory. That includes
  chezmoi, Homebrew, zsh, Starship, delta, fnm, 1Password SSH, and Cursor. Say in
  your report which pages you checked.
- Scripts start with `#!/usr/bin/env bash` and `set -euo pipefail`, pass
  `shellcheck`, and can run twice with no errors and no duplicated effect.
- Shell rc files must start cleanly when an optional tool is missing: guard every
  external command with `command -v` or a file test.
- To ship a file on some platforms only, make it a `.tmpl` whose whole body is
  inside `{{- if ... -}}` ... `{{- end -}}`. chezmoi does not create a file whose
  template renders empty, removes it if it already exists, and skips a script that
  renders to whitespace. A stray newline outside the trim markers defeats this.
  Use `home/.chezmoiignore` only for whole directories.
- chezmoi runs each script in its own process without reading `~/.zshenv`, so
  scripts call tools by full path (`{{ .brewPrefix }}/bin/brew`) or set `PATH`
  themselves.
- Comments explain a constraint the code can't show. No narration.
- Finish by running `scripts/test.sh` (once Task 2 exists). Report: files created,
  test output, anything left undone, and any question for the user.

## Tasks

```text
Wave 0:  T1 clean slate
Wave 1:  T2 test harness
Wave 2:  T3 machine data
Wave 3:  T4 packages   T5 zsh   T7 prompt   T8 git   T9 ssh   T10 small configs   T11 agent skills
Wave 4:  T6 aliases and work config (after T5)
Wave 5:  T12 README   T13 CI
Wave 6:  T14 end-to-end test on a fresh user
Wave 7:  T15 cutover notes and cleanup
```

---

### T1. Clean slate

**Depends on:** nothing.

**Goal:** the branch contains only the skeleton of the new layout.

**Do:**

1. `git rm -r` every tracked file except `PLAN.md`.
2. Create `.chezmoiroot` containing the single line `home`.
3. Create `README.md` with a title and one paragraph: this repo is managed with
   chezmoi, see `PLAN.md` while the rebuild is in progress.
4. Create `home/.chezmoiignore` with a one-line comment, so `home/` exists in git.
5. Create a repo-root `.gitignore` that ignores `.bin/` (local tool installs from
   Task 2).

**Owns:** everything at the repo root at this point.

**Done when:** `git ls-files` plus new files are exactly `PLAN.md`,
`.chezmoiroot`, `README.md`, `.gitignore`, and `home/.chezmoiignore`.

---

### T2. Test harness

**Depends on:** T1.

**Goal:** any subagent can prove a change works on all four machine profiles from
this Linux VM, without touching the real home directory.

**Do:**

1. `scripts/install-test-tools.sh`: installs `chezmoi` into `./.bin` with the
   official installer (`sh -c "$(curl -fsLS get.chezmoi.io)" -- -b ./.bin`), and
   installs `zsh`, `shellcheck`, and `git` if they are missing: with `apt` on
   Linux, with `brew` on macOS (for the CI job in Task 13). Idempotent. This is for
   the harness and CI only; machines are set up with the one-liner in "Goal".
2. `tests/profiles/{darwin,linux-server,linux-desktop,wsl}.toml`: chezmoi config
   files, each with only a `[data]` table holding a placeholder value for every key
   in "Template data". The harness passes `--source`, so the profiles don't set
   `sourceDir`. Task 3 replaces the placeholders with real values.
3. `scripts/test.sh`, which creates a fresh `mktemp -d` directory per run (parallel
   subagents run it at the same time) and, for each profile:
   - renders the whole target state into `<tmp>/<profile>/` with
     `chezmoi --source "$repo" --destination "$out" --config "$profile"
     --persistent-state "$tmp/<profile>.state" --no-tty apply --exclude=scripts
     --force`;
   - renders each file in `home/.chezmoiscripts/` with the same `--source` and
     `--config` flags, as `chezmoi ... execute-template < <script>` (the template
     is read from stdin), into `<tmp>/<profile>.scripts/<name>`, and runs
     `shellcheck` on the non-empty results. `apply --exclude=scripts` never writes
     scripts to the destination, so this directory is where tasks check rendered
     scripts;
   - runs `zsh -n` on every rendered `.zshenv`, `.zprofile`, `.zshrc`, and `*.zsh`;
   - runs `git config --file <f> --list` on every rendered git config file;
   - fails if any rendered file matches a secret pattern
     (`BEGIN .*PRIVATE KEY`, `ghp_`, `gho_`, `github_pat_`, `AKIA[0-9A-Z]{16}`,
     `oauth_token`);
   - prints a one-line pass/fail summary per profile and exits non-zero on any
     failure.
   A config-template warning from chezmoi when using `--config` is expected; the
   harness filters it rather than failing on it. Externals (Task 11) are skipped
   with `--exclude=externals` by default; `TEST_EXTERNALS=1` includes them.
4. Also in `scripts/test.sh`: run `chezmoi execute-template --init --no-tty` on
   `home/.chezmoi.toml.tmpl` (from stdin) with `--promptBool` and `--promptString`
   answers for every prompt in "Template data", and check that its `[data]` keys
   match the keys in every profile. Skip this check with a notice while the
   template does not exist.
5. `scripts/test.sh --keep` prints the temp directory and leaves it in place, so a
   task can inspect the rendered files.

**Owns:** `scripts/`, `tests/`.

**Done when:** `scripts/install-test-tools.sh && scripts/test.sh` passes on the
empty source state, and adding a file containing `ghp_x` under `home/` makes it
fail (remove it afterwards).

---

### T3. Machine data

**Depends on:** T2.

**Goal:** `chezmoi init` produces a config with every key in "Template data".

**Do:**

1. `home/.chezmoi.toml.tmpl`: compute `platform` and `brewPrefix` from
   `.chezmoi.os` and `.chezmoi.kernel.osrelease`
   (<https://www.chezmoi.io/user-guide/machines/windows/>). Call `fail` with a clear
   message on `darwin` when `.chezmoi.arch` is not `arm64`. Prompt once for
   `work`, `workEmail` (only if `work`), `headless` (only on `linux`), and
   `windowsUser` (only on `wsl`). Constants: `name`, `email`, `signingKey`,
   `workSigningKey` from `main:.config/git/config`.
2. Keep chezmoi's own settings at their defaults: scripts stay visible in
   `chezmoi diff`, and git `autoCommit` and `autoPush` stay off.
3. Fill `tests/profiles/*.toml` with realistic values: `darwin` is a work Mac,
   `linux-server` a headless personal server, `linux-desktop` a personal desktop,
   `wsl` a personal WSL machine with `windowsUser = "Michael Nitchie"`.

**Owns:** `home/.chezmoi.toml.tmpl`, `tests/profiles/*.toml`.

**Done when:** `scripts/test.sh` passes, including the key-match check, and
`chezmoi execute-template --init --no-tty` on this VM, with every prompt answered
by flag, reports `platform = "linux"`.

---

### T4. Packages

**Depends on:** T3.

**Goal:** `chezmoi apply` installs Homebrew and the same tools on every platform,
and adding a tool is a one-line edit.

**Port from `main`:** the tool list in `bin/mac_setup.sh` and
`bin/wsl_ubuntu_setup.sh`: `gh`, `jq`, `bat`, `tree`, `pre-commit`, `awscli`,
`aws-vault`, 1Password CLI. Replace `exa` with `eza`. Replace pyenv with `uv`.
Replace nvm with `fnm`. Drop the Powerline fonts clone.

**Add:** `git`, `git-delta`, `vim`, `zsh-autosuggestions`, `starship`, `chezmoi`,
`ripgrep`, `fzf`. On `darwin`, the cask `font-jetbrains-mono-nerd-font` (see
"Nerd Font"). No pnpm.

**Do:**

1. `home/.chezmoidata/packages.yaml` with `brews` (all platforms), `casks`
   (darwin only), and `apt` (Linux and WSL prerequisites for Homebrew plus `zsh`).
   Check each name on formulae.brew.sh. `aws-vault` must be the maintained fork
   that Homebrew ships, not the archived 99designs release. Check how to install
   the 1Password CLI on Linux; if Homebrew can't, add a per-platform install step
   and say why.
2. `run_once_before_00-install-homebrew.sh.tmpl`: on `linux` and `wsl`, install
   the apt list (plus `fontconfig` on a Linux desktop); then, on every platform,
   install Homebrew with `NONINTERACTIVE=1` if `{{ .brewPrefix }}/bin/brew` does
   not exist.
3. `run_onchange_before_10-install-packages.sh.tmpl`: `eval` the output of
   `{{ .brewPrefix }}/bin/brew shellenv`, then run `brew bundle` on a Brewfile
   generated inline from `packages.yaml`, so the script's content, and therefore
   its hash, changes whenever the list changes. Casks only on `darwin`.
4. `run_once_after_90-set-login-shell.sh.tmpl`: on `linux` and `wsl`, make apt's
   `/usr/bin/zsh` the login shell if it isn't already (`chsh` only accepts shells
   listed in `/etc/shells`, and Homebrew's zsh isn't). Nothing on `darwin`, where
   zsh is the default.
5. `run_onchange_after_20-refresh-font-cache.sh.tmpl`: rendered only on `linux`
   when not headless. Runs `fc-cache` on `$XDG_DATA_HOME/fonts` (default
   `~/.local/share/fonts`) if `fc-cache` exists. Include the external's URL from
   `home/.chezmoiexternal.toml.tmpl` in a comment so a font version change re-runs
   it; if that file doesn't exist yet, use the URL in "Nerd Font" and say so.

**Owns:** `home/.chezmoidata/packages.yaml`, `home/.chezmoiscripts/`.

**Done when:** `scripts/test.sh` passes, and in the harness's rendered scripts
(`scripts/test.sh --keep`), the darwin package script contains casks while the
Linux ones do not, and the darwin Homebrew install script installs Homebrew but
runs no apt commands.

---

### T5. zsh core

**Depends on:** T3.

**Goal:** a small zsh setup that keeps its files under XDG and starts the same way
in login and non-login shells on every platform.

**Port from `main`:** from `.config/zsh/.zshrc`: `HIST_IGNORE_SPACE`,
`EDITOR=vim`, `PAGER=less`, `PYTHONDONTWRITEBYTECODE`, `PYTHONUNBUFFERED`, uv
completion, zsh-autosuggestions. Drop oh-my-zsh, nvm, and the SSH agent lines
(Task 9).

**Do:**

1. `home/dot_zshenv.tmpl` (the only zsh file in `$HOME`): the XDG variables,
   `ZDOTDIR`, every relocation variable in "XDG locations", `brew shellenv` from
   `{{ .brewPrefix }}` if present, `~/.local/bin` on `PATH`
   (use `typeset -U path`), `EDITOR`, `PAGER`, and the Python variables. Nothing
   interactive and nothing slow: this file runs for every zsh, including scripts.
   Create the state and cache directories the variables point at if they don't
   exist.
2. `home/dot_config/zsh/dot_zprofile.tmpl`: on `darwin`, `/etc/zprofile` runs
   `path_helper` after `~/.zshenv` and moves system paths ahead of Homebrew in
   login shells. Restore the order here. Check the final `PATH` in both a login and
   a non-login shell.
3. `home/dot_config/zsh/dot_zshrc.tmpl`:
   - History with timestamps: `EXTENDED_HISTORY` (each entry records its start
     time and duration), `SHARE_HISTORY`, `HIST_IGNORE_SPACE`,
     `HIST_IGNORE_ALL_DUPS`, `HIST_REDUCE_BLANKS`, `HIST_VERIFY`, large `HISTSIZE`
     and `SAVEHIST`, and `HISTFILE` from "XDG locations". `alias history='fc -li 1'`
     lists all history with ISO date and time.
   - `compinit -d` with the XDG cache path, key bindings, zsh-autosuggestions from
     Homebrew's `share` directory if present, and uv completion, fzf key bindings,
     fnm (`fnm env --use-on-cd`), and Starship init, each only if the command
     exists.
   - Then source `$ZDOTDIR/conf.d/*.zsh(N)` in order (`N` so a missing or empty
     directory isn't an error), skipping names that start with `_`, then
     `$ZDOTDIR/local.zsh` if it exists.
4. Do not create files in `conf.d/`; Tasks 6 and 9 do.

**Owns:** `home/dot_zshenv.tmpl`, `home/dot_config/zsh/dot_zprofile.tmpl`,
`home/dot_config/zsh/dot_zshrc.tmpl`.

**Done when:** `scripts/test.sh` passes; on this VM, with the rendered linux-server
files and `HOME` set to a temp directory, `zsh -i -c exit` and `zsh -l -i -c exit`
print nothing and exit 0 with no optional tools installed; after running a
command, `fc -li 1` shows it with a date and time; and the rendered darwin
`.zprofile` runs `/opt/homebrew/bin/brew shellenv` (the `path_helper` behavior
itself can only be observed on a Mac).

---

### T6. Aliases and work config

**Depends on:** T5.

**Port from `main`:** `.config/includes/aliases.sh`. Keep the general ones
(`cat=bat`, `ls=eza`, `tree -C`, `gitacp`, `csv`, the uv `manage` alias, and the
python_sandbox Docker aliases). Replace the `*z` aliases that edit `.zshrc` with
the `chezmoi edit` equivalent. Drop the old `history` alias (Task 5 owns
`history`) and the `sqlite3` alias. From the `cd` aliases, keep only `cdsrda`;
drop the rest.

**Do:**

1. `home/dot_config/zsh/conf.d/10-aliases.zsh`: platform-neutral aliases, each
   guarded so it only applies when the target command exists.
2. `home/dot_config/zsh/conf.d/15-aws.zsh`: a zsh function wrapping `aws-vault`
   that prints a one-line yellow warning to stderr on each call, nudging a move to
   AWS IAM Identity Center (`aws configure sso`), then runs the real command with
   all arguments. Keep the message short; it must not change the exit status or
   stdout.
3. `home/dot_config/zsh/conf.d/20-darwin.zsh.tmpl`: the `powermetrics`
   temperature alias and any other macOS-only alias, rendered only on `darwin`.
4. `home/dot_config/zsh/conf.d/work.zsh.tmpl`: rendered only when `.work` is true.
   For now it contains only `cdsrda`. Start the file with a two-line comment
   explaining decision 11: when the job ends, move the contents to
   `_<company>.zsh`, which is never sourced.

**Owns:** `home/dot_config/zsh/conf.d/10-aliases.zsh`, `15-aws.zsh`,
`20-darwin.zsh.tmpl`, `work.zsh.tmpl`.

**Done when:** `scripts/test.sh` passes; `20-darwin.zsh` appears only in the darwin
output and `work.zsh` only in work profiles; and in zsh with a stub `aws-vault` on
`PATH`, `aws-vault --version` prints the warning on stderr and the stub's output on
stdout, with the stub's exit status.

---

### T7. Prompt

**Depends on:** T3.

**Goal:** a Starship prompt that shows the AWS profile, turns red for production
profiles, and shows remaining aws-vault session time.

**Port from `main`:** the intent of `prompt_aws` and `aws_vault_prompt_info` in
`.config/zsh/.zshrc`: red on `*-prod`, `*production*`, and `cleardata`; show hours
and minutes left from `AWS_CREDENTIAL_EXPIRATION`; no `user@host` on the local
machine.

**Do:** `home/dot_config/starship.toml`. Read the Starship `aws` module docs first.
The module stays hidden unless credentials are in the environment or
`force_display = true`, so make it show whenever `AWS_PROFILE` or `AWS_VAULT` is
set. One `style` can't depend on the profile name, so use a `custom` module (with a
`when` test) for the red production case and hide the plain module in that case. Don't call BSD- or GNU-only commands, so the prompt behaves
the same on macOS and Linux. Use Nerd Font symbols (Starship's "Nerd Font Symbols"
preset is a good base); see "Nerd Font".

**Owns:** `home/dot_config/starship.toml`.

**Done when:** `scripts/test.sh` passes, and `starship prompt` (installed into
`./.bin` for the test only) shows a red segment with
`AWS_VAULT=cleardata AWS_PROFILE=cleardata` and a time remaining when
`AWS_CREDENTIAL_EXPIRATION` is an hour ahead.

---

### T8. Git and GitHub CLI

**Depends on:** T3.

**Goal:** one git config serves all platforms, commits are signed with 1Password
wherever it exists, and diffs go through delta.

**Port from `main`:** `.config/git/config` (identity, SSH signing,
`commit.gpgsign`, `push.autoSetupRemote`, `pull.rebase`, `init.defaultBranch`) and
`.config/gh/config.yml` (`git_protocol: ssh`, `co` alias). Do not port
`.config/gh/hosts.yml`: gh writes it at login, and on Linux without a keyring it
can contain the token.

**Do:**

1. `home/dot_config/git/config.tmpl`:
   - identity and signing key from data, `gpg.format = ssh`;
   - `gpg.ssh.program` per platform: the 1Password app's `op-ssh-sign` on
     `darwin`, the Linux app's on non-headless `linux`, and on `wsl`
     `op-ssh-sign-wsl.exe`, which recent 1Password for Windows installs under
     `/mnt/c/Users/{{ .windowsUser }}/AppData/Local/Microsoft/WindowsApps/`. Do not
     reuse the commented-out `.../1Password/app/8/...` path from `main`. Confirm
     all three in 1Password's developer docs (Git commit signing and the WSL
     integration page). Quote the value: `windowsUser` contains a space;
   - `commit.gpgsign` true only where a signer exists (false when `headless`);
   - GitHub credentials through `gh auth git-credential` on every platform instead
     of `osxkeychain`;
   - on `wsl`, `core.sshCommand` set to Windows `ssh.exe` if 1Password's WSL docs
     still recommend it;
   - delta: `core.pager = delta`, `interactive.diffFilter = delta --color-only`,
     plus the settings delta's README recommends (`delta.navigate`,
     `merge.conflictStyle = zdiff3`). No theme choices;
   - `[includeIf "gitdir:~/git/strata/"] path = work` when `.work` is true;
   - `[include] path = local` last, for per-machine overrides.
2. `home/dot_config/git/work.tmpl`: work email and `workSigningKey`, rendered only
   when `.work` is true.
3. `home/dot_config/git/ignore`: `.DS_Store` and editor swap files.
4. `home/dot_config/gh/config.yml`: only the settings that differ from defaults.

**Owns:** `home/dot_config/git/`, `home/dot_config/gh/`.

**Done when:** `scripts/test.sh` passes; `git config --file <rendered> --get
gpg.ssh.program` returns the right path for each profile; the linux-server profile
has signing off; and `core.pager` is `delta` in every profile.

---

### T9. SSH agent

**Depends on:** T3.

**Goal:** `ssh` and `git` use the 1Password SSH agent on each platform, with no
background process started from the shell.

**Port from `main`:** the macOS socket path in `.config/zsh/.zshrc`. Do not port
the `socat`/`npiperelay` relay in `.config/includes/linux.sh`.

**Do:**

1. `home/private_dot_ssh/private_config.tmpl` (`private_` on the file gives
   `0600`; on the directory it only makes `~/.ssh` `0700`): an `Include` of
   `~/.ssh/config.local` first, then `Host *` with `IdentityAgent` set to the
   1Password socket on `darwin` and on `linux` when not headless. The macOS socket
   path contains a space (`Group Containers`), so quote it. Check with `ssh -G`
   that the `Include` doesn't fail when `config.local` is missing; if it does, use
   a glob such as `~/.ssh/config.d/*`.
2. On `wsl`, follow 1Password's WSL integration docs. At the time of writing they
   use Windows `ssh.exe` rather than a socket relay. If that is still the
   recommendation, put an `ssh` alias for `ssh.exe` in
   `home/dot_config/zsh/conf.d/40-wsl.zsh.tmpl`, rendered only on `wsl`. Task 8
   sets git's `core.sshCommand` from the same docs.
3. Do not manage keys, `known_hosts`, or `authorized_keys`.

**Owns:** `home/private_dot_ssh/`, `home/dot_config/zsh/conf.d/40-wsl.zsh.tmpl`.

**Done when:** `scripts/test.sh` passes, the rendered `~/.ssh/config` has mode
`0600`, and each profile names the correct agent (none on linux-server).

---

### T10. Small tool configs

**Depends on:** T3.

**Do:**

1. `home/dot_config/vim/vimrc`: port `main:.config/vim/vimrc`, and add the
   `viminfofile`, swap, undo, and backup locations from "XDG locations", creating
   those directories if missing, so vim doesn't write `~/.viminfo` or `~/.vim/`.
2. `home/dot_config/ipython/profile_default/ipython_config.py`: only the
   uncommented lines of `main:.config/ipython/profile_default/ipython_config.py`.
3. `home/dot_config/python/pythonstartup.py`, a new stub for the plain `python`
   REPL. It must print nothing, add no noticeable startup time, and fail silently
   if a module is missing. It does two things:
   - keeps REPL history in `$PYTHON_HISTORY` on Pythons older than 3.13 (3.13+
     reads that variable itself), creating the directory if needed;
   - defines `pp` as `pprint.pprint`.
4. Nothing from `main:.config/.sqliterc`, `.config/.pythonstartup.py` (empty), or
   `.config/iterm2/`.

**Owns:** `home/dot_config/vim/`, `home/dot_config/ipython/`,
`home/dot_config/python/`.

**Done when:** `scripts/test.sh` passes; the three files appear in every profile's
output; and `PYTHONSTARTUP=<rendered file> PYTHON_HISTORY=$(mktemp -d)/h python3 -i
-c ''` prints nothing extra and exits cleanly (pipe `exit()` on stdin).

---

### T11. Externals: agent skills and Linux font

**Depends on:** T3.

**Goal:** upstream skills and the Linux desktop font are fetched at apply time,
without copying their files into this repo.

**Port from `main`:** nothing. `model-selection-advisor` and `daisyui` are dropped.

**Do:** `home/.chezmoiexternal.toml.tmpl` with two entries.

1. `gh-stack` into `~/.agents/skills/gh-stack` only (not `~/.cursor/skills`), as an
   `archive` of the `v0.1.0` tag tarball
   (`https://github.com/github/gh-stack/archive/refs/tags/v0.1.0.tar.gz`), using
   `stripComponents` and `include` so only the contents of `skills/gh-stack/` land
   there and `SKILL.md` sits directly in the target. Check the tarball's top-level
   directory name first. Don't use `git-repo`: it clones the whole repository and
   pulls on every apply.
2. The JetBrainsMono Nerd Font archive from a pinned `ryanoasis/nerd-fonts`
   release into `.local/share/fonts/JetBrainsMonoNerdFont`, only on `linux` when
   not headless (see "Nerd Font"). Include only the font files.
3. Do not manage anything else under `~/.agents`.

**Owns:** `home/.chezmoiexternal.toml.tmpl`.

**Done when:** `TEST_EXTERNALS=1 scripts/test.sh` passes with network access; the
rendered output has `.agents/skills/gh-stack/SKILL.md` in every profile, no
`.cursor` directory, and font files only in the linux-desktop profile.

---

### T12. README

**Depends on:** T4 through T11.

**Do:** rewrite `README.md`: new-machine setup with the one-liner, including
`--branch <name>` for trying a branch before merging; daily operations (`edit`,
`diff`, `apply`, `update`, `re-add`, `chezmoi cd`) linked to the chezmoi docs; how
to add a package; how to add a file for one platform; the work config and
`_<company>.zsh` convention; where secrets and local overrides go (all three local
files from decision 8, and the WSL ssh config location); setting the
terminal font on each platform, including installing JetBrainsMono Nerd Font on
Windows for WSL (see "Nerd Font"); and how to run `scripts/test.sh`. No long
background section.

**Owns:** `README.md`.

**Done when:** every command in the README exists in the current chezmoi CLI, and
every path it mentions exists in the rendered output of at least one profile.

---

### T13. CI

**Depends on:** T2 (best run after T12).

**Do:** `.github/workflows/test.yml` runs `scripts/install-test-tools.sh` and
`scripts/test.sh` on `ubuntu-latest` and `macos-latest` for pushes and pull
requests. On the macOS job, also run `chezmoi execute-template --init` on the
config template with the prompts answered by flags, so the darwin branch is
exercised on a real Mac, and assert `brewPrefix = "/opt/homebrew"`.

**Owns:** `.github/`.

**Done when:** the workflow passes on the pull request for this branch.

---

### T14. End-to-end on a fresh user

**Depends on:** T12.

**Goal:** prove the real bootstrap on this Linux VM, including scripts.

**Do:**

1. Create a throwaway user with passwordless sudo
   (`useradd -m -s /bin/bash dottest`).
2. As that user, run the README's one-liner with
   `--branch cursor/chezmoi-rebuild-a64c`, answering the prompts by flag as a
   personal, non-work, headless Linux machine
   (`--promptBool 'Headless Linux (no 1Password app)=true' --promptBool 'Work machine=false'`).
3. Check: `zsh -i -c exit` is clean; `brew`, `gh`, `bat`, `eza`, `delta`,
   `starship`, `fnm`, and `uv` are on `PATH` in login and non-login
   shells; `git config --get user.email` and `core.pager` are correct; and the only
   new dotfiles in the user's home are `~/.zshenv`, `~/.ssh`, `~/.config`,
   `~/.local`, `~/.cache`, and `~/.agents`.
4. Run `chezmoi apply` a second time and check that no script runs again and
   `chezmoi status` is empty.
5. Add a formula to `packages.yaml` in the test user's source directory, run
   `chezmoi apply`, and check only the package script ran. Revert.
6. Delete the user.

**Owns:** nothing in the repo. Report bugs to the task that owns the file.

**Done when:** all checks pass, or the report lists each failure with the owning
task.

---

### T15. Cutover notes and cleanup

**Depends on:** T14.

**Do:**

1. Add a README section on moving an existing machine off the bare repo: list
   tracked files with
   `git --git-dir=$HOME/.my_dotfiles_git --work-tree=$HOME ls-files`; move
   `~/.my_dotfiles_git`, `~/.oh-my-zsh`, the old `~/.zshenv`, and the old
   `~/.config/zsh/` and `~/.config/includes/`, `~/.vimrc`, and `~/.vim/` aside;
   then run the one-liner. Note moving the old zsh history file to the new
   `HISTFILE` so history carries over.
2. Delete `PLAN.md`.

**Owns:** `README.md` (this section only), `PLAN.md`.

**Done when:** the repo matches "Target layout" minus `PLAN.md`.