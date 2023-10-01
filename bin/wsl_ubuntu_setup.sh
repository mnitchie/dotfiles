#!/bin/bash

echo "Updating package lists"
sudo apt update

echo "Installing prerequisites"
sudo apt install -y curl git zsh

echo "Installing 1password-cli"
curl -sS -o 1password.tar.gz https://cache.agilebits.com/dist/1P/op/pkg/v1.12.2/op_linux_amd64_v1.12.2.tar.gz
tar -xzf 1password.tar.gz op
sudo mv op /usr/local/bin
rm 1password.tar.gz

echo "Installing font needed for agnoster theme"
# clone
git clone https://github.com/powerline/fonts.git --depth=1
# install
cd fonts
./install.sh
# clean-up a bit
cd ..
rm -rf fonts

echo "Installing AWS CLI"
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
rm awscliv2.zip
which aws
aws --version

echo "Installing AWS Vault"
wget https://github.com/99designs/aws-vault/releases/download/v6.3.1/aws-vault-linux-amd64 -O aws-vault
chmod +x aws-vault
sudo mv aws-vault /usr/local/bin/

echo "Installing GitHub CLI"
sudo apt install -y gh

echo "Installing jq"
sudo apt install -y jq

echo "Installing pre-commit"
sudo apt install -y pre-commit

echo "Installing exa"
sudo apt install exa

echo "Installing oh-my-zsh"
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

echo "Installing zsh-autosuggestions plugin
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

echo "Making zsh the default shell"
chsh -s $(which zsh)

echo "Install and configure powerline fonts for your terminal with this guide: https://gist.github.com/stramel/658d702f3af8a86a6fe8b588720e0e23"