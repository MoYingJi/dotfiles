command -v playerctl >/dev/null 2>&1; or exit 0

complete -c playerctl -s p -l player -x -a "(__fish_complete_list , 'playerctl -l 2>/dev/null')" -d (__completion_l10n en 'Control the specified players' zh '指定要控制的播放器')
complete -c playerctl -s i -l ignore-player -x -a "(__fish_complete_list , 'playerctl -l 2>/dev/null')" -d (__completion_l10n en 'Ignore the specified players' zh '忽略指定的播放器')
complete -c playerctl -s a -l all-players -d (__completion_l10n en 'Select all available players' zh '选择所有可用的播放器')
complete -c playerctl -s f -l format -x -d (__completion_l10n en 'Format string for printing properties and metadata' zh '输出属性和元数据的格式字符串')
complete -c playerctl -s F -l follow -d (__completion_l10n en 'Block and append the query when it changes' zh '阻塞运行，并在结果变化时追加输出')
complete -c playerctl -s l -l list-all -d (__completion_l10n en 'List the names of running players' zh '列出正在运行且可控制的播放器名称')
complete -c playerctl -s s -l no-messages -d (__completion_l10n en 'Suppress diagnostic messages' zh '屏蔽诊断信息')
complete -c playerctl -s v -l version -d (__completion_l10n en 'Print version information' zh '显示版本信息')
complete -c playerctl -s h -l help -d (__completion_l10n en 'Show help options' zh '显示帮助选项')

complete -c playerctl -n 'not __fish_seen_subcommand_from play pause play-pause stop next previous position volume status metadata open loop shuffle' -f -a play -d (__completion_l10n en 'Command the player to play' zh '让播放器开始播放')
complete -c playerctl -n 'not __fish_seen_subcommand_from play pause play-pause stop next previous position volume status metadata open loop shuffle' -f -a pause -d (__completion_l10n en 'Command the player to pause' zh '让播放器暂停')
complete -c playerctl -n 'not __fish_seen_subcommand_from play pause play-pause stop next previous position volume status metadata open loop shuffle' -f -a play-pause -d (__completion_l10n en 'Toggle between play and pause' zh '在播放与暂停之间切换')
complete -c playerctl -n 'not __fish_seen_subcommand_from play pause play-pause stop next previous position volume status metadata open loop shuffle' -f -a stop -d (__completion_l10n en 'Command the player to stop' zh '让播放器停止')
complete -c playerctl -n 'not __fish_seen_subcommand_from play pause play-pause stop next previous position volume status metadata open loop shuffle' -f -a next -d (__completion_l10n en 'Skip to the next track' zh '跳到下一曲')
complete -c playerctl -n 'not __fish_seen_subcommand_from play pause play-pause stop next previous position volume status metadata open loop shuffle' -f -a previous -d (__completion_l10n en 'Skip to the previous track' zh '跳到上一曲')
complete -c playerctl -n 'not __fish_seen_subcommand_from play pause play-pause stop next previous position volume status metadata open loop shuffle' -f -a position -d (__completion_l10n en 'Get or seek the playback position' zh '获取或跳转播放位置')
complete -c playerctl -n 'not __fish_seen_subcommand_from play pause play-pause stop next previous position volume status metadata open loop shuffle' -f -a volume -d (__completion_l10n en 'Print or set the volume' zh '获取或设置音量')
complete -c playerctl -n 'not __fish_seen_subcommand_from play pause play-pause stop next previous position volume status metadata open loop shuffle' -f -a status -d (__completion_l10n en 'Get the play status of the player' zh '获取播放器的播放状态')
complete -c playerctl -n 'not __fish_seen_subcommand_from play pause play-pause stop next previous position volume status metadata open loop shuffle' -f -a metadata -d (__completion_l10n en 'Print metadata of the current track' zh '输出当前曲目的元数据')
complete -c playerctl -n 'not __fish_seen_subcommand_from play pause play-pause stop next previous position volume status metadata open loop shuffle' -f -a open -d (__completion_l10n en 'Open a file path or URL in the player' zh '在播放器中打开文件路径或 URL')
complete -c playerctl -n 'not __fish_seen_subcommand_from play pause play-pause stop next previous position volume status metadata open loop shuffle' -f -a loop -d (__completion_l10n en 'Print or set the loop status' zh '获取或设置循环状态')
complete -c playerctl -n 'not __fish_seen_subcommand_from play pause play-pause stop next previous position volume status metadata open loop shuffle' -f -a shuffle -d (__completion_l10n en 'Print or set the shuffle status' zh '获取或设置随机播放状态')

complete -c playerctl -n '__fish_seen_subcommand_from play pause play-pause stop next previous status' -f
complete -c playerctl -n '__fish_seen_subcommand_from position volume' -f
complete -c playerctl -n '__fish_seen_subcommand_from metadata' -f -a 'album artist title xesam:album xesam:artist xesam:title xesam:url mpris:artUrl mpris:length mpris:trackid'
complete -c playerctl -n '__fish_seen_subcommand_from loop' -f -a 'None Track Playlist'
complete -c playerctl -n '__fish_seen_subcommand_from shuffle' -f -a 'On Off Toggle'
