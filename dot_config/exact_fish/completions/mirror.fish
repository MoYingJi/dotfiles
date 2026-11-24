# for functions/mirror.fish

complete -c mirror -n __fish_use_subcommand -f -a on -d (__completion_l10n en 'Enable mirrors in the current shell' zh '在当前 shell 启用镜像源')
complete -c mirror -n __fish_use_subcommand -f -a off -d (__completion_l10n en 'Restore official sources' zh '恢复官方源')
complete -c mirror -n __fish_use_subcommand -f -a status -d (__completion_l10n en 'Show the source each tool uses' zh '查看各工具当前使用的源')
complete -c mirror -n __fish_use_subcommand -f -a run -d (__completion_l10n en 'Run a command with mirrors enabled' zh '仅对该命令启用镜像源运行')

complete -c mirror -n '__fish_seen_subcommand_from run' -a "(__fish_complete_subcommand --fcs-skip=2)"
