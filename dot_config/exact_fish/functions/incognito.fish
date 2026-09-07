#!/usr/bin/fish

function incognito -d "切换无痕模式"
    if set -q fish_history
        set -ge fish_history
        echo "已退出无痕模式"
    else
        set -g fish_history ""
        echo "已进入无痕模式"
    end
end
