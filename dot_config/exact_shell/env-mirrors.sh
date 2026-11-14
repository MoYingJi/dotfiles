#!/usr/bin/bash

# 在这里设置镜像源，不需要时保持干净，需要时显式设置
# 需要被多个 shell source

export UV_DEFAULT_INDEX="https://mirrors.aliyun.com/pypi/simple"

export RUSTUP_DIST_SERVER="https://rsproxy.cn"
export RUSTUP_UPDATE_ROOT="https://rsproxy.cn/rustup"
