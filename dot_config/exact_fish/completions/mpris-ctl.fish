command -v mpris-ctl >/dev/null 2>&1; or exit 0

complete -c mpris-ctl -l player -x -a active -d (__completion_l10n en 'All players currently playing' zh '所有正在播放的播放器')
complete -c mpris-ctl -l player -x -a inactive -d (__completion_l10n en 'All players currently stopped or paused' zh '所有已停止或暂停的播放器')
complete -c mpris-ctl -l player -x -a "(mpris-ctl --player active --player inactive list 2>/dev/null)" -d (__completion_l10n en 'Name of a running player' zh '正在运行的播放器名称')
complete -c mpris-ctl -l player -x -d (__completion_l10n en 'Specify the player(s) to control' zh '指定要控制的播放器')

complete -c mpris-ctl -n 'not __fish_seen_subcommand_from help play pp pause stop next prev raise shuffle repeat seek volume status list info' -f -a help -d (__completion_l10n en 'Show the help message' zh '显示帮助信息')
complete -c mpris-ctl -n 'not __fish_seen_subcommand_from help play pp pause stop next prev raise shuffle repeat seek volume status list info' -f -a play -d (__completion_l10n en 'Begin playing' zh '开始播放')
complete -c mpris-ctl -n 'not __fish_seen_subcommand_from help play pp pause stop next prev raise shuffle repeat seek volume status list info' -f -a pp -d (__completion_l10n en 'Toggle play or pause' zh '在播放与暂停之间切换')
complete -c mpris-ctl -n 'not __fish_seen_subcommand_from help play pp pause stop next prev raise shuffle repeat seek volume status list info' -f -a pause -d (__completion_l10n en 'Pause the player' zh '暂停播放器')
complete -c mpris-ctl -n 'not __fish_seen_subcommand_from help play pp pause stop next prev raise shuffle repeat seek volume status list info' -f -a stop -d (__completion_l10n en 'Stop the player' zh '停止播放器')
complete -c mpris-ctl -n 'not __fish_seen_subcommand_from help play pp pause stop next prev raise shuffle repeat seek volume status list info' -f -a next -d (__completion_l10n en 'Change to the next track in the playlist' zh '切换到播放列表中的下一曲')
complete -c mpris-ctl -n 'not __fish_seen_subcommand_from help play pp pause stop next prev raise shuffle repeat seek volume status list info' -f -a prev -d (__completion_l10n en 'Change to the previous track in the playlist' zh '切换到播放列表中的上一曲')
complete -c mpris-ctl -n 'not __fish_seen_subcommand_from help play pp pause stop next prev raise shuffle repeat seek volume status list info' -f -a raise -d (__completion_l10n en 'Raise the window of the player if hidden' zh '将隐藏的播放器窗口提到前台')
complete -c mpris-ctl -n 'not __fish_seen_subcommand_from help play pp pause stop next prev raise shuffle repeat seek volume status list info' -f -a shuffle -d (__completion_l10n en 'Change the shuffle mode' zh '设置随机播放模式')
complete -c mpris-ctl -n 'not __fish_seen_subcommand_from help play pp pause stop next prev raise shuffle repeat seek volume status list info' -f -a repeat -d (__completion_l10n en 'Change the loop status' zh '设置循环模式')
complete -c mpris-ctl -n 'not __fish_seen_subcommand_from help play pp pause stop next prev raise shuffle repeat seek volume status list info' -f -a seek -d (__completion_l10n en 'Seek forwards or backwards in the current track' zh '在当前曲目中前进或后退')
complete -c mpris-ctl -n 'not __fish_seen_subcommand_from help play pp pause stop next prev raise shuffle repeat seek volume status list info' -f -a volume -d (__completion_l10n en 'Get or modify the volume' zh '获取或修改音量')
complete -c mpris-ctl -n 'not __fish_seen_subcommand_from help play pp pause stop next prev raise shuffle repeat seek volume status list info' -f -a status -d (__completion_l10n en 'Get the playback status' zh '获取播放状态')
complete -c mpris-ctl -n 'not __fish_seen_subcommand_from help play pp pause stop next prev raise shuffle repeat seek volume status list info' -f -a list -d (__completion_l10n en 'Get the name of the running player(s)' zh '获取正在运行的播放器名称')
complete -c mpris-ctl -n 'not __fish_seen_subcommand_from help play pp pause stop next prev raise shuffle repeat seek volume status list info' -f -a info -d (__completion_l10n en 'Display information about the current track' zh '显示当前曲目的信息')

complete -c mpris-ctl -n '__fish_seen_subcommand_from help play pp pause stop next prev raise status list' -f
complete -c mpris-ctl -n '__fish_seen_subcommand_from seek volume' -f
complete -c mpris-ctl -n '__fish_seen_subcommand_from shuffle' -f -a 'on off'
complete -c mpris-ctl -n '__fish_seen_subcommand_from repeat' -l track -d (__completion_l10n en 'Apply to the current track' zh '作用于当前曲目')
complete -c mpris-ctl -n '__fish_seen_subcommand_from repeat' -l playlist -d (__completion_l10n en 'Apply to the whole playlist' zh '作用于整个播放列表')
complete -c mpris-ctl -n '__fish_seen_subcommand_from repeat' -f -a 'on off'

complete -c mpris-ctl -n '__fish_seen_subcommand_from info' -f -a '%player_name' -d (__completion_l10n en 'Player name' zh '播放器名称')
complete -c mpris-ctl -n '__fish_seen_subcommand_from info' -f -a '%track_name' -d (__completion_l10n en 'Track name' zh '曲目名称')
complete -c mpris-ctl -n '__fish_seen_subcommand_from info' -f -a '%track_number' -d (__completion_l10n en 'Track number' zh '曲目编号')
complete -c mpris-ctl -n '__fish_seen_subcommand_from info' -f -a '%track_length' -d (__completion_l10n en 'Track length' zh '曲目时长')
complete -c mpris-ctl -n '__fish_seen_subcommand_from info' -f -a '%artist_name' -d (__completion_l10n en 'Artist name' zh '艺术家名称')
complete -c mpris-ctl -n '__fish_seen_subcommand_from info' -f -a '%album_name' -d (__completion_l10n en 'Album name' zh '专辑名称')
complete -c mpris-ctl -n '__fish_seen_subcommand_from info' -f -a '%album_artist' -d (__completion_l10n en 'Album artist' zh '专辑艺术家')
complete -c mpris-ctl -n '__fish_seen_subcommand_from info' -f -a '%art_url' -d (__completion_l10n en 'URL of the cover art image' zh '封面图片的 URL')
complete -c mpris-ctl -n '__fish_seen_subcommand_from info' -f -a '%play_status' -d (__completion_l10n en 'Playback status' zh '播放状态')
complete -c mpris-ctl -n '__fish_seen_subcommand_from info' -f -a '%shuffle' -d (__completion_l10n en 'Shuffle mode' zh '随机播放模式')
complete -c mpris-ctl -n '__fish_seen_subcommand_from info' -f -a '%volume' -d (__completion_l10n en 'Volume' zh '音量')
complete -c mpris-ctl -n '__fish_seen_subcommand_from info' -f -a '%loop_status' -d (__completion_l10n en 'Loop status' zh '循环状态')
complete -c mpris-ctl -n '__fish_seen_subcommand_from info' -f -a '%position' -d (__completion_l10n en 'Song position in seconds' zh '播放位置（秒）')
complete -c mpris-ctl -n '__fish_seen_subcommand_from info' -f -a '%bitrate' -d (__completion_l10n en 'Bitrate' zh '比特率')
complete -c mpris-ctl -n '__fish_seen_subcommand_from info' -f -a '%comment' -d (__completion_l10n en 'Track comment' zh '曲目注释')
complete -c mpris-ctl -n '__fish_seen_subcommand_from info' -f -a '%full' -d (__completion_l10n en 'All available information' zh '所有可用信息')
