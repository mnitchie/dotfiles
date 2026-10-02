This repo is personal dotfiles managed with chezmoi. Files under `home/` are the source and are applied as real files under `$HOME`.

There is no package manager and no build. After a change, `chezmoi apply` should leave `chezmoi status` empty. CI runs `.github/workflows/bootstrap.yml`.

Change the source files in `home/` (chezmoi names such as `dot_` and `.tmpl`). Paths like `~/.config/zsh/.zshrc` are the installed copies. README.md covers apply, templates, platform-only files, packages, and secrets. Keep secrets out of git.
