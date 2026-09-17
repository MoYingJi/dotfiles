# 简单的补全

# wrapper 继承命令补全
complete -c obs-x11 -w obs

# 是命令的 wrapper
complete -c input-env -f -a "(__fish_complete_command)"
