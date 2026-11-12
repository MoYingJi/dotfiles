complete -c geodbq -n '__fish_use_subcommand' -f -a domain -d '查询域名匹配的 geosite 分类'
complete -c geodbq -n '__fish_use_subcommand' -f -a extract -d '从 Xray 配置生成结构体代码'
complete -c geodbq -n '__fish_use_subcommand' -f -a help -d '显示帮助信息'
complete -c geodbq -n '__fish_use_subcommand' -f -a ip -d '查询 IP 所属国家代码'
complete -c geodbq -n '__fish_use_subcommand' -f -a list-categories -d '列出所有国家代码和分类'
complete -c geodbq -n '__fish_use_subcommand' -f -a list-rules -d '列出指定国家代码或分类的规则'
complete -c geodbq -n '__fish_use_subcommand' -f -a simulate-route -d '模拟 Xray 路由决策'
complete -c geodbq -n '__fish_use_subcommand' -f -a summarize -d '显示数据文件摘要'

complete -c geodbq -l geoip -r -F -d 'geoip.dat 文件路径'
complete -c geodbq -l geosite -r -F -d 'geosite.dat 文件路径'
complete -c geodbq -s h -l help -d '显示帮助信息'

complete -c geodbq -n '__fish_seen_subcommand_from help' -f -a 'domain extract ip list-categories list-rules simulate-route summarize'
complete -c geodbq -n '__fish_seen_subcommand_from domain' -f
complete -c geodbq -n '__fish_seen_subcommand_from ip' -f
complete -c geodbq -n '__fish_seen_subcommand_from list-rules' -f

complete -c geodbq -n '__fish_seen_subcommand_from list-rules' -l max-show -x -d '最多显示的规则数（-1 表示全部）'

complete -c geodbq -n '__fish_seen_subcommand_from simulate-route' -l config -r -F -d 'Xray 配置文件路径'
complete -c geodbq -n '__fish_seen_subcommand_from simulate-route' -l domain -x -d '要模拟路由的域名'
complete -c geodbq -n '__fish_seen_subcommand_from simulate-route' -l ip -x -d '要模拟路由的 IP 地址'
complete -c geodbq -n '__fish_seen_subcommand_from simulate-route' -l source-ip -x -d '流量来源 IP 地址'
complete -c geodbq -n '__fish_seen_subcommand_from simulate-route' -l prefer-ip -x -a 'ipv4 ipv6' -d 'DNS 查询优先使用的 IP 版本'
complete -c geodbq -n '__fish_seen_subcommand_from simulate-route' -l inbound-tag -x -d '流量来源 inbound 标签'
complete -c geodbq -n '__fish_seen_subcommand_from simulate-route' -l port -x -d '目标端口'
complete -c geodbq -n '__fish_seen_subcommand_from simulate-route' -l source-port -x -d '来源端口'
complete -c geodbq -n '__fish_seen_subcommand_from simulate-route' -l protocol -x -d '协议'
complete -c geodbq -n '__fish_seen_subcommand_from simulate-route' -l network -x -a 'tcp udp' -d '网络类型'
complete -c geodbq -n '__fish_seen_subcommand_from simulate-route' -l user-email -x -d '用于匹配的用户邮箱'

complete -c geodbq -n '__fish_seen_subcommand_from extract' -l lang -x -a 'golang go swift s kotlin k' -d '输出语言'
