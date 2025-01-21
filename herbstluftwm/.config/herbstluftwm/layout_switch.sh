#!/bin/zsh
# LICENSE: PUBLIC DOMAIN
# switch between my layouts

# If an explicit layout is provided as an argument, use it. Otherwise, select the next layout from
# the set [us, it, fr].
if [[ -n "$1" ]]; then
    setxkbmap $1 && xmodmap ~/.Xmodmap
else
    layout=$(setxkbmap -query | awk 'END{print $2}')
    case $layout in
        no)
                xmodmap ~/.config/herbstluftwm/.Xmodmap.no
            ;;
        us)
                xmodmap ~/.config/herbstluftwm/.Xmodmap.us
            ;;
        *)
                xmodmap ~/.Xmodmap.us
            ;;
    esac
fi
