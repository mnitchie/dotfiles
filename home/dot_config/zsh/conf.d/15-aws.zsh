if (( $+commands[aws-vault] )); then
  aws-vault() {
    print -Pu2 '%F{yellow}aws-vault: move to AWS IAM Identity Center (aws configure sso)%f'
    command aws-vault "$@"
  }
fi
