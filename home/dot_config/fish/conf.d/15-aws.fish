if status is-interactive
    if command -q aws-vault
        function aws-vault --wraps aws-vault
            set_color yellow
            echo 'aws-vault: move to AWS IAM Identity Center (aws configure sso)' >&2
            set_color normal
            command aws-vault $argv
        end
    end
end
