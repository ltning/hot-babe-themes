#!/bin/sh
#### Configuration/Defaults ####

# Theme directory name
theme=${1:-default} # Will default hot-babe theme, if it can be found

# Margins set in integer percentage points
XmarginPct=${2:-2} # Default 2% of screen width
YmarginPct=${3:-0} # Default no vertical margin

# Alignment; left/right and top/bottom
Xalign=${4:-right} # Default right-edge
Yalign=${5:-bottom} # Default bottom-edge


#### Do not modify beyond this line ####
usage() {
    echo '${0} - Position hot-babe on screen.'
    echo 'Usage:'
    echo "   ${0} <theme> [<X margin> <Y margin> <X alignment> <Y alignment>]"
    echo ' where'
    echo '   <theme> is the name of a theme directory in ~/.hot-babe or "default",'
    echo '   <X/Y margin> is given in percentage of screensize (integer only), and'
    echo '   <X/Y alignment> is given as left/right and top/bottom, respectively.'
    echo
    echo 'Note that this script will only make a limited effort at locating the'
    echo 'files for the default theme; locate it and copy to your ~/.hot-babe if'
    echo 'this fails.'
    echo
    exit 1
}

if [ "${2}" ] ; then
    if [ -z "${5}" ] ; then
        echo "If any positional options are given, all must be given."
        echo
        usage
    fi
fi

# Determine where the themes are (typically where this script is run from, or
# the default theme directory), and the first file in the animation
if [ "${theme}" = 'default' ] ; then
    case $(uname) in
        FreeBSD)
            first="$(pkg info -l hot-babe|grep '\.png$'|head -1)"
            ;;
        NetBSD|OpenBSD)
            first="$(pkg_info -L hot-babe|grep '\.png$'|head -1)"
            ;;
        *)
            echo "Platform $(uname) not supported."
            usage
    esac
    dir="$(dirname "$first")"
else
    dir="$(dirname $(realpath $0))/${theme}"
    first="${dir}/$(head -2 "${dir}/descr" | tail -1)"
fi

if ! [ -f "${dir}/descr" ] ; then
    echo "Could not locate theme config in ${dir}! Bailing.."
    exit 1
fi

# Extract screen dimensions from xprop
IFS=' ' set -- $(xprop -root _NET_DESKTOP_GEOMETRY|tr -d ,|cut -f 3,4 -d ' ')
scrwidth=$1
scrheigth=$2
unset IFS

if ! [ "$scrwidth" -gt 0 ] || ! [ "$scrheigth" -gt 0 ] ; then
    echo "Could not determine screen dimensions. Does 'xprop' work at all?"
    exit 1
fi

# Calculate margins
marginX=$((scrwidth*XmarginPct/100))
marginY=$((scrheigth*YmarginPct/100))

if ! [ "$marginX" -ge 0 ] || ! [ "$marginY" -ge 0 ] ; then
    echo "Could not calculate margins."
    usage
fi

# Get dimensions of first image in the animation
IFS=' ' set -- $(file "${first}"|grep -Eo '[0-9]{1,4} x [0-9]{1,4}'|cut -f 1,3 -d ' ')
imgwidth=$1
imgheigth=$2
unset IFS

if ! [ "$imgwidth" -gt 0 ] || ! [ "$imgheigth" -gt 0 ] ; then
    echo "Could not determine image dimensions. Check that the 'file' command gives sane output."
    echo "Its output must contain image dimensions matching the regex '[0-9]{1,4} x [0-9]{1,4}'."
    exit 1
fi

case $Xalign in
    right)
        posX=$(((scrwidth-marginX)-imgwidth))
        ;;
    left)
        posX=$marginX
        ;;
    *)
        echo "Xalign not correctly specified ('right' or 'left')"
        usage
esac

case $Yalign in
    top)
        posY=$marginY
        ;;
    bottom)
        posY=$(((scrheigth-marginY)-imgheigth))
        ;;
    *)
        echo "Yalign not correctly specified ('top' or 'bottom')"
        usage
esac

wait=0
while [ $wait -lt 10 ] ; do
    if [ $(xdotool search --name hot-babe | wc -l) -gt 0 ] ; then
        echo "The Hot Babe is here, relocating.."
        sleep 0.5
        xdotool search --name hot-babe windowmove %2 $posX $posY windowstate --add BELOW %2
        exit 0
    else
        wait=$((wait+2))
        if [ $wait -ge 10 ] ; then
            break
        fi
        sleep 2
    fi
done

echo 'Waited too long for the Hot Babe. Bailing out!'
