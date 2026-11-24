#!/usr/bin/bash

# 镜像源开关，表见 mirrors.conf，需要被 bash / zsh source
# 不放进 profile.sh，fish 无法解析此处的函数定义

__mirror_rows() {
    grep -vE '^[[:space:]]*(#|$)' "$COMMON_SHELL_PROFILE_DIR/mirrors.conf"
}

# off 直接 unset 而非设为官方地址，即回到工具自身的默认行为
__mirror_apply() {
    local name var url
    while read -r name var url; do
        if [[ "$1" == on ]]; then
            export "$var=$url"
        else
            unset "$var"
        fi
    done < <(__mirror_rows)
}

mirror() {
    local name var url
    case "${1:-status}" in
        on | off)
            __mirror_apply "$1" ;;
        run)
            shift
            if [[ $# -eq 0 ]]; then
                echo "用法: mirror run <命令> [参数...]" >&2
                return 1
            fi
            # 子 shell 保证变量只对这条命令生效
            ( __mirror_apply on; "$@" ) ;;
        status)
            while read -r name var url; do
                printf '%-8s %-22s %s\n' "$name" "$var" "$(printenv "$var" || echo 官方)"
            done < <(__mirror_rows) ;;
        *)
            echo "用法: mirror on|off|status|run <命令> [参数...]" >&2
            return 1 ;;
    esac
}

# 命令补全，zsh 需在 compinit 之后注册
if [[ -n "$BASH_VERSION" ]]; then
    __mirror_complete() {
        local cur=${COMP_WORDS[COMP_CWORD]}
        if ((COMP_CWORD == 1)); then
            mapfile -t COMPREPLY < <(compgen -W "on off status run" -- "$cur")
        elif [[ ${COMP_WORDS[1]} == run ]] && ((COMP_CWORD == 2)); then
            mapfile -t COMPREPLY < <(compgen -c -- "$cur")
        else
            mapfile -t COMPREPLY < <(compgen -f -- "$cur")
        fi
    }
    complete -F __mirror_complete mirror
elif [[ -n "$ZSH_VERSION" ]]; then
    _mirror() {
        if ((CURRENT == 2)); then
            _values 'action' 'on[在当前 shell 启用镜像源]' 'off[恢复官方源]' 'status[查看各工具当前使用的源]' 'run[仅对该命令启用镜像源运行]'
        elif [[ ${words[2]} == run ]]; then
            words=("${words[3,-1]}")
            ((CURRENT -= 2))
            _normal
        fi
    }
    compdef _mirror mirror
fi
