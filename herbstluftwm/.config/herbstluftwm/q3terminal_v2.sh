#!/bin/bash

# a q3-like (or yakuake-like) terminal for arbitrary applications.
#
# this lets a new monitor scroll in from the top, bottom, left or right
# respectively, into the current monitor. There a separate tag will be 
# shown (it will be created if it doesn't exist yet). If the monitor 
# already exists it is scrolled out of the screen and removed again.
#
# Warning: this uses much resources because herbstclient is forked for each
# animation step.
#
# If no arguments is supplied, a scratchpad will be scrolled in from the top.

tag="${1:-scratchpad}"
hc() { "${herbstclient_command[@]:-herbstclient}" "$@" ;}

idxW=0
idxH=1
idxX=2
idxY=3
mrect=( $(hc detect_monitors -l | awk -F '[+x]' 'NR<=1 {print $1, $2, $3, $4}') )
termwidth=$(( (${mrect[$idxW]} * 8) / 10 ))
termheight=$(( (${mrect[$idxH]} * 4) / 10 ))

echo 'termwidth: ' ${termwidth}
echo 'termheight: ' ${termheight}

top() {
    visible=(
        $termwidth
        $termheight
        $(( ${mrect[$idxX]} + (${mrect[$idxW]} - termwidth) / 2 ))
        ${mrect[$idxY]}
    )

    invisible=(
        $termwidth
        $termheight
        $(( ${mrect[$idxX]} + (${mrect[$idxW]} - termwidth) / 2 ))
        $(( ${mrect[$idxY]} - termheight))
    )
}
bottom() {
    visible=(
        $termwidth
        $termheight
        $(( ${mrect[$idxX]} + (${mrect[$idxW]} - termwidth) / 2 ))
        $(( ${mrect[$idxH]} - termheight))
    )

    invisible=(
        $termwidth
        $termheight
        $(( ${mrect[$idxX]} + (${mrect[$idxW]} - termwidth) / 2 ))
        ${mrect[$idxH]}
    )
}
left() {
    local width=$(($termwidth / 2))
    local height=$(($termheight * 2))
    visible=(
        $width
        $height
        ${mrect[$idxX]}
        $(( ${mrect[$idxY]} + (${mrect[$idxH]} - height) / 2 ))
    )

    invisible=(
        $width
        $height
        $(( ${mrect[$idxX]} - width))
        $(( ${mrect[$idxY]} + (${mrect[$idxH]} - height) / 2 ))
    )
}
right() {
    local width=$(($termwidth / 2))
    visible=(
        $width
        $termheight
        $((${mrect[$idxW]} - width))
        $(( ${mrect[$idxY]} + (${mrect[$idxH]} - termheight) / 2 ))
    )

    invisible=(
        $width
        $termheight
        ${mrect[$idxW]}
        $(( ${mrect[$idxY]} + (${mrect[$idxH]} - termheight) / 2 ))
    )
}

${1:-top}

#echo Visible rect: ${visible[@]}

#echo Invisible: ${invisible[@]}

hc add "$tag"

monitor=${1:-q3terminal}

exists=false
if ! hc add_monitor $(printf "%dx%d%+d%+d" "${rect[@]}") \
                    "$tag" $monitor 2> /dev/null ; then
    exists=true
else
    # remember which monitor was focused previously
    hc chain \
        , new_attr string monitors.by-name."$monitor".my_prev_focus \
        , substitute M monitors.focus.index \
            set_attr monitors.by-name."$monitor".my_prev_focus M
fi

update_geom() {
    local geom=$(printf "%dx%d%+d%+d" "${rect[@]}")
    hc move_monitor "$monitor" $geom
}

steps=5
interval=0.01

animate() {
    progress=( "$@" )
    for i in "${progress[@]}" ; do
        rect[0]=$((invisible[0] + (i * (visible[0]-invisible[0]) / steps)))
        rect[1]=$((invisible[1] + (i * (visible[1]-invisible[1]) / steps)))
        rect[2]=$((invisible[2] + (i * (visible[2]-invisible[2]) / steps)))
        rect[3]=$((invisible[3] + (i * (visible[3]-invisible[3]) / steps)))
        #echo 'Moving to ' ${rect[@]}
        update_geom
        sleep "$interval"
    done
    #echo 'Finished'
}

show() {
    #echo 'Show'
    hc lock
    hc raise_monitor "$monitor"
    hc focus_monitor "$monitor"
    hc unlock
    hc lock_tag "$monitor"
    animate $(seq 0 +1 $steps)
}

hide() {
    #echo 'Hide'
    #rect=( $(hc monitor_rect "$monitor" ) )
    rect=( $(hc monitor_rect ) )
    animate $(seq $steps -1 0)
    # if q3terminal still is focused, then focus the previously focused monitor
    # (that mon which was focused when starting q3terminal)
    hc substitute M monitors.by-name."$monitor".my_prev_focus \
        and + compare monitors.focus.name = "$monitor" \
            + focus_monitor M
    hc remove_monitor "$monitor"
}

[ $exists = true ] && hide || show



