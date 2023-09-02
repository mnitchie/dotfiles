echo "Installing brew"
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"

echo "Installing 1password cli. Remember to enable this in the 1password desktop settings"
brew install 1password-cli
(echo; echo 'eval "$(/opt/homebrew/bin/brew shellenv)"') >> $XDG_CONFIG_HOME/zsh/.zprofile
