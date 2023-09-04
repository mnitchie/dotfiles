echo "Installing brew"
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"

echo "Installing 1password cli. Remember to enable this in the 1password desktop settings"
brew install 1password-cli
(echo; echo 'eval "$(/opt/homebrew/bin/brew shellenv)"') >> $XDG_CONFIG_HOME/zsh/.zprofile

echo "Installing font needed for agnoster theme"
# clone
git clone https://github.com/powerline/fonts.git --depth=1
# install
cd fonts
./install.sh
# clean-up a bit
cd ..
rm -rf fonts

echo "Installing aws cli"
curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
sudo installer -pkg AWSCLIV2.pkg -target /
which aws
aws --version

echo "Install AWS Vault"
brew install --cask aws-vault

echo "Install gh cli"
brew install gh

echo "Installing jq"
brew install jq
