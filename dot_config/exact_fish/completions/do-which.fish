# for .local/binCmd/do-which

command -v do-which >/dev/null 2>&1; or exit 0

complete -c do-which -n "__fish_is_nth_token 1" -f -a "(__fish_complete_command)"
complete -c do-which -n "__fish_is_nth_token 2" -f -a "(__fish_complete_command)"

complete -c do-which -f
