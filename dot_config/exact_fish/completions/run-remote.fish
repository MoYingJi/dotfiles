command -v run-remote >/dev/null 2>&1; or exit 0

function __fish_run_remote_next_argument
    set -l tokens (commandline -opc)
    set -e tokens[1]
    set -l target_seen 0
    set -l script_seen 0
    set -l parse_options 1
    set -l next_option_argument ''

    for token in $tokens
        if test -n "$next_option_argument"
            switch $next_option_argument
                case target
                    set target_seen 1
                case script
                    set script_seen 1
            end
            set next_option_argument ''
            continue
        end

        if test $parse_options -eq 1
            if test "$token" = --
                set parse_options 0
                continue
            end

            switch $token
                case -H
                    set next_option_argument target
                    continue
                case -S
                    set next_option_argument script
                    continue
                case -p -i -J -l -o -E
                    set next_option_argument other
                    continue
                case '-H*'
                    set target_seen 1
                    continue
                case '-S*'
                    set script_seen 1
                    continue
                case '-p*' '-i*' '-J*' '-l*' '-o*' '-E*'
                    continue
                case '-*'
                    continue
            end
        end

        if test $target_seen -eq 0
            set target_seen 1
        else if test $script_seen -eq 0
            set script_seen 1
        else
            break
        end
    end

    if test -n "$next_option_argument"
        switch $next_option_argument
            case target
                echo host
            case script
                echo script
            case '*'
                echo option-value
        end
    else if test $target_seen -eq 0
        echo host
    else if test $script_seen -eq 0
        echo script
    else
        echo arguments
    end
end

function __fish_run_remote_forward_completions
    set -l tokens (commandline -opc)
    set -e tokens[1]
    set -l remote_tokens
    set -l after_separator 0

    for token in $tokens
        if test $after_separator -eq 1
            set -a remote_tokens "$token"
        else if test "$token" = --
            set after_separator 1
        end
    end

    if test $after_separator -eq 0
        return
    end

    set -l escaped_tokens
    for token in $remote_tokens
        set -a escaped_tokens (string escape -- "$token")
    end

    set -l remote_line (string join -- ' ' $escaped_tokens)
    if test -n "$remote_line"
        set remote_line "$remote_line "
    end

    set -l current_token (commandline -ct)
    if test -n "$current_token"
        set remote_line "$remote_line"(string escape -- "$current_token")
    else
        set remote_line "$remote_line "
    end

    complete -C "$remote_line"
end

complete -c run-remote -n 'test (__fish_run_remote_next_argument) != arguments' -s p -x -d 'SSH 端口'
complete -c run-remote -n 'test (__fish_run_remote_next_argument) != arguments' -s i -r -d 'SSH 私钥文件'
complete -c run-remote -n 'test (__fish_run_remote_next_argument) != arguments' -s J -x -a '(__fish_print_hostnames)' -d 'SSH 跳板机'
complete -c run-remote -n 'test (__fish_run_remote_next_argument) != arguments' -s l -x -d 'SSH 登录用户名'
complete -c run-remote -n 'test (__fish_run_remote_next_argument) != arguments' -s o -x -d '额外的 SSH 选项'
complete -c run-remote -n 'test (__fish_run_remote_next_argument) != arguments' -s t -d '分配伪终端并以内联模式运行'
complete -c run-remote -n 'test (__fish_run_remote_next_argument) != arguments' -s T -d '禁用伪终端分配'
complete -c run-remote -n 'test (__fish_run_remote_next_argument) != arguments' -s q -d '安静模式'
complete -c run-remote -n 'test (__fish_run_remote_next_argument) != arguments' -s L -d '在登录 shell 中运行'
complete -c run-remote -n 'test (__fish_run_remote_next_argument) != arguments' -s E -r -d '设置远端环境变量'
complete -c run-remote -n 'test (__fish_run_remote_next_argument) != arguments' -s H -x -a '(__fish_print_hostnames)' -d '远端主机'
complete -c run-remote -n 'test (__fish_run_remote_next_argument) != arguments' -s S -r -a '(__fish_complete_command)' -d '本地脚本'
complete -c run-remote -n 'test (__fish_run_remote_next_argument) != arguments' -s I -d '以内联模式运行'
complete -c run-remote -n 'test (__fish_run_remote_next_argument) != arguments' -s n -d '试运行，只打印 SSH 命令'
complete -c run-remote -n 'test (__fish_run_remote_next_argument) != arguments' -s v -d '执行前打印 SSH 命令'
complete -c run-remote -n 'test (__fish_run_remote_next_argument) != arguments' -s h -d '显示帮助信息'

complete -c run-remote -n 'test (__fish_run_remote_next_argument) = host' -f -a '(__fish_print_hostnames)' -d '远端主机'
complete -c run-remote -n 'test (__fish_run_remote_next_argument) = script' -f -a '(__fish_complete_command)' -d '本地脚本'
complete -c run-remote -n 'test (__fish_run_remote_next_argument) = arguments' -f -a '(__fish_run_remote_forward_completions)'
