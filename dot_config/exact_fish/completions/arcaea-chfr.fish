command -v arcaea-chfr >/dev/null 2>&1; or exit 0

complete -c arcaea-chfr -s h -l help -d '显示帮助信息'
complete -c arcaea-chfr -s v -l view -d '查看当前残片数和校验和'

complete -c arcaea-chfr -n '__fish_is_nth_token 1' -f
complete -c arcaea-chfr -n '__fish_is_nth_token 2; or __fish_seen_argument -s v -l view' -f -a 'moe.low.arc' -d '默认包名／国际服'
complete -c arcaea-chfr -n '__fish_is_nth_token 2; or __fish_seen_argument -s v -l view' -f -a 'com.xd.arcaea.tapcn' -d '国服包名'
