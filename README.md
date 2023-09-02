# Dotfiles

My dotfiles and some setup stuff.

## Getting started

This just needs to get executed once per machine
`curl -Lks https://raw.githubusercontent.com/mnitchie/dotfiles/main/bin/setup.sh | /bin/bash`

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

## References

1. [Primary reference](https://www.atlassian.com/git/tutorials/dotfiles)
    * Roughly copied to [this doc](./docs/HowToStoreDotfiles.html) in case the link dies
    * https://github.com/durdn/cfg
    * https://news.ycombinator.com/item?id=11071754

Notable quote:

I use:
```bash
git init --bare $HOME/.myconf
alias config='/usr/bin/git --git-dir=$HOME/.myconf/ --work-tree=$HOME'
config config status.showUntrackedFiles no
```

where my ~/.myconf directory is a git bare repository. Then any file within the home folder can be versioned with normal commands like:

```bash
config status
config add .vimrc
config commit -m "Add vimrc"
config add .config/redshift.conf
config commit -m "Add redshift config"
config push
```

No extra tooling, no symlinks, files are tracked on a version control system, you can use different branches for different computers, you can replicate you configuration easily on new installation.


1. https://dotfiles.github.io/
2. https://www.freecodecamp.org/news/dotfiles-what-is-a-dot-file-and-how-to-create-it-in-mac-and-linux
3. https://github.com/ActionScripted/dotfiles
