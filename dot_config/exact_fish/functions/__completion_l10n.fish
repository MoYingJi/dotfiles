function __completion_l10n -d "按 locale 选取补全描述文本"
    # 用法：__completion_l10n <locale前缀> <文本> [<locale前缀> <文本> ...]，首对为回退值
    # locale 取 LC_ALL > LC_MESSAGES > LANG 的第一个非空值；与 gettext 一致，LANGUAGE 可覆盖它，但 C/POSIX 时忽略
    set -l locale
    for loc in $LC_ALL $LC_MESSAGES $LANG
        if test -n "$loc"
            set locale $loc
            break
        end
    end
    if test -n "$locale"; and not string match -q -r '^(C|POSIX)([.@]|$)' -- $locale; and set -q LANGUAGE[1]
        set locale $LANGUAGE[1]
    end

    set -l pairs $argv
    while set -q pairs[2]
        if string match -q "$pairs[1]*" -- "$locale"
            echo $pairs[2]
            return
        end
        set -e pairs[1..2]
    end
    echo $argv[2]
end
