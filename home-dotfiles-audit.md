# Home dotfiles audit

Scan of `/Users/mike.nichie` on 2 Oct 2026. Nothing was deleted or added to chezmoi.

Chezmoi already manages `~/.zshenv`, `~/.config/zsh`, git, `~/.ssh/config` (which includes `~/.ssh/config.local`), gh `config.yml`, Starship, vim, IPython, Python startup, and the Homebrew package list. The items below are everything else that looked like config or leftover setup.

`~/.zshenv` sets `ZDOTDIR=~/.config/zsh`, so zsh does not read `~/.zshrc`, `~/.zprofile`, or `~/.profile`.

## 1. Cruft

Safe to remove once you agree with the note on each line. Sizes are approximate.

### Leftovers from the old bare-repo dotfiles

The chezmoi migration left the previous setup in place.

| Path | Why it can go |
| --- | --- |
| `~/dotfiles-backup-20260929` (19 MB) | Snapshot of the old bare repo, Oh My Zsh, and `includes/`. `includes/secrets.sh` is in there. Delete only after you are sure nothing in that snapshot is still the only copy. |

### Empty or abandoned directories

| Path | Last touched | Notes |
| --- | --- | --- |
| `~/.config-backup/` | Sep 2023 | Empty. |
| `~/ScreenConnect/Toolbox/` | | Empty. The ScreenConnect Client app is still installed. |

### 2023 vendor leftovers

`~/.cisco/`, `~/.vpn/` — Cisco AnyConnect, Sep 2023.
- `~/.labtech/` — LabTech / ConnectWise agent state, Sep 2023.

## 2. Worth managing

Portable config that is not in the source tree yet. Leave secrets, app databases, and session files out.

### Move into managed zsh, then delete `~/.zshrc`

### Cursor editor config

This is the main gap. `todo.md` in this repo is already a cleanup pass for it.

| Path | What to keep |
| --- | --- |
| `~/Library/Application Support/Cursor/User/settings.json` | Edited 2 days ago. Run the `todo.md` cleanup first. Drop `sqltools.connections` (it contains a database password) and the other keys that file already marks as local or dead. |
| `~/Library/Application Support/Cursor/User/keybindings.json` | 14 bindings: terminal focus, back/forward on cmd+[/], member navigation, agent mode. The `gotoNextPreviousMember` bindings depend on an extension `todo.md` says is not installed. |

Do not manage `~/.cursor/` as a tree. It is plans, chats, extension installs, and project state.

Two small files are real config, after a secret strip:

- `~/.cursor/hooks.json` — runs `~/.cursor/hooks/cursor_logger.py` and a local plugin notifier. Only worth sharing if those scripts move into this repo too.
- `~/.cursor/mcp.json` — MCP server list (Stitch, AWS, CircleCI, draw.io, GitHub, Terraform). The GitHub entry has a personal access token hardcoded in the file. Rotate that token, switch the header to an env var, and only then consider chezmoi. The same servers are duplicated in `~/.codex/config.toml`.

`~/.config/cursor/cli-config.json` is account and session state, not a dotfile to commit.

### Terminal config

Ghostty, Warp, and iTerm are all installed. Pick the one you actually use.

| Path | Last touched | Fit for chezmoi |
| --- | --- | --- |
| `~/.config/ghostty/config.ghostty` | ~131 days | Yes. Six lines: theme and shell-integration features. |

### Other small config

| Path | Why |
| --- | --- |
| `~/.aws/config` | Profiles (`cleardata`, `non-cleardata`, `bams`, `strata-localstack`, `non-cd-mcp-readonly`, `GSKDataTransfer2`) and an `aws-vault` credential process. No secret values in this file. Do **not** add `~/.aws/credentials`. |
| `~/.docker/daemon.json` | BuildKit GC capped at 20 GB. |
| `~/.config/.sqliterc` | `.mode column` and `.headers on`. |
| `~/.ssh/config.local` | Work host aliases. The managed `~/.ssh/config` already includes this file. A private chezmoi template is reasonable. Do not commit it to the public repo as-is: it names internal hosts and key files. |

Low value, already the upstream default: `~/.config/1Password/ssh/agent.toml` only enables the Private vault.

## 3. Needs a manual look

### Secrets and machine state — do not chezmoi these

- `~/.aws/credentials` — static key material for `GSKDataTransfer2`. The rest of AWS is already `aws-vault` / `credential_process` in `~/.aws/config`.
- `~/.ssh/gh_keypair`, `informatics-utils-08092022.pem`, `strata-instance-key.pem`, `known_hosts`, `known_hosts.old`.
- `~/.config/strata/certs/` — dev certs from 2023, including private keys (`strata-dev.com.key`, `strata-dev.com.root_ca.key`). Likely expired. Confirm before deleting.
- `~/.cursor/mcp.json` — GitHub personal access token in the `Authorization` header. Rotate it whether or not you manage the file.
- `~/dotfiles-backup-20260929/includes/secrets.sh`
- `~/.grokbot/local-exec-daemon-credential.json` and the rest of `~/.grokbot/` (active this week; app runtime).
- `~/.codex/auth.json`, session logs, and sqlite files. Codex.app is in use (the directory was updated today).
- `~/.config/filezilla/sitemanager.xml` and `recentservers.xml` — often contain passwords. FileZilla.app is installed; these files are ~450 days old.
- `~/.ollama/id_ed25519` — Ollama’s own key. `~/.ollama` is about 46 GB of models. `config.json` is only the last-used model. Not a dotfile.
- `~/.docker/config.json` — `credsStore` is fine; `auths` may not be.

### Still installed, so not obviously junk

| Path | Question |
| --- | --- |
| `~/.vscode/` (1.5 GB) and `~/Library/Application Support/Code/User/settings.json` | Visual Studio Code.app is installed and that settings file changed 10 days ago. `~/.vscode/extensions` has not changed since Sep 2023. Decide whether Code is still used before deleting the extensions or copying settings. The settings overlap the Cursor file and have the same kind of stale keys. |
| `~/.antigravity/` (281 MB) and `~/.gemini/` | Antigravity.app is installed (~198 days since these dirs changed). Extensions and Gemini state, not config to copy. The missing piece is the `PATH` line trapped in `~/.zshrc`. |
| `~/.lmstudio/` (2.1 GB) and `~/.lmstudio-home-pointer` | LM Studio.app. Models and app data. Same `PATH` issue as Antigravity. |
| `~/.ollama/` | Ollama.app, used recently. Leave the model store alone. |
| `~/.da/` | Thermo Fisher plate-analysis preferences (report title, dye list). ~514 days old. Delete only if that instrument software is gone. |
| `~/.gk/` | GitKraken workspace maps, updated yesterday. App state. |
| `~/.claude/` | `settings.json` is only `enabledPlugins`. The rest is a plugin cache. Updated ~10 days ago. |
| `~/.codex/config.toml` | Real preferences (model, desktop, MCP), plus absolute paths and a GitHub auth header. Strip secrets before treating it as a dotfile. Overlaps `~/.cursor/mcp.json`. `~/.codex/AGENTS.md` is empty. |
| `~/.config/raycast/` | Extension installs, ~136 days. Raycast owns this directory. |
| `~/.config/circleci/config.yml` | CLI device login from ~51 days ago. Not portable. |
| `~/.config/gh/hosts.yml` | `gh auth` rewrites this (`user: mnitchie`, HTTPS). Optional. |
| `~/.local/bin/devcontainer` | Symlink into VS Code’s Dev Containers CLI. Still resolves. Tied to whether you still use that CLI. |
| `~/.local/bin/cursor-agent` | Points at a Cursor agent build from April 2026. May be an old CLI pin. |
