#!/usr/bin/bash
# Shell Profile
#shellcheck disable=SC1091

# 此文件必须同时符合 Bash / Zsh / Fish 的语法!

# 此文件需要环境变量
# $COMMON_SHELL_PROFILE_DIR: 指向此文件夹 以便编辑和刷新
# $SPEC_SHELL_PROFILE: 指向调用 shell 的 profile 以便刷新

command -v "chezmoi" > /dev/null && chezmoi apply

source "$COMMON_SHELL_PROFILE_DIR/environment.sh"
source "$COMMON_SHELL_PROFILE_DIR/aliases.sh"
