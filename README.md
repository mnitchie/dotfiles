# Dotfiles

My dotfiles and some setup stuff.

## Getting started

This just needs to get executed once per machine

`curl -Lks https://raw.githubusercontent.com/mnitchie/dotfiles/main/bin/setup.sh | /bin/bash`

Then `source $HOME/.config/zsh/zshrc` or restart your terminal

This will clone the repo to `$HOME/.my_dotfiles_git` as a bare repo, but set the home directory to the workdir.
.zshenv creates a `config` alias that will run all git commands in the bare repo.

## Usage

The setup script sets ignoreUntracked to true for everything in the repo (home directory), so new files must always be added explicitly.

```bash
config status
config add .vimrc
config commit -m "Add vimrc"
config add .config/redshift.conf
config commit -m "Add redshift config"
config push
```

## Secrets and environment variables
When needed, export secrets in .config/includes/secrets.sh, which is `source`d in `.zshrc`. Never check the secrets file in

## Other scripts

Other scripts in bin/ should be executed after the above is done, as it will assume some things are already set up (like xdg dirs)

## Other setup

### AWS Vault
https://github.com/99designs/aws-vault

Open the keychain, File -> Add Keychain, aws-vault.keychain.db (or something)
https://github.com/99designs/aws-vault/issues/534#issuecomment-596971986
https://github.com/99designs/aws-vault/issues/534#issuecomment-596578706

## References

1. [Primary reference](https://www.atlassian.com/git/tutorials/dotfiles)
    * Roughly copied to [this doc](./docs/HowToStoreDotfiles.html) in case the link dies
    * https://github.com/durdn/cfg
    * https://news.ycombinator.com/item?id=11071754
2. https://dotfiles.github.io/
3. https://www.freecodecamp.org/news/dotfiles-what-is-a-dot-file-and-how-to-create-it-in-mac-and-linux
4. https://github.com/ActionScripted/dotfiles
