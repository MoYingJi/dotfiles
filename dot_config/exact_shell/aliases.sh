#!/usr/bin/bash

# 只允许兼容 alias a='b' 这种形式的 shell 调用！

# Profile
alias ref='_REF=1 source $COMMON_SHELL_PROFILE_DIR/profile.sh'

alias ege='edit /etc/environment'
alias egp='edit /etc/profile'

alias e-kate='export EDITOR="kate -b"'
alias e-nvim='export EDITOR="nvim"'

## 短名
alias c='clear'
alias l='ls'
alias y='yay'
alias p='paru'

alias vi='nvim'

alias syu='sudo pacman -Syu'

alias gc='git clone'

alias sys='systemctl'
alias sys-en='systemctl enable --now'

alias k9='kill -9'
alias pk9='pkill -9'
alias pkexe='pkill .exe'

alias bat-which='do-which bat'
alias edit-which='do-which $EDITOR'
alias kate-which='do-which kate'

alias watch-mem='watch -n 2   -- free -h'
alias watch-nvi='watch -n 0.5 -- nvidia-smi'
alias watch-nft='watch -n 0.2 -- sudo nft list ruleset'

alias sude='sudo -E'

## ls
alias ls='eza \
    --time-style long-iso \
    --group-directories-first \
    --icons \
    --header \
    --binary \
    --group \
    --git \
' # End of `alias ls`

alias ll='ls --long'
alias la='ll --all'

## BBDown
    # `--multi-file-pattern` 参数的 `/` 是路径分隔符，视频在文件夹内
alias bbdown='BBDown \
    --file-pattern "<videoTitle> [<bvid>]" \
    --multi-file-pattern "<videoTitle> [<bvid>]/[P<pageNumberWithZero>] <pageTitle>" \
' # End of `alias bbdown`

## yt-dlp
alias yt-dlp='yt-dlp \
    --cookies-from-browser firefox \
    --embed-metadata \
    --embed-thumbnail \
' # End of `alias yt-dlp`

## Package Manage
alias ycr='yc -R'
alias ycrns='yc -Rns'
alias ycs='yc -S'
alias ycq='yc -Q'
alias ycl='yc -Ql'
alias ys='yay -S'

## 目录
alias tmp='cd /tmp'
alias down='cd $(xdg-user-dir DOWNLOAD)'
alias pub='cd $(xdg-user-dir PUBLICSHARE)'
alias pstow='cd $(xdg-user-dir PUBLICSHARE)/stow'
alias bilivideo='cd $(xdg-user-dir VIDEOS)/哔哩哔哩'
alias pkgs='cd $(xdg-user-dir PUBLICSHARE)/packages'

## 文件
alias hosts='edit /etc/hosts'
alias fstab='edit /etc/fstab'
alias epacman='edit /etc/pacman.conf'

## 其它

