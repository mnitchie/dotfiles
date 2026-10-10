# Dotfiles

Personal dotfiles managed with [chezmoi](https://www.chezmoi.io/). `chezmoi init --apply` installs Homebrew, CLI tools, and configuration under `$HOME`. Supports Apple Silicon macOS, Debian/Ubuntu and Fedora Linux (desktop or headless), and WSL. Intel Macs are not supported.

## New machine

For work secrets, set up 1Password first. Leave the work account prompt blank to skip them. Templates render before install scripts: if the CLI is missing, the first apply skips secrets. Apply again after installing and signing in to the CLI.

| Platform | 1Password before the apply that reads secrets |
| --- | --- |
| macOS, Linux desktop | Desktop app installed and signed in; **Integrate with 1Password CLI** and the SSH agent enabled in the app. Homebrew (macOS), apt (Debian/Ubuntu), or dnf (Fedora) installs the CLI |
| Headless Linux | If you will enter a work account at init, run [`op account add`](https://developer.1password.com/docs/cli/get-started/) before the apply that reads secrets. The first apply installs the CLI when it is missing; add the account after that, then apply again. Otherwise leave the prompt blank |
| WSL | [1Password CLI on Windows](https://developer.1password.com/docs/cli/get-started/) (e.g. `winget install AgileBits.1Password.CLI`); enable CLI integration in the Windows 1Password app (chezmoi uses `op.exe`, not Linux `op`, and does not install it) |

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin" -- --use-builtin-git=true init --apply mnitchie
```

This installs `chezmoi` in `~/.local/bin` and clones [mnitchie/dotfiles](https://github.com/mnitchie/dotfiles). Update chezmoi with `chezmoi upgrade`. Built-in Git allows cloning before macOS Command Line Tools are installed. Add `--branch <name>` after `init` to test a branch.

`chezmoi init` uses `home/.chezmoi.toml.tmpl` to ask these questions once. Answer boolean prompts with **y** or **n**:

| Prompt | When | Notes |
| --- | --- | --- |
| Work machine | always | |
| Work email | if work | |
| Work 1Password account sign-in address (blank to skip work secrets) | if work | Example: `employee.1password.com` |
| Headless Linux (no 1Password app) | Linux only, including Fedora | **n** on a desktop, including Fedora Workstation. **y** disables git commit signing and the 1Password SSH agent |
| Windows user folder name | WSL only | Folder name under `C:\Users\` (spaces allowed) |

Install the [1Password desktop app](https://1password.com/) separately on macOS; Git signing and SSH use it. Homebrew installs only the CLI. Bootstrap may prompt for sudo and, on macOS, Command Line Tools.

## Daily use

Edit sources under `home/`. `chezmoi edit` accepts destination paths, such as `~/.config/fish/config.fish`. See [daily operations](https://www.chezmoi.io/user-guide/daily-operations/).

| Command | Purpose |
| --- | --- |
| `chezmoi edit <target>` | Edit source for a destination file |
| `chezmoi diff` | Show pending changes |
| `chezmoi apply` | Apply the source state to `$HOME` |
| `chezmoi update` | Pull the source repo and apply |
| `chezmoi re-add` | Copy non-template files you changed under `$HOME` back into the source |
| `chezmoi cd` | Shell in the source directory |

Use `chezmoi re-add` for plain files and `chezmoi edit` for templates. Do not add `~/.config/fish/fish_variables`; fish manages it.

**`editf`** → `chezmoi edit --apply ~/.config/fish/config.fish`; **`reloadf`** → `exec fish`.

`.chezmoiroot` sets `home/` as the source root.

## Fish

Bootstrap registers Homebrew’s fish in `/etc/shells` and sets it as the login shell (`dscl` on macOS, `chsh` on Linux/WSL). It uses `/opt/homebrew/bin/fish` on macOS and `/home/linuxbrew/.linuxbrew/bin/fish` on Linux/WSL.

Login shells prepend `~/.local/bin` and Homebrew’s `bin` and `sbin` to `PATH`. macOS system paths come from `path_helper`, since fish does not read `/etc/zprofile`. Non-login shells inherit PATH; fnm adds its Node.js directory during interactive startup. `reloadf` starts a non-login shell.

All shells set XDG directories, tool environment variables, and history paths. Interactive shells load Starship, zoxide (`cd`), fnm, fzf, and uv/op completions. Fish provides syntax highlighting and autosuggestions.

Plain `history` and fzf’s `Ctrl-R` view show readable dates and times.

Fish loads `conf.d/*.fish` before `config.fish`. Interactive shells source unmanaged `~/.config/fish/local.fish` last.

## Add a Homebrew package

Run `chezmoi cd`, then edit `home/.chezmoidata/packages.yaml`:

- **`brews`** — all platforms (`brew bundle` in `run_onchange_before_10-install-packages.sh.tmpl`)
- **`casks`** — macOS only (e.g. `font-jetbrains-mono-nerd-font`, `1password-cli`)
- **`apt`** — Debian/Ubuntu packages before Homebrew on Linux and WSL
- **`aptLinuxDesktop`** — non-headless Debian/Ubuntu only (e.g. `fontconfig`)
- **`dnfGroups`** and **`dnf`** — Fedora packages before Homebrew. `dnfGroups` entries are `dnf group install` groups (Homebrew’s `development-tools`)
- **`dnfLinuxDesktop`** — non-headless Fedora only (e.g. `fontconfig`)
- **`uvTools`** — `uv tool install` after Homebrew. `with` packages install into that tool (`llm` with `llm-ollama`). Homebrew’s `llm` formula is not used

Debian-family Linux (`ID` of `debian` or `ubuntu`, or `ID_LIKE` containing `debian`) uses apt. Fedora (`ID=fedora`) uses dnf. Other distributions stop during apply. WSL keeps using apt when its `/etc/os-release` is Debian-family, and still uses Windows `op.exe`.

Run `chezmoi apply` so the package script re-runs.

## CLI tools

Interactive fish uses `bat --paging=never` for `cat`, `eza --icons=always --total-size` for `ls`, and zoxide for `cd`. fzf key bindings load when stdin is a terminal. `df`, `du`, `find`, and `grep` suggest `duf`, `dust`, `fd`, and `rg` on stderr.

`fd` includes hidden files by default and prints a reminder on stderr to add
`--no-ignore` when you also want files excluded by ignore rules.

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

Command examples, provided by `tlrc` as `tldr`. Pages download on first use and refresh automatically. Use `tldr git checkout` for the `git-checkout` page.

| Command | Purpose |
| --- | --- |
| `tldr tar` | Examples for `tar` |
| `tldr -p osx tar` | The macOS page (platform name is `osx`) |
| `tldr -u` | Refresh the page cache |

### llm

Installed at `~/.local/bin/llm` with `uv tool install --with llm-ollama`. `uv tool upgrade llm` preserves the plugin. Run Ollama to list its models.

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

Templates use these data keys:

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

Older chezmoi configs may override identity data. Run `chezmoi update --init` to regenerate the config while keeping stored prompt answers.

Skip a whole directory on some machines by listing it in `home/.chezmoiignore` (patterns are templates even without `.tmpl`). Keep a single file's platform differences inside an `{{- if -}}` body so an empty render removes the file.

## Work config

When **Work machine** is true, apply produces:

- `~/.config/fish/conf.d/work.fish` (from `home/dot_config/fish/conf.d/work.fish.tmpl`)
- `~/.config/fish/conf.d/work-secrets.fish` (from `private_work-secrets.fish.tmpl`, when `opWorkAccount` is set and `op` is already installed)
- `~/.config/git/work`
- `[includeIf "gitdir:~/git/strata/"]` → `work` in git config

When a job ends, set `work = false` in `~/.config/chezmoi/chezmoi.toml` and apply. Work templates render empty, removing their destination files.

## Secrets and local overrides

Nothing secret is committed. Templates may use `onepasswordRead` for 1Password values.

Cursor's global MCP config is managed at `~/.cursor/mcp.json` by `home/dot_cursor/private_mcp.json`. It includes Stitch, draw.io, and Terraform (requires Docker, with operations disabled). Stitch always references `${env:GOOGLE_STITCH_API_KEY}`; Cursor must inherit that variable from its environment. The installed file has mode 0600 (owner read/write only). Edit the source JSON rather than the installed copy; Cursor does not document `~/.agents/mcp.json` as a configuration location.

### Work secrets

With `work = true`, `opWorkAccount` set, and the CLI installed, apply reads these items from the work account’s **Private** vault. Item titles and field labels must be unique. Any item type can hold the fields.

| Item | Field labels |
| --- | --- |
| **Gemfury** | `credential` |
| **Cloudflare** | `credential` |
| **Google Stitch** | `credential` |

The template creates `~/.config/fish/conf.d/work-secrets.fish` with mode 0600 and exports `FURY_AUTH`, `UV_INDEX_GEMFURY_USERNAME`, `UV_INDEX_GEMFURY_PASSWORD` (`NOPASS`), `CLOUDFLARE_API_TOKEN`, and `GOOGLE_STITCH_API_KEY`. Chezmoi authenticates through the desktop app, or `op signin` on headless Linux. WSL uses `op.exe`.

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

- Third-party skills in `~/.agents/skills/`: `gh-stack`,
  `ponytail`, `pr-lens`, and `i-have-adhd`
- Linux desktop Nerd Font, pinned in `home/.chezmoidata/fonts.yaml`

## Cursor CLI

Fish sets `CURSOR_CONFIG_DIR` to `$XDG_CONFIG_HOME/cursor`, so the CLI reads
`~/.config/cursor/cli-config.json` on macOS and Linux/WSL. Preferences are merged
by `home/dot_config/cursor/modify_private_cli-config.json`; edit that source,
then apply. The installed file has mode 0600. Login data, model selections, and
CLI caches remain local and are preserved by the merge.

## User skills

`~/.agents/skills/` is the shared user-level skills directory. Use the plural
`.agents`; clients do not discover `~/.config/agents/` by default. Cursor-managed
built-ins and plugin caches remain owned by their clients.

Third-party skills are declared in `home/.chezmoiexternal.toml.tmpl`, with a
one-week (`168h`) download refresh period. `simplify` is tracked under
`home/dot_agents/skills/`; edit that source, then apply. Install Stitch plugins
through Cursor's marketplace; chezmoi does not manage their skills or caches.

`chezmoi update` pulls this dotfiles repository and applies it. Changing an
external URL downloads the new source. Externals using a moving branch URL
refresh on apply once their cached download is at least a week old; use
`chezmoi update --refresh-externals` to force a download sooner. A pinned release
or commit stays at that version until its URL and checksum are changed.

Keep each user skill installed in one place.

## CI

[Bootstrap CI](.github/workflows/bootstrap.yml) runs on pull requests and pushes to `main`, on Ubuntu and macOS. It installs the branch with non-interactive answers, checks apply idempotence, and smoke-tests fish, CLI tools, and the Git pager.
