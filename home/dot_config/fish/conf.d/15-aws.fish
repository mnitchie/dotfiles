if status is-interactive
    if command -q aws-vault
        function aws-vault --wraps aws-vault
            begin
                set_color yellow
                echo 'aws-vault: move to AWS IAM Identity Center (aws configure sso)'
                set_color normal
            end >&2
            command aws-vault $argv
        end
    end
end
