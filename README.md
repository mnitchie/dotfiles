# Dotfiles

Personal dotfiles managed with [chezmoi](https://www.chezmoi.io/). One command installs a package manager, CLI tools, fish, and config.

| Platform | Packages | fish |
| --- | --- | --- |
| macOS, Apple Silicon | Homebrew | `/opt/homebrew/bin/fish` |
| macOS, Intel (Sequoia 15, Tahoe 26) | MacPorts | `/opt/local/bin/fish` |
| Debian/Ubuntu, Fedora (desktop or headless) | apt or dnf, then Homebrew | `/home/linuxbrew/.linuxbrew/bin/fish` |
| WSL (Debian-family) | apt, then Homebrew | `/home/linuxbrew/.linuxbrew/bin/fish` |

## Install

**1. Set up 1Password** (skip if you won't use work secrets):

| Platform | Before installing |
| --- | --- |
| macOS, Linux desktop | Install the [desktop app](https://1password.com/), sign in, and enable **Integrate with 1Password CLI** and the SSH agent. The CLI is installed for you |
| Headless Linux | After the first apply installs `op`, run [`op account add`](https://developer.1password.com/docs/cli/get-started/), then apply again |
| WSL | On Windows: `winget install AgileBits.1Password.CLI` and enable CLI integration in the app. chezmoi uses `op.exe` |

**2. Run:**

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin" -- --use-builtin-git=true init --apply mnitchie
```

Add `--branch <name>` after `init` to test a branch. Expect sudo prompts, and on macOS a Command Line Tools install.

**3. Answer the prompts** (asked once, answer **y**/**n**):

| Prompt | Asked | Notes |
| --- | --- | --- |
| Work machine | always | |
| Work email | work | |
| Work 1Password account sign-in address | work | e.g. `employee.1password.com`. Blank skips work secrets |
| Headless Linux (no 1Password app) | Linux | **y** disables commit signing and the 1Password SSH agent |
| Windows user folder name | WSL | Folder under `C:\Users\` |

If `op` wasn't installed yet, secrets are skipped on the first run. Run `chezmoi apply` again after signing in.

## Daily use

| Command | Purpose |
| --- | --- |
| `chezmoi edit <target>` | Edit the source of a file, e.g. `~/.config/fish/config.fish` |
| `chezmoi diff` | Show pending changes |
| `chezmoi apply` | Apply the source to `$HOME` |
| `chezmoi update` | Pull this repo and apply |
| `chezmoi re-add` | Copy changes to plain (non-template) files back into the source |
| `chezmoi cd` | Shell in the source directory (`home/` is the source root) |
| `chezmoi update --init` | Regenerate config after the prompts change (fixes `map has no entry for key`) |
| `chezmoi update --refresh-externals` | Re-download externals now instead of weekly |
| `editf` | Edit and apply `config.fish` |
| `reloadf` | `exec fish` |

Use `re-add` for plain files and `edit` for `.tmpl` files. Don't add `~/.config/fish/fish_variables`.

## Packages

Edit `home/.chezmoidata/packages.yaml`, then `chezmoi apply`.

| Key | Installs on |
| --- | --- |
| `brews` | Everywhere (`brew`, or `port` on Intel macOS) |
| `casks` | Apple Silicon macOS |
| `ports` | Intel macOS, in place of casks |
| `portNames` | Intel macOS: port name when it differs from the brew (`awscli: py314-awscli2`). Look up names at [ports.macports.org](https://ports.macports.org/) |
| `portSelect` | Intel macOS: `port select --set` for versioned commands (`aws`) |
| `apt`, `aptLinuxDesktop` | Debian/Ubuntu/WSL, before Homebrew. `LinuxDesktop` skips headless |
| `dnf`, `dnfGroups`, `dnfLinuxDesktop` | Fedora, before Homebrew |
| `uvTools` | `uv tool install`, with optional `with` plugins (`llm` + `llm-ollama`) |

Other Linux distributions stop with an error.

### Intel Macs

Homebrew [no longer builds Intel packages](https://docs.brew.sh/Support-Tiers#future-macos-support) and stops running on Intel in September 2027, so Intel Macs get MacPorts in `/opt/local`. It's picked automatically.

- The installer is pinned and checksummed in `home/.chezmoidata/macports.yaml`. Add an entry there for a new macOS version.
- Ports without a prebuilt binary compile from source, so the first install can be slow.
- Update everything with `sudo port selfupdate && sudo port upgrade outdated`.

## CLI tools

In interactive fish, `cat` is `bat`, `ls` is `eza`, and `cd` is zoxide. `df`, `du`, `find`, and `grep` suggest `duf`, `dust`, `fd`, and `rg`. Starship, fzf, fnm, and uv/op completions load automatically. `history` shows timestamps.

### bat

| Command | Purpose |
| --- | --- |
| `bat README.md` | Syntax highlighting and line numbers |
| `bat -r 40:80 file.py` | Lines 40–80 only |
| `bat --diff file.py` | Lines that differ from the Git index |

### duf

| Command | Purpose |
| --- | --- |
| `duf` | Free space on mounted filesystems |
| `duf -only local` | Local disks only |
| `duf /` | The filesystem holding `/` |

### dust

| Command | Purpose |
| --- | --- |
| `dust` | Disk use in the current directory, largest first |
| `dust -d 1 ~` | One level under home |
| `dust -n 20` | The 20 largest entries |

### eza

| Command | Purpose |
| --- | --- |
| `ls -la` | Long listing |
| `eza -lh --git` | Human sizes and git status |
| `eza --tree -L 2` | Two-level tree |

### fd

Includes hidden files. Add `--no-ignore` to also search gitignored files.

| Command | Purpose |
| --- | --- |
| `fd config` | Paths matching `config` |
| `fd -e md` | Markdown files |
| `fd -t d src` | Directories only |

### fzf

| Key | Purpose |
| --- | --- |
| `Ctrl-R` | Search history |
| `Ctrl-T` | Find files and paste their paths |
| `Alt-C` | Find a directory and `cd` into it (macOS: set Option to send Esc+) |

### ripgrep (`rg`)

Skips hidden files, binaries, and gitignored files.

| Command | Purpose |
| --- | --- |
| `rg TODO` | Search the current tree |
| `rg -t py 'def '` | Python files only |
| `rg -n -C 2 error src/` | Line numbers and two lines of context |

### tldr

| Command | Purpose |
| --- | --- |
| `tldr tar` | Examples for `tar` |
| `tldr git checkout` | Subcommand page |
| `tldr -p osx tar` | The macOS page |
| `tldr -u` | Refresh the page cache |

### llm

Installed with uv; `uv tool upgrade llm` keeps the Ollama plugin.

| Command | Purpose |
| --- | --- |
| `llm models` | List models (Ollama must be running for local ones) |
| `llm 'Hello'` | Prompt the default model |
| `llm keys set openai` | Store an API key |

### zoxide

| Command | Purpose |
| --- | --- |
| `cd proj` | Best-ranked match for `proj` (existing paths work as usual) |
| `cd api rust` | Match several words |
| `cdi` | Pick from the ranked list with fzf |

## Customizing

### Local overrides (not managed)

| File | Purpose |
| --- | --- |
| `~/.config/fish/local.fish` | Extra fish config, sourced last |
| `~/.config/git/local` | Git overrides |
| `~/.ssh/config.local` | SSH overrides (macOS, Linux desktop) |

On WSL, git and `ssh` use Windows `ssh.exe`, so put SSH hosts in `%USERPROFILE%\.ssh\config`.

### Platform-only files

Wrap the **entire** template body in a condition. An empty render removes the file:

```
{{- if eq .platform "darwin" -}}
...
{{- end -}}
```

To skip a whole directory, list it in `home/.chezmoiignore`.

### Template data

| Key | Source | Value |
| --- | --- | --- |
| `platform` | prompts | `darwin`, `linux`, or `wsl` |
| `packageManager` | prompts | `homebrew` or `macports` |
| `packagePrefix` | prompts | `/opt/homebrew`, `/opt/local`, or `/home/linuxbrew/.linuxbrew` |
| `headless`, `work`, `workEmail`, `opWorkAccount`, `windowsUser` | prompts | Your answers |
| `name`, `email`, `signingKey`, `workSigningKey` | `.chezmoidata/identity.yaml` | Git identity and SSH signing keys |
| `jetbrainsMonoNerdFont` | `.chezmoidata/fonts.yaml` | Pinned font URL and checksum |
| `macports` | `.chezmoidata/macports.yaml` | Pinned MacPorts installer |

"Prompts" values live in `~/.config/chezmoi/chezmoi.toml`, generated from `home/.chezmoi.toml.tmpl`.

## Work machines

With **Work machine** set, apply adds `~/.config/fish/conf.d/work.fish`, `~/.config/git/work`, and git `includeIf` for `~/git/strata/`. To turn it off, set `work = false` in `~/.config/chezmoi/chezmoi.toml` and apply.

Work secrets are read from the work account's **Private** vault into `~/.config/fish/conf.d/work-secrets.fish` (mode 0600):

| 1Password item (field `credential`) | Exported as |
| --- | --- |
| Gemfury | `FURY_AUTH`, `UV_INDEX_GEMFURY_USERNAME` (`UV_INDEX_GEMFURY_PASSWORD=NOPASS`) |
| Cloudflare | `CLOUDFLARE_API_TOKEN` |
| Google Stitch | `GOOGLE_STITCH_API_KEY` |

Nothing secret is committed.

## Terminal font

Starship needs **JetBrainsMono Nerd Font** in your terminal.

| Platform | Installed by |
| --- | --- |
| macOS, Apple Silicon | Homebrew cask |
| macOS Intel, Linux desktop | chezmoi external (pinned in `.chezmoidata/fonts.yaml`) |
| WSL | You: `winget install --id DEVCOM.JetBrainsMonoNerdFont`, then set it in Windows Terminal |
| Linux server | Set it on the SSH client |

## Cursor and agent skills

| What | Source |
| --- | --- |
| Editor settings and keybindings (Cursor, VS Code, macOS) | `home/private_Library/` |
| MCP servers (`~/.cursor/mcp.json`: Stitch, draw.io, Terraform via Docker) | `home/dot_cursor/private_mcp.json` |
| Cursor CLI preferences (merged; login and model choices stay local) | `home/dot_config/cursor/modify_private_cli-config.json` |
| `simplify` skill | `home/dot_agents/skills/` |
| Third-party skills (`gh-stack`, `ponytail`, `pr-lens`, `i-have-adhd`) | `home/.chezmoiexternal.toml.tmpl`, refreshed weekly |

Skills install to `~/.agents/skills/` (plural `.agents`). Stitch's MCP entry reads `GOOGLE_STITCH_API_KEY` from Cursor's environment.

## CI

[Bootstrap CI](.github/workflows/bootstrap.yml) installs each PR on Ubuntu and Apple Silicon macOS. Intel macOS is not tested in CI. It then checks that a second apply changes nothing, and smoke-tests fish and the tools.
