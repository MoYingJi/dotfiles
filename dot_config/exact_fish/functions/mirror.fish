#!/usr/bin/fish

# 镜像源开关，表见 shell/mirrors.conf，行为需与 mirror.sh 保持一致
function mirror -d "切换镜像源（表见 shell/mirrors.conf）"
    set -l conf $COMMON_SHELL_PROFILE_DIR/mirrors.conf
    set -l action status
    if test (count $argv) -gt 0
        set action $argv[1]
    end
    set -l args $argv[2..-1]
    set -l rows (string match -rv '^\s*(#|$)' < $conf)

    switch $action
        case on
            for row in $rows
                set -l f (string split --no-empty -- ' ' $row)
                set -gx $f[2] $f[3]
            end
        case off
            for row in $rows
                set -l f (string split --no-empty -- ' ' $row)
                set -e $f[2]
            end
        case run
            if test (count $args) -eq 0
                echo "用法: mirror run <命令> [参数...]" >&2
                return 1
            end
            set -l pairs
            for row in $rows
                set -l f (string split --no-empty -- ' ' $row)
                set -a pairs "$f[2]=$f[3]"
            end
            env $pairs $args
        case status
            for row in $rows
                set -l f (string split --no-empty -- ' ' $row)
                set -l var $f[2]
                set -l cur 官方
                set -q $var; and set cur $$var
                printf '%-8s %-22s %s\n' $f[1] $var $cur
            end
        case '*'
            echo "用法: mirror on|off|status|run <命令> [参数...]" >&2
            return 1
    end
end
