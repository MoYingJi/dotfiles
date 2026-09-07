#!/usr/bin/fish

function mkcd -d "创建目录并进入"
    mkdir -p $argv[1]
    cd $argv[1]
end
