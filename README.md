# Dotfiles

Personal machine setup managed with [chezmoi](https://www.chezmoi.io/). A single `chezmoi init --apply` installs Homebrew, CLI tools, shell, git, SSH, and editor config as real files under `$HOME` (copy mode, not symlinks). Supported platforms: **Apple Silicon macOS** (Intel Macs are refused at init), **Linux** (headless server or desktop with 1Password), and **WSL**.

## New machine

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin" init --apply mnitchie
```

The installer puts `chezmoi` in `~/.local/bin`; update it later with `chezmoi upgrade`. `mnitchie` resolves to [github.com/mnitchie/dotfiles](https://github.com/mnitchie/dotfiles). To try a branch before it is merged, add `--branch <name>` (keep `-b "$HOME/.local/bin"` before `init`).

`chezmoi init` runs `home/.chezmoi.toml.tmpl` and asks once (via `prompt*Once`). Bool prompts have no default — answer **y** or **n**:

| Prompt | When | Notes |
| --- | --- | --- |
| Work machine | always | |
| Work email | if work | |
| Work 1Password account sign-in address (blank to skip work secrets) | if work | Example: `employee.1password.com` |
| Headless Linux (no 1Password app) | Linux only | **y** disables git commit signing and the 1Password SSH agent |
| Windows user folder name | WSL only | Folder name under `C:\Users\` (spaces allowed) |

On **macOS**, install the **1Password desktop app** separately (from [1Password](https://1password.com/) or the Mac App Store). Git commit signing and the SSH agent use the app’s `op-ssh-sign`; Homebrew only installs the **1Password CLI** (`op`). The first Homebrew install may also prompt for **sudo** and **Xcode Command Line Tools**. On **Linux and WSL**, **apt** and Homebrew setup may prompt for **sudo**.

## Moving a machine off the old bare repo

The old setup used a bare git repo at `~/.my_dotfiles_git` with `work-tree=$HOME`. Chezmoi replaces that entirely. **Move** old paths aside into a dated backup directory — do not delete them until you are satisfied with the new setup.

1. **See what the old repo tracked** (optional, for your records):

   ```bash
   git --git-dir=$HOME/.my_dotfiles_git --work-tree=$HOME ls-files
   ```

2. **Move the old dotfiles aside** into a backup directory:

   ```bash
   backup=~/dotfiles-backup-$(date +%Y%m%d)
   mkdir -p "$backup"
   [ -e "$HOME/.my_dotfiles_git" ] && mv -n "$HOME/.my_dotfiles_git" "$backup/"
   [ -e "$HOME/.oh-my-zsh" ] && mv -n "$HOME/.oh-my-zsh" "$backup/"
   [ -e "$HOME/.zshenv" ] && mv -n "$HOME/.zshenv" "$backup/"
   [ -e "$HOME/.config/zsh" ] && mv -n "$HOME/.config/zsh" "$backup/"
   [ -e "$HOME/.config/includes" ] && mv -n "$HOME/.config/includes" "$backup/"
   [ -e "$HOME/.vimrc" ] && mv -n "$HOME/.vimrc" "$backup/"
   [ -d "$HOME/.vim" ] && mv -n "$HOME/.vim" "$backup/"
   [ -e "$HOME/.config/git/config" ] && mv -n "$HOME/.config/git/config" "$backup/"
   [ -e "$HOME/.config/gh/config.yml" ] && mv -n "$HOME/.config/gh/config.yml" "$backup/"
   ```

   If you had secrets in `~/.config/includes/secrets.sh`, copy that file somewhere private before or after the move. Chezmoi does **not** recreate it — use 1Password or `~/.config/zsh/local.zsh` for secrets going forward.

   Leave `~/.config/gh/hosts.yml` in place (GitHub login state). On **WSL**, you no longer need any old `socat` / `npiperelay` SSH-agent relay from the previous Linux includes.

3. **Carry over zsh history** to the new `HISTFILE` (`~/.local/state/zsh/history`). The old setup did not set `HISTFILE`; oh-my-zsh/zsh wrote `~/.zsh_history` and sometimes `$ZDOTDIR/.zsh_history` (`~/.config/zsh/.zsh_history`). Step 2 moved `~/.config/zsh` into `$backup`, so look at `~/.zsh_history` and `$backup/zsh/.zsh_history` (reuse the same `backup=...` as step 2 if you are in a new shell):

   ```bash
   backup=~/dotfiles-backup-$(date +%Y%m%d)
   mkdir -p "$HOME/.local/state/zsh"
   hist="$HOME/.local/state/zsh/history"
   if [ ! -e "$hist" ]; then
     for old in "$HOME/.zsh_history" "$backup/zsh/.zsh_history"; do
       if [ -f "$old" ]; then
         cp -a "$old" "$hist"
         break
       fi
     done
   fi
   ```

   If `$hist` already exists, merge manually or append from the old file instead of overwriting.

4. **Keep existing SSH host entries.** Chezmoi replaces `~/.ssh/config` but `Include`s `~/.ssh/config.local` first. Leave `~/.ssh` keys, `known_hosts`, and `authorized_keys` in place; only rename the config file if you do not already have a local override:

   ```bash
   [ -f "$HOME/.ssh/config" ] && [ ! -e "$HOME/.ssh/config.local" ] && mv "$HOME/.ssh/config" "$HOME/.ssh/config.local"
   ```

5. **Install chezmoi and apply** (same as [New machine](#new-machine)):

   ```bash
   sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin" init --apply mnitchie
   ```

6. Open a **new terminal** and check:

   ```bash
   chezmoi doctor
   chezmoi status
   ```

## Daily use

See the chezmoi [daily operations](https://www.chezmoi.io/user-guide/daily-operations/) guide. Edits belong in the **source** tree (`home/`): use `chezmoi cd` or `chezmoi edit` with **destination** paths (e.g. `~/.config/zsh/.zshrc`).

| Command | Purpose |
| --- | --- |
| `chezmoi edit <target>` | Edit source for a destination file |
| `chezmoi diff` | Show pending changes |
| `chezmoi apply` | Apply the source state to `$HOME` |
| `chezmoi update` | Pull the source repo and apply |
| `chezmoi re-add` | Copy non-template files you changed under `$HOME` back into the source |
| `chezmoi cd` | Shell in the source directory |

`chezmoi re-add` does **not** update templates (including `~/.zshenv`, `~/.config/zsh/.zshrc`, `~/.config/git/config`, `~/.ssh/config`, and `work.zsh`). Use `chezmoi edit` for those.

Aliases (when `chezmoi` / `zsh` are on `PATH`): **`editz`** → `chezmoi edit --apply ~/.config/zsh/.zshrc`; **`reloadz`** → `exec zsh`.

Layout: `.chezmoiroot` points at `home/` in this repo. The only **zsh** file in `$HOME` is `~/.zshenv` (it sets `ZDOTDIR=~/.config/zsh`). Chezmoi also manages under `$HOME`: `~/.ssh`, `~/.config`, `~/.local`, `~/.cache`, and `~/.agents`. `dot_zshrc` loads `conf.d/*.zsh` in order, **skipping** `_*.zsh`, then `local.zsh` if present.

## Add a Homebrew package

Edit `home/.chezmoidata/packages.yaml` in the source (via `chezmoi edit` or after `chezmoi cd`):

- **`brews`** — all platforms (`brew bundle` in `run_onchange_before_10-install-packages.sh.tmpl`)
- **`casks`** — macOS only (e.g. `font-jetbrains-mono-nerd-font`, `1password-cli`)
- **`apt`** — Debian/Ubuntu packages before Homebrew on Linux and WSL
- **`aptLinuxDesktop`** — non-headless Linux only (e.g. `fontconfig`)

Run `chezmoi apply` so the package script re-runs.

## Add a file on one platform only

Add a template under `home/` whose **entire body** is inside `{{- if ... -}}` … `{{- end -}}` (no stray newlines outside the trim markers). Example: `conf.d/20-darwin.zsh.tmpl` uses `{{- if eq .platform "darwin" -}}`.

Template **data keys** (from `home/.chezmoi.toml.tmpl`; other templates use these, not `.chezmoi.os` / `.chezmoi.arch`):

| Key | Meaning |
| --- | --- |
| `platform` | `darwin`, `linux`, or `wsl` |
| `brewPrefix` | Homebrew prefix |
| `headless` | Linux without 1Password desktop app |
| `work` | Work machine |
| `workEmail` | Git email for work repos |
| `opWorkAccount` | Work 1Password account sign-in address (if work; blank skips work secrets) |
| `windowsUser` | `C:\Users\<name>` folder name (WSL) |
| `name`, `email` | Personal git identity |
| `signingKey`, `workSigningKey` | SSH signing public keys |

Use `home/.chezmoiignore` only for whole directories.

## Work config

When **Work machine** is true, apply produces:

- `~/.config/zsh/conf.d/work.zsh` (from `home/dot_config/zsh/conf.d/work.zsh.tmpl`)
- `~/.config/zsh/conf.d/work-secrets.zsh` (from `private_work-secrets.zsh.tmpl`, when `opWorkAccount` is set)
- `~/.config/git/work`
- `[includeIf "gitdir:~/git/strata/"]` → `work` in git config

When a job ends, in the **source**: clear or trim `work.zsh.tmpl` and add `home/dot_config/zsh/conf.d/_<company>.zsh` with the old contents. `_*.zsh` files are never sourced.

## Secrets and local overrides

Nothing secret is committed. Templates may use `onepasswordRead` for 1Password values.

### Work secrets

On work machines with `opWorkAccount` set, `chezmoi apply` reads three items from the **Private** vault in your **work** 1Password account (the sign-in address you set as `opWorkAccount` at init — not the Private vault on a personal account). `op read` resolves vault name, item title, then field label, so item type does not matter (a Login item with added custom fields works). Each item needs these field labels. Labels must be unique within the item, and item titles must be unique in the vault.

| Item | Field labels |
| --- | --- |
| **Gemfury** | `credential`, `org` |
| **Cloudflare** | `credential` |
| **Google Stitch** | `credential` |

That renders `~/.config/zsh/conf.d/work-secrets.zsh` (mode 0600) with `FURY_AUTH`, `UV_INDEX_GEMFURY_USERNAME`, `UV_INDEX_GEMFURY_PASSWORD` (`NOPASS`), `PIP_EXTRA_INDEX_URL`, `CLOUDFLARE_API_TOKEN`, and `GOOGLE_STITCH_API_KEY`. Chezmoi runs `op` during apply. With the 1Password desktop app and CLI integration enabled, approve the app prompt (Touch ID on macOS, system authentication on Linux). On headless Linux (no app), run `op account add` once; chezmoi then runs `op signin`, which asks for the account password in the terminal.

Not managed by chezmoi — create on the machine:

| File | Role |
| --- | --- |
| `~/.config/zsh/local.zsh` | Extra shell (sourced last) |
| `~/.config/git/local` | Git overrides |
| `~/.ssh/config.local` | SSH overrides on macOS / Linux desktop |

On **WSL**, `ssh` and git use Windows `ssh.exe`. Linux `~/.ssh/config` and `config.local` are **not** read. Put SSH **host** entries in `%USERPROFILE%\.ssh\config` on Windows.

## Terminal font (JetBrainsMono Nerd Font)

Starship needs a [Nerd Font](https://www.nerdfonts.com/). Use **JetBrainsMono Nerd Font** in the terminal you type into.

| Platform | Install | Set in terminal |
| --- | --- | --- |
| macOS | Cask `font-jetbrains-mono-nerd-font` | Terminal.app, iTerm2, etc. |
| Linux desktop | `~/.local/share/fonts/JetBrainsMonoNerdFont` via `.chezmoiexternal.toml.tmpl` | Desktop terminal |
| WSL | Windows: `winget install --id DEVCOM.JetBrainsMonoNerdFont` or [nerdfonts.com](https://www.nerdfonts.com/) | Windows Terminal → Font |
| Linux server | — | Font on the SSH client machine |

## Externals

`home/.chezmoiexternal.toml.tmpl` fetches at apply time:

- `~/.agents/skills/gh-stack/`
- Linux desktop Nerd Font (see above)

## Testing

```bash
scripts/install-test-tools.sh
scripts/test.sh
```

`TEST_EXTERNALS=1` includes externals (network). `scripts/test.sh --keep` leaves the render tree for inspection. Profiles: `tests/profiles/`.

**CI:** `.github/workflows/test.yml` on `ubuntu-latest` and `macos-latest` with `TEST_EXTERNALS=1`; macOS checks `brewPrefix = "/opt/homebrew"` from `home/.chezmoi.toml.tmpl`.
