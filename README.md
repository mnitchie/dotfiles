# Dotfiles

Personal machine setup managed with [chezmoi](https://www.chezmoi.io/). A single `chezmoi init --apply` installs Homebrew, CLI tools, shell, git, SSH, and editor config as real files under `$HOME` (copy mode, not symlinks). Supported platforms: **Apple Silicon macOS** (Intel Macs are refused at init), **Linux** (headless server or desktop with 1Password), and **WSL**.

## New machine

**Before the one-liner:** for work secrets, set up 1Password first — or leave the work account prompt blank and secrets are skipped. Chezmoi renders templates before `run_before_` install scripts, and `onepasswordRead` runs only when `op` is already available. If the CLI is missing, that apply installs it and skips work secrets. Run `chezmoi apply` again once `op` can sign in.

| Platform | 1Password before the apply that reads secrets |
| --- | --- |
| macOS, Linux desktop | Desktop app installed and signed in; **Integrate with 1Password CLI** and the SSH agent enabled in the app. Homebrew (macOS) or apt (Linux) installs the CLI |
| Headless Linux | If you will enter a work account at init, run [`op account add`](https://developer.1password.com/docs/cli/get-started/) before the apply that reads secrets. The first apply installs the CLI when it is missing; add the account after that, then apply again. Otherwise leave the prompt blank |
| WSL | [1Password CLI on Windows](https://developer.1password.com/docs/cli/get-started/) (e.g. `winget install AgileBits.1Password.CLI`); enable CLI integration in the Windows 1Password app (chezmoi uses `op.exe`, not Linux `op`, and does not install it) |

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin" -- --use-builtin-git=true init --apply mnitchie
```

The installer puts `chezmoi` in `~/.local/bin`; update it later with `chezmoi upgrade`. `mnitchie` resolves to [github.com/mnitchie/dotfiles](https://github.com/mnitchie/dotfiles). The `--` after `-b` passes the rest of the flags to chezmoi; put `--use-builtin-git=true` before `init` so a Mac without Command Line Tools can still clone (Homebrew installs the CLT during apply). Add `--branch <name>` after `init` to test an unmerged branch.

`chezmoi init` runs `home/.chezmoi.toml.tmpl` and asks once (via `prompt*Once`). Bool prompts have no default — answer **y** or **n**:

| Prompt | When | Notes |
| --- | --- | --- |
| Work machine | always | |
| Work email | if work | |
| Work 1Password account sign-in address (blank to skip work secrets) | if work | Example: `employee.1password.com` |
| Headless Linux (no 1Password app) | Linux only | **y** disables git commit signing and the 1Password SSH agent |
| Windows user folder name | WSL only | Folder name under `C:\Users\` (spaces allowed) |

On **macOS**, install the **1Password desktop app** separately (from [1Password](https://1password.com/) or the Mac App Store). Git commit signing and the SSH agent use the app’s `op-ssh-sign`; Homebrew only installs the **1Password CLI** (`op`). The first Homebrew install may also prompt for **sudo** and **Xcode Command Line Tools**. On **Linux and WSL**, **apt** and Homebrew setup may prompt for **sudo**.

## Daily use

See the chezmoi [daily operations](https://www.chezmoi.io/user-guide/daily-operations/) guide. Edits belong in the **source** tree (`home/`): use `chezmoi cd` or `chezmoi edit` with **destination** paths (e.g. `~/.config/fish/config.fish`).

| Command | Purpose |
| --- | --- |
| `chezmoi edit <target>` | Edit source for a destination file |
| `chezmoi diff` | Show pending changes |
| `chezmoi apply` | Apply the source state to `$HOME` |
| `chezmoi update` | Pull the source repo and apply |
| `chezmoi re-add` | Copy non-template files you changed under `$HOME` back into the source |
| `chezmoi cd` | Shell in the source directory |

`chezmoi re-add` updates plain files, including `~/.config/fish/config.fish`. Templates stay on `chezmoi edit` (`~/.config/git/config`, `~/.ssh/config`, `work.fish`, `work-secrets.fish`, and the other `*.tmpl` sources). Do not re-add `~/.config/fish/fish_variables`; fish rewrites that file itself.

**`editf`** → `chezmoi edit --apply ~/.config/fish/config.fish`; **`reloadf`** → `exec fish`.

Layout: `.chezmoiroot` points at `home/` in this repo. Chezmoi manages `~/.ssh`, `~/.config`, `~/.agents`, and on non-headless Linux desktop `~/.local/share/fonts` (JetBrainsMono Nerd Font).

## Fish

Fish is the login shell. On apply, the login-shell script adds Homebrew's `fish` to `/etc/shells` if needed and switches the user shell to it (`dscl` on macOS, `chsh` on Linux and WSL). That binary is `/opt/homebrew/bin/fish` on macOS and `/home/linuxbrew/.linuxbrew/bin/fish` on Linux and WSL.

A login fish puts `~/.local/bin`, then Homebrew's `bin` and `sbin`, in front of `PATH`. On macOS it runs `path_helper` first, because fish does not read `/etc/zprofile`. A non-login fish does not touch `PATH`, so an active virtualenv stays first. `reloadf` starts a non-login shell.

Every fish sets the XDG directories, `EDITOR`, `PAGER`, the Homebrew variables, and the Python, less, psql, and sqlite history paths. Interactive startup wires starship, zoxide (`cd`), fnm, fzf (when stdin is a terminal), and uv / op completions. Syntax highlighting and autosuggestions are built in. `df`, `du`, `find`, and `grep` print a nudge toward `duf`, `dust`, `fd`, and `rg`.

`~/.config/fish/config.fish` is the entry point. Fish sources `~/.config/fish/conf.d/*.fish` before that (environment, aliases, command nudges, plus the darwin, WSL, work, and work-secrets files when those templates apply). `~/.config/fish/local.fish`, when present, is sourced last and is not managed. Fish maintains `~/.config/fish/fish_variables`; leave it out of the source repo.

## Add a Homebrew package

Edit `home/.chezmoidata/packages.yaml` in the source (via `chezmoi edit` or after `chezmoi cd`):

- **`brews`** — all platforms (`brew bundle` in `run_onchange_before_10-install-packages.sh.tmpl`)
- **`casks`** — macOS only (e.g. `font-jetbrains-mono-nerd-font`, `1password-cli`)
- **`apt`** — Debian/Ubuntu packages before Homebrew on Linux and WSL
- **`aptLinuxDesktop`** — non-headless Linux only (e.g. `fontconfig`)
- **`uvTools`** — `uv tool install` after Homebrew. `with` packages install into that tool (`llm` with `llm-ollama`). Homebrew’s `llm` formula is not used

Run `chezmoi apply` so the package script re-runs.

## CLI tools

A few of the `brews` in `home/.chezmoidata/packages.yaml` replace everyday commands. Interactive fish aliases `cat` to `bat --paging=never` and `ls` to `eza --icons=always`, and wires zoxide in as `cd`. fzf loads when stdin is a terminal. `df`, `du`, `find`, and `grep` print a nudge toward `duf`, `dust`, `fd`, and `rg`.

### bat

| Command | Purpose |
| --- | --- |
| `bat README.md` | Syntax highlighting and line numbers |
| `bat -r 40:80 file.py` | Print only lines 40–80 |
| `bat --diff file.py` | Lines that differ from the Git index |

### duf

| Command | Purpose |
| --- | --- |
| `duf` | Free space on mounted filesystems |
| `duf -only local` | Local disks only |
| `duf /` | The filesystem that holds `/` |

### dust

| Command | Purpose |
| --- | --- |
| `dust` | Disk used in the current directory, largest first |
| `dust -d 1 ~` | One level under home |
| `dust -n 20` | The 20 largest entries |

### eza

| Command | Purpose |
| --- | --- |
| `ls -la` | Long listing (`ls` is already eza) |
| `eza -lh --git` | Human sizes and git status |
| `eza --tree -L 2` | Two-level tree |

### fzf

| Command | Purpose |
| --- | --- |
| `Ctrl-R` | Fuzzy-search history and paste the line |
| `Ctrl-T` | Fuzzy-find files and paste their paths |
| `Alt-C` | Fuzzy-find a directory and `cd` into it |

On macOS, Option has to send Esc for `Alt-C` (iTerm2: Profiles → Keys → Left Option key → Esc+).

### ripgrep

The binary is `rg`. Searches skip hidden files, binaries, and anything in `.gitignore`.

| Command | Purpose |
| --- | --- |
| `rg TODO` | Search the current tree |
| `rg -t py 'def '` | Python files only |
| `rg -n -C 2 error src/` | Line numbers and two lines of context |

### tldr

Short examples for a command. Homebrew’s `tldr` formula is disabled, so the package is `tlrc`; the binary is still `tldr`. The first run downloads the pages. The cache refreshes on its own after two weeks. Several words are joined with hyphens, so `tldr git checkout` is the `git-checkout` page.

| Command | Purpose |
| --- | --- |
| `tldr tar` | Examples for `tar` |
| `tldr -p osx tar` | The macOS page (platform name is `osx`) |
| `tldr -u` | Refresh the page cache |

### llm

Installed with `uv tool install`, not Homebrew. The binary is `~/.local/bin/llm`. The `llm-ollama` plugin is installed into that same environment (`--with`), so `uv tool upgrade llm` keeps it. `llm models` lists Ollama models while the Ollama app is running.

| Command | Purpose |
| --- | --- |
| `llm models` | List available models |
| `llm 'Hello'` | Send a prompt to the default model |
| `llm keys set openai` | Store an API key |

### zoxide

`cd` with a query jumps to the highest-ranked directory you have already visited. A path that exists is used as-is.

| Command | Purpose |
| --- | --- |
| `cd proj` | Best match for `proj` |
| `cd api rust` | Match on several words |
| `cdi` | Pick from the ranked list with fzf |

## Add a file on one platform only

Add a template under `home/` whose **entire body** is inside `{{- if ... -}}` … `{{- end -}}` (no stray newlines outside the trim markers). Example: `conf.d/20-darwin.fish.tmpl` uses `{{- if eq .platform "darwin" -}}`.

Template **data keys** (other templates use these, not `.chezmoi.os` / `.chezmoi.arch`).

From `home/.chezmoi.toml.tmpl`, written to `~/.config/chezmoi/chezmoi.toml` at `chezmoi init`:

| Key | Meaning |
| --- | --- |
| `platform` | `darwin`, `linux`, or `wsl` |
| `brewPrefix` | Homebrew prefix |
| `headless` | Linux without 1Password desktop app |
| `work` | Work machine |
| `workEmail` | Git email for work repos |
| `opWorkAccount` | Work 1Password account sign-in address (if work; blank skips work secrets) |
| `windowsUser` | `C:\Users\<name>` folder name (WSL) |

From `home/.chezmoidata/`, updated on `chezmoi apply` and `chezmoi update`:

| Key | File | Meaning |
| --- | --- | --- |
| `name`, `email` | `identity.yaml` | Personal git identity |
| `signingKey`, `workSigningKey` | `identity.yaml` | SSH signing public keys |
| `jetbrainsMonoNerdFont` | `fonts.yaml` | Linux desktop Nerd Font URL and checksum |

A config file created before this split can still contain `name`, `email`, `signingKey`, and `workSigningKey`. Those config values override `.chezmoidata`. Run `chezmoi update --init` once; `prompt*Once` keeps the answers already stored.

Skip a whole directory on some machines by listing it in `home/.chezmoiignore` (patterns are templates even without `.tmpl`). Keep a single file's platform differences inside an `{{- if -}}` body so an empty render removes the file.

## Work config

When **Work machine** is true, apply produces:

- `~/.config/fish/conf.d/work.fish` (from `home/dot_config/fish/conf.d/work.fish.tmpl`)
- `~/.config/fish/conf.d/work-secrets.fish` (from `private_work-secrets.fish.tmpl`, when `opWorkAccount` is set and `op` is already installed)
- `~/.config/git/work`
- `[includeIf "gitdir:~/git/strata/"]` → `work` in git config

When a job ends, in the **source**: clear `work.fish.tmpl`. Fish sources every `*.fish` file in `conf.d`, so old config has to leave that directory. Remove `private_work-secrets.fish.tmpl` as well if those secrets should stop being exported.

## Secrets and local overrides

Nothing secret is committed. Templates may use `onepasswordRead` for 1Password values.

### Work secrets

On work machines with `opWorkAccount` set and `op` already installed, `chezmoi apply` reads three items from the **Private** vault in your **work** 1Password account (the sign-in address you set as `opWorkAccount` at init — not the Private vault on a personal account). `op read` resolves vault name, item title, then field label, so item type does not matter (a Login item with added custom fields works). Each item needs these field labels. Labels must be unique within the item, and item titles must be unique in the vault.

| Item | Field labels |
| --- | --- |
| **Gemfury** | `credential` |
| **Cloudflare** | `credential` |
| **Google Stitch** | `credential` |

That renders `~/.config/fish/conf.d/work-secrets.fish` (mode 0600) with `FURY_AUTH`, `UV_INDEX_GEMFURY_USERNAME`, `UV_INDEX_GEMFURY_PASSWORD` (`NOPASS`), `CLOUDFLARE_API_TOKEN`, and `GOOGLE_STITCH_API_KEY`. Chezmoi runs `op` (or `op.exe` on WSL) while rendering the template. With the desktop app and CLI integration enabled, approve the app prompt (Touch ID on macOS, Windows or Linux app authentication). On headless Linux (no app), run `op account add` before that render; chezmoi then runs `op signin`, which asks for the account password in the terminal. When `op` is not installed yet, the secrets file is left absent and the package script installs the CLI; apply again after `op` can sign in.

Not managed by chezmoi — create on the machine:

| File | Role |
| --- | --- |
| `~/.config/fish/local.fish` | Extra fish (sourced last, interactive) |
| `~/.config/git/local` | Git overrides |
| `~/.ssh/config.local` | SSH overrides on macOS / Linux desktop |

On **WSL**, `ssh` and git use Windows `ssh.exe`. Linux `~/.ssh/config` and `config.local` are **not** read. Put SSH **host** entries in `%USERPROFILE%\.ssh\config` on Windows.

## Terminal font (JetBrainsMono Nerd Font)

Starship needs a [Nerd Font](https://www.nerdfonts.com/). Use **JetBrainsMono Nerd Font** in the terminal you type into.

| Platform | Install | Set in terminal |
| --- | --- | --- |
| macOS | Cask `font-jetbrains-mono-nerd-font` | Terminal.app, iTerm2, etc. |
| Linux desktop | `~/.local/share/fonts/JetBrainsMonoNerdFont` via `.chezmoiexternal.toml.tmpl` (pin in `.chezmoidata/fonts.yaml`) | Desktop terminal |
| WSL | Windows: `winget install --id DEVCOM.JetBrainsMonoNerdFont` or [nerdfonts.com](https://www.nerdfonts.com/) | Windows Terminal → Font |
| Linux server | — | Font on the SSH client machine |

## Externals

`home/.chezmoiexternal.toml.tmpl` fetches at apply time:

- `~/.agents/skills/gh-stack/`
- Linux desktop Nerd Font, pinned in `home/.chezmoidata/fonts.yaml`

## CI

[`.github/workflows/bootstrap.yml`](.github/workflows/bootstrap.yml) runs on pull requests and on pushes to `main`, on `ubuntu-latest` and `macos-latest`. It runs the one-liner above with `--branch` and non-interactive answers for the prompts that machine asks, checks that a second `chezmoi apply` changes nothing, and smoke-tests login fish, a nested non-login fish, core CLI tools, and the delta pager.
