# Rebuild these dotfiles on chezmoi

Status: draft for review. Nothing below has been implemented.

This branch (`cursor/chezmoi-rebuild-a64c`) replaces the bare-repo setup on `main`
with a chezmoi source repository. `main` stays untouched and is the reference for
anything worth keeping: read old files with `git show main:<path>`. Nothing is
carried over by default. Each task below names what it may port from `main`.

The tasks are written so one subagent can pick up one task with no other context
than this file. The orchestrator (the parent agent) runs the tasks, reviews each
result, and commits it.

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
   `.chezmoi.kernel.osrelease` containing `microsoft`.
4. **Templates never read `.chezmoi.os`, `.chezmoi.arch`, or `.chezmoi.kernel`
   directly.** Only `home/.chezmoi.toml.tmpl` does. Every other template branches
   on the data keys listed under "Template data". The test harness can then
   render the macOS and WSL variants on a Linux VM by passing a config file.
5. **Homebrew is the package manager on all three platforms.** Package lists live
   in `home/.chezmoidata/packages.yaml`. apt installs only what Homebrew itself
   needs on Linux, plus zsh.
6. **zsh with its files in their default places.** `~/.zshenv` and `~/.zshrc`.
   No `ZDOTDIR`, no oh-my-zsh. The prompt is Starship.
7. **Secrets come from 1Password or stay on the machine.** Nothing secret is
   committed. A template may call `onepasswordRead` when a file needs a secret.
   `~/.zshrc.local` and `~/.gitconfig.local` are sourced or included if they
   exist and are never managed by chezmoi.
8. **The repo stays public.** Every task assumes anyone can read it.
9. **Store what you wrote, fetch what you didn't.** Upstream content (skills,
   plugins, themes) comes from Homebrew or `.chezmoiexternal.toml`, never pasted
   into this repo.

## Target layout

```text
.chezmoiroot                      # contains: home
README.md
PLAN.md                           # deleted in the last task
install.sh                        # optional wrapper around the one-liner
scripts/
  dev-setup.sh                    # installs chezmoi, zsh, shellcheck for testing
  test.sh                         # renders every profile and runs checks
tests/profiles/
  darwin-arm64.toml               # chezmoi config files with fixed [data]
  darwin-x86_64.toml
  linux.toml
  wsl.toml
.github/workflows/test.yml
home/
  .chezmoi.toml.tmpl              # computes machine data at `chezmoi init`
  .chezmoiignore                  # whole-directory exclusions only
  .chezmoidata/packages.yaml
  .chezmoiexternal.toml           # upstream skills and similar
  .chezmoiscripts/
    run_once_before_00-install-homebrew.sh.tmpl
    run_onchange_before_10-install-packages.sh.tmpl
    run_once_after_90-set-login-shell.sh.tmpl
  dot_zshenv.tmpl
  dot_zshrc.tmpl
  dot_config/zsh/conf.d/*.zsh(.tmpl)
  dot_config/starship.toml
  dot_config/git/config.tmpl
  dot_config/git/work.tmpl
  dot_config/git/ignore
  dot_config/gh/config.yml
  private_dot_ssh/config.tmpl
  dot_vimrc
  dot_sqliterc
  dot_ipython/profile_default/ipython_config.py
  dot_cursor/skills/model-selection-advisor/SKILL.md
```

## Template data

`home/.chezmoi.toml.tmpl` (Task 3) defines exactly these keys under `[data]`. The
test profiles in `tests/profiles/` hold fixed values for the same keys. A task
that needs another key reports that back; it does not add the key itself.

| Key | Type | Values / meaning |
|---|---|---|
| `platform` | string | `darwin`, `linux`, or `wsl` |
| `arch` | string | `arm64` or `amd64` |
| `brewPrefix` | string | `/opt/homebrew` (Apple Silicon), `/usr/local` (Intel Mac), `/home/linuxbrew/.linuxbrew` (Linux and WSL) |
| `headless` | bool | Linux with no desktop session. No 1Password app, so no SSH agent and no commit signing. Prompted once on `linux`; `false` on `darwin` and `wsl` |
| `work` | bool | This machine is used for Strata work. Prompted once |
| `workEmail` | string | Commit email for the work repos. Prompted once when `work` is true, otherwise empty |
| `windowsUser` | string | Windows profile directory name (for `/mnt/c/Users/<name>/...`). Prompted once on `wsl`, otherwise empty |
| `name` | string | `Mike Nitchie` (constant) |
| `email` | string | `mikenitchie@gmail.com` (constant) |
| `signingKey` | string | Personal SSH public key (constant; from `main:.config/git/config`) |
| `workSigningKey` | string | Work SSH public key (constant; from `main:.config/git/config`) |

Use `promptBoolOnce` and `promptStringOnce` so `chezmoi init` asks only the first
time.

## Rules for every task

- Work in `/workspace` on branch `cursor/chezmoi-rebuild-a64c`. Do not switch
  branches, commit, or push. Leave your changes in the working tree; the
  orchestrator reviews and commits one task at a time.
- Edit only the files your task says it owns. If another file needs a change,
  say so in your report.
- Never write to the real `$HOME` of the VM. Test with the harness, which renders
  into a temporary destination. Task 14 is the one exception, and it uses a
  throwaway user account.
- Read old content with `git show main:<path>`. Port behavior, not text: drop dead
  settings, commented-out blocks, and anything a tool now does by default.
- Confirm tool behavior against current documentation, not memory. That includes
  chezmoi, Homebrew, Starship, 1Password SSH, and Cursor. Say in your report which
  pages you checked.
- Scripts start with `#!/usr/bin/env bash` and `set -euo pipefail`, pass
  `shellcheck`, and can run twice with no errors and no duplicated effect.
- Shell rc files must start cleanly when an optional tool is missing: guard every
  external command with `command -v` or a file test.
- To ship a file on some platforms only, make it a `.tmpl` whose whole body is
  inside an `{{ if }}`. chezmoi does not create a file whose template renders
  empty, and removes it if it already exists. Use `home/.chezmoiignore` only for
  whole directories.
- Comments explain a constraint the code can't show. No narration.
- Finish by running `scripts/test.sh` (once Task 2 exists). Report: files created,
  test output, anything left undone, and any question for the user.

## Tasks

Dependencies are listed per task. Tasks in the same wave can run in parallel
because they own disjoint files.

```text
Wave 0:  T1 clean slate
Wave 1:  T2 test harness
Wave 2:  T3 machine data
Wave 3:  T4 packages   T5 zsh   T7 prompt   T8 git + gh   T9 ssh   T10 small configs   T11 cursor skills
Wave 4:  T6 aliases (after T5)
Wave 5:  T12 bootstrap + README   T13 CI
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
4. Create `home/.chezmoiignore` with an empty comment header, so `home/` exists in
   git.
5. Create a repo-root `.gitignore` that ignores `.bin/` (local tool installs from
   Task 2) and `.test-output/`.

**Owns:** everything at the repo root at this point.

**Done when:** `git ls-files` lists exactly `PLAN.md`, `.chezmoiroot`,
`README.md`, `.gitignore`, and `home/.chezmoiignore`.

---

### T2. Test harness

**Depends on:** T1.

**Goal:** any subagent can prove a change works on all four platforms from this
Linux VM, without touching the real home directory.

**Do:**

1. `scripts/dev-setup.sh`: installs `chezmoi` into `./.bin` with the official
   installer (`sh -c "$(curl -fsLS get.chezmoi.io)" -- -b ./.bin`), and installs
   `zsh`, `shellcheck`, and `git` with `apt` if they are missing. Idempotent.
2. `tests/profiles/*.toml`: four chezmoi config files, each with only a `[data]`
   table holding a placeholder value for every key in "Template data". The
   harness passes `--source`, so the profiles don't set `sourceDir`. Task 3
   replaces the placeholders with real values.
3. `scripts/test.sh`, which for each profile:
   - renders the whole target state into `.test-output/<profile>/` with
     `chezmoi --source "$repo" --destination "$out" --config "$profile"
     --persistent-state "$out.state" --no-tty apply --exclude=scripts --force`;
   - renders each file in `home/.chezmoiscripts/` with
     `chezmoi execute-template` and runs `shellcheck` on the result;
   - runs `zsh -n` on every rendered file named `.zshenv`, `.zshrc`, or `*.zsh`;
   - runs `git config --file <f> --list` on every rendered git config file;
   - fails if any rendered file matches a secret pattern
     (`BEGIN .*PRIVATE KEY`, `ghp_`, `gho_`, `AKIA[0-9A-Z]{16}`,
     `oauth_token`);
   - prints a one-line pass/fail summary per profile and exits non-zero on any
     failure.
   A config-template warning from chezmoi when using `--config` is expected; the
   harness should filter it, not fail on it.
4. Also in `scripts/test.sh`: run
   `chezmoi execute-template --init` on `home/.chezmoi.toml.tmpl` with
   `--promptBool`/`--promptString` answers, and check that its `[data]` keys match
   the keys in every profile. Skip this check with a notice while the template
   does not exist.

**Owns:** `scripts/`, `tests/`.

**Done when:** `scripts/dev-setup.sh && scripts/test.sh` passes on the empty
source state, and deliberately adding a file containing `ghp_x` under `home/`
makes it fail (remove it afterwards).

---

### T3. Machine data

**Depends on:** T2.

**Goal:** `chezmoi init` produces a config with every key in "Template data".

**Do:**

1. `home/.chezmoi.toml.tmpl`: compute `platform`, `arch`, and `brewPrefix` from
   `.chezmoi.os`, `.chezmoi.arch`, and `.chezmoi.kernel.osrelease`
   (<https://www.chezmoi.io/user-guide/machines/windows/>). Prompt once for
   `work`, `workEmail` (only if `work`), `headless` (only on `linux`), and
   `windowsUser` (only on `wsl`). Constants: `name`, `email`, `signingKey`,
   `workSigningKey` from `main:.config/git/config`.
2. Keep chezmoi's own settings at their defaults: scripts stay visible in
   `chezmoi diff`, and git `autoCommit` and `autoPush` stay off.
3. Fill `tests/profiles/*.toml` with realistic values: `darwin-arm64` is a work
   Mac, `darwin-x86_64` a personal Intel Mac, `linux` a headless personal server,
   `wsl` a personal WSL machine with `windowsUser = "Michael Nitchie"`.

**Owns:** `home/.chezmoi.toml.tmpl`, `tests/profiles/*.toml`.

**Done when:** `scripts/test.sh` passes, including the key-match check, and
`chezmoi execute-template --init` output on this VM reports `platform = "linux"`.

---

### T4. Packages

**Depends on:** T3.

**Goal:** `chezmoi apply` installs Homebrew and the same tools on every platform,
and adding a tool is a one-line edit.

**Port from `main`:** the tool list in `bin/mac_setup.sh` and
`bin/wsl_ubuntu_setup.sh`: `gh`, `jq`, `bat`, `tree`, `pre-commit`, `awscli`,
`aws-vault`, 1Password CLI. Replace `exa` with `eza`. Replace pyenv and nvm with
`uv` (Node: see Open questions). Drop the Powerline fonts clone.

**Add:** `git`, `zsh-autosuggestions`, `starship`, `chezmoi`, `ripgrep`, `fzf`.

**Do:**

1. `home/.chezmoidata/packages.yaml` with `brews` (all platforms), `casks`
   (darwin only), and `apt` (Linux and WSL prerequisites for Homebrew plus `zsh`).
   Check each name with `brew info` or formulae.brew.sh. In particular, check how
   to install the 1Password CLI and `aws-vault` on Linux; if Homebrew can't, add a
   per-platform install step and say why.
2. `run_once_before_00-install-homebrew.sh.tmpl`: on Linux and WSL, install the apt
   list; then install Homebrew non-interactively if `brew` is not on `PATH` at
   `{{ .brewPrefix }}`.
3. `run_onchange_before_10-install-packages.sh.tmpl`: run `brew bundle` from a
   Brewfile generated inline from `packages.yaml`, so the script's content, and
   therefore its hash, changes whenever the list changes. Casks only on
   `darwin`.
4. `run_once_after_90-set-login-shell.sh.tmpl`: on Linux and WSL, make zsh the
   login shell if it isn't already. Nothing on `darwin`.

**Owns:** `home/.chezmoidata/packages.yaml`, `home/.chezmoiscripts/`.

**Done when:** `scripts/test.sh` passes, and the rendered darwin script contains
casks while the linux one does not.

---

### T5. zsh core

**Depends on:** T3.

**Goal:** a small zsh setup that starts the same way in login and non-login
shells on every platform.

**Port from `main`:** from `.config/zsh/.zshrc`: `HIST_IGNORE_SPACE`,
`EDITOR=vim`, `PAGER=less`, `PYTHONDONTWRITEBYTECODE`, `PYTHONUNBUFFERED`, uv
completion, zsh-autosuggestions. Drop oh-my-zsh, `ZDOTDIR`, the XDG exports that
only restate defaults, nvm, `PYTHONSTARTUP`, `IPYTHONDIR`, and the SSH agent
lines (Task 9).

**Do:**

1. `dot_zshenv.tmpl`: `brew shellenv` from `{{ .brewPrefix }}` if present,
   `~/.local/bin` on `PATH`, `EDITOR`, `PAGER`, and the Python variables. Nothing
   interactive and nothing slow: this file runs for every zsh, including scripts.
2. `dot_zshrc.tmpl`: history settings (size, shared history, ignore duplicates),
   `compinit`, key bindings, zsh-autosuggestions from
   `$(brew --prefix)/share/...` if present, uv completion if `uv` exists, fzf key
   bindings if `fzf` exists, Starship init if `starship` exists. Then source
   `~/.config/zsh/conf.d/*.zsh` in order, then `~/.zshrc.local` if it exists.
3. Do not create files in `conf.d/`; Tasks 6 and 9 do.

**Owns:** `home/dot_zshenv.tmpl`, `home/dot_zshrc.tmpl`.

**Done when:** `scripts/test.sh` passes, and on this VM
`HOME=$(mktemp -d) zsh -i -c exit` using the rendered linux files prints nothing
and exits 0 with no tools installed.

---

### T6. Aliases and functions

**Depends on:** T5.

**Port from `main`:** `.config/includes/aliases.sh`. Keep the general ones
(`cat=bat`, `ls=eza`, `tree -C`, `gitacp`, `csv`, the uv `manage` alias, and the
python_sandbox Docker aliases). Replace the `*z` aliases that edit `.zshrc` with
the `chezmoi edit` equivalent. Drop `alias history=...` unless it still does
something zsh doesn't. Drop the `sqlite3 -init` alias (Task 10 puts `.sqliterc`
where sqlite reads it).

**Do:**

1. `home/dot_config/zsh/conf.d/10-aliases.zsh`: platform-neutral aliases, each
   guarded so it only applies when the target command exists.
2. `home/dot_config/zsh/conf.d/20-darwin.zsh.tmpl`: the `powermetrics`
   temperature alias and any other macOS-only alias, rendered only on `darwin`.
3. `home/dot_config/zsh/conf.d/30-work.zsh.tmpl`: the `~/git/strata/...` `cd`
   aliases, rendered only when `.work` is true.

**Owns:** `home/dot_config/zsh/conf.d/10-aliases.zsh`, `20-darwin.zsh.tmpl`,
`30-work.zsh.tmpl`.

**Done when:** `scripts/test.sh` passes, and `20-darwin.zsh` is present only in the
darwin outputs and `30-work.zsh` only in the work profile's output.

---

### T7. Prompt

**Depends on:** T3.

**Goal:** a Starship prompt that shows the AWS profile, turns red for production
profiles, and shows remaining aws-vault session time.

**Port from `main`:** the intent of `prompt_aws` and `aws_vault_prompt_info` in
`.config/zsh/.zshrc`: red on `*-prod`, `*production*`, and `cleardata`; show hours
and minutes left from `AWS_CREDENTIAL_EXPIRATION`; no `user@host` in the prompt
on the local machine.

**Do:** `home/dot_config/starship.toml`. Check the Starship `aws` module docs
first. If the built-in module can't color by profile name, use a `custom` module
for production profiles. The config must not call BSD- or GNU-only commands, so it
behaves the same on macOS and Linux.

**Owns:** `home/dot_config/starship.toml`.

**Done when:** `scripts/test.sh` passes, and `starship prompt` (installed into
`./.bin` for the test only) shows a red segment with
`AWS_VAULT=cleardata AWS_PROFILE=cleardata` and a time remaining when
`AWS_CREDENTIAL_EXPIRATION` is an hour ahead.

---

### T8. Git and GitHub CLI

**Depends on:** T3.

**Goal:** commits are signed with 1Password on every platform that has it, and one
git config serves all three platforms.

**Port from `main`:** `.config/git/config` (identity, SSH signing,
`commit.gpgsign`, `push.autoSetupRemote`, `pull.rebase`, `init.defaultBranch`) and
`.config/gh/config.yml` (`git_protocol: ssh`, `co` alias). Do not port
`.config/gh/hosts.yml`: gh writes it at login, and on Linux without a keyring it
can contain the token.

**Do:**

1. `home/dot_config/git/config.tmpl`:
   - identity and signing key from data;
   - `gpg.ssh.program` per platform: the 1Password app's `op-ssh-sign` on
     `darwin`, the Linux app path on non-headless `linux`, and
     `op-ssh-sign-wsl` under `/mnt/c/Users/{{ .windowsUser }}/...` on `wsl`.
     Confirm paths in 1Password's developer docs (Git commit signing, and the WSL
     integration page);
   - `commit.gpgsign` true only where a signer exists (false when `headless`);
   - GitHub credentials through `gh auth git-credential` on every platform
     instead of `osxkeychain`;
   - on `wsl`, `core.sshCommand` set to Windows `ssh.exe` if 1Password's WSL docs
     still recommend it;
   - `[includeIf "gitdir:~/git/strata/"] path = work` when `.work` is true;
   - `[include] path = ~/.gitconfig.local` last.
2. `home/dot_config/git/work.tmpl`: work email and `workSigningKey`, rendered
   only when `.work` is true.
3. `home/dot_config/git/ignore`: `.DS_Store` and editor swap files.
4. `home/dot_config/gh/config.yml`: only the settings that differ from defaults.

**Owns:** `home/dot_config/git/`, `home/dot_config/gh/`.

**Done when:** `scripts/test.sh` passes, `git config --file <rendered> --get
gpg.ssh.program` returns the right path for each profile, and the linux (headless)
profile has signing off.

---

### T9. SSH agent

**Depends on:** T3.

**Goal:** `ssh` and `git` use the 1Password SSH agent on each platform, with no
background process started from the shell.

**Port from `main`:** the macOS socket path in `.config/zsh/.zshrc`. Do not port
the `socat`/`npiperelay` relay in `.config/includes/linux.sh`.

**Do:**

1. `home/private_dot_ssh/config.tmpl`: `Include ~/.ssh/config.local` first, then
   `Host *` with `IdentityAgent` set to the 1Password socket on `darwin` and on
   non-headless `linux`.
2. On `wsl`, follow 1Password's WSL integration docs. At the time of writing they
   use Windows `ssh.exe` rather than a socket relay. If that is still the
   recommendation, put an `ssh` alias for `ssh.exe` in
   `home/dot_config/zsh/conf.d/40-wsl.zsh.tmpl` (rendered only on `wsl`). Task 8
   sets git's `core.sshCommand` from the same docs.
3. Do not manage keys, `known_hosts`, or `authorized_keys`.

**Owns:** `home/private_dot_ssh/`, `home/dot_config/zsh/conf.d/40-wsl.zsh.tmpl`.

**Done when:** `scripts/test.sh` passes, the rendered `~/.ssh/config` has mode
`0600`, and each profile names the correct agent (or none on headless linux).

---

### T10. Small tool configs

**Depends on:** T3.

**Port from `main`:**

- `.config/vim/vimrc` to `home/dot_vimrc` (vim reads `~/.vimrc` without extra
  environment variables).
- `.config/.sqliterc` to `home/dot_sqliterc` (sqlite reads `~/.sqliterc` by
  default).
- From `.config/ipython/profile_default/ipython_config.py`, only the uncommented
  lines, to `home/dot_ipython/profile_default/ipython_config.py`.
- Nothing from `.config/.pythonstartup.py` or `.config/includes/strata.sh`; both
  are empty on `main`.

**Owns:** `home/dot_vimrc`, `home/dot_sqliterc`, `home/dot_ipython/`.

**Done when:** `scripts/test.sh` passes and the three files appear in every
profile's output.

---

### T11. Cursor skills

**Depends on:** T3.

**Port from `main`:** `.config/cursor/User/skills/model-selection-advisor/SKILL.md`,
which is the only skill written for this repo.

**Do:**

1. Confirm in Cursor's documentation where personal skills load from. The plan
   assumes `~/.cursor/skills/<name>/SKILL.md` on both macOS and Linux.
2. Put `model-selection-advisor` there under `home/`.
3. `gh-stack` (from `github/gh-stack`, tag `v0.1.0`, path `skills/gh-stack`) and
   `daisyui` (from <https://daisyui.com/SKILL.md>) are upstream. If the user keeps
   them (see Open questions), fetch them with `home/.chezmoiexternal.toml` pinned
   to a version, with a `refreshPeriod`. Do not copy their files into the repo.

**Owns:** `home/dot_cursor/`, `home/.chezmoiexternal.toml`.

**Done when:** `scripts/test.sh` passes. Externals may need
`--refresh-externals=never` or network access in the harness; report which.

---

### T12. Bootstrap and README

**Depends on:** T4 through T11.

**Do:**

1. `install.sh` at the repo root (outside `home/`, so it is never applied): a short
   wrapper that installs chezmoi to `~/.local/bin` and runs
   `chezmoi init --apply mnitchie`, accepting `--branch <name>` so a branch can be
   tested on a real machine before merging.
2. Rewrite `README.md`: new-machine setup; daily operations (`edit`, `diff`,
   `apply`, `update`, `re-add`, `chezmoi cd`) linked to the chezmoi docs; how to
   add a package; how to add a file for one platform; where secrets and local
   overrides go; how to run `scripts/test.sh`. No long background section.

**Owns:** `install.sh`, `README.md`.

**Done when:** `shellcheck install.sh` passes and every command in the README
exists in the current chezmoi CLI.

---

### T13. CI

**Depends on:** T2 (can run any time after it; best after T12).

**Do:** `.github/workflows/test.yml` runs `scripts/dev-setup.sh` and
`scripts/test.sh` on `ubuntu-latest` and `macos-latest` for pushes and pull
requests. On the macOS job, also run a real `chezmoi init` render (not apply) with
the prompts answered by flags, so the darwin branch of `home/.chezmoi.toml.tmpl` is
exercised by a real Mac. `scripts/dev-setup.sh` must use `brew` instead of `apt`
on macOS; report the change needed if Task 2's script doesn't handle that.

**Owns:** `.github/`.

**Done when:** the workflow passes on the PR for this branch.

---

### T14. End-to-end on a fresh user

**Depends on:** T12.

**Goal:** prove the real bootstrap on this Linux VM, including scripts.

**Do:**

1. Create a throwaway user with sudo (`useradd -m -s /bin/bash dottest`, passwordless
   sudo for the test).
2. As that user, run `install.sh --branch cursor/chezmoi-rebuild-a64c`, answering
   the prompts as a personal, non-work, headless Linux machine.
3. Check: `zsh -i -c exit` is clean, `brew`, `gh`, `bat`, `eza`, `starship`, and `uv`
   are on `PATH` in a new login shell and in a non-login shell, and
   `git config --get user.email` is correct.
4. Run `chezmoi apply` a second time and check that no script runs again and
   `chezmoi status` is empty.
5. Add a formula to `packages.yaml` in the test user's source dir, run
   `chezmoi apply`, and check only the package script ran. Revert.
6. Delete the user.

**Owns:** nothing in the repo. Report bugs back to the task that owns the file.

**Done when:** all checks pass, or the report lists each failure with the owning
task.

---

### T15. Cutover notes and cleanup

**Depends on:** T14.

**Do:**

1. Add a README section on moving an existing machine off the bare repo: list
   tracked files with
   `git --git-dir=$HOME/.my_dotfiles_git --work-tree=$HOME ls-files`, move
   `~/.my_dotfiles_git` and the old `~/.config/zsh/`, `~/.oh-my-zsh`, and the old
   `~/.zshenv` aside, then run the one-liner. Stale files under `~/.config/zsh/` are
   harmless once `~/.zshenv` no longer sets `ZDOTDIR`.
2. Delete `PLAN.md`.

**Owns:** `README.md` (this section only), `PLAN.md`.

**Done when:** the repo matches "Target layout" minus `PLAN.md`.

## Open questions

Each has a default the tasks will follow unless you say otherwise.

1. **Node version manager.** `main` loads nvm. Default: drop it, and install `node`
   from Homebrew only if you still need it. Alternative: `fnm` or `mise`.
2. **aws-vault.** The 99designs project is archived. Default: keep it if Homebrew
   still ships a maintained build; otherwise drop it and rely on
   `aws sso login` / `aws configure export-credentials`. Task 7's prompt still
   reads `AWS_PROFILE`.
3. **Upstream Cursor skills.** Default: fetch `gh-stack` with
   `.chezmoiexternal.toml`; drop `daisyui`, which tells the agent to load it for
   any HTML.
4. **iTerm2 profile.** Default: drop it. The plist is an app export that iTerm
   rewrites itself. Add a terminal config later if you settle on one that works on
   both platforms.
5. **Strata.** Default: keep the `work` flag, the work signing key, and the `cd`
   aliases behind it. Say if that job is over and the flag can go.
6. **Linux hosts.** Default: WSL on Ubuntu and headless Ubuntu servers. Say if a
   Linux desktop with the 1Password app is also a target.
