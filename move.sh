#!/bin/sh
usage() {
    echo "${0} - Position hot-babe on screen."
    echo 'Usage:'
    echo "  ${0} [<theme>] [<X margin> <Y margin> <X alignment> <Y alignment>] [<Z-order>]"
    echo ' where'
    echo '  <theme> is the name of a theme directory in ~/.hot-babe or "default",'
    echo '  <X/Y margin> is given in pixels or percentage of screensize (integer only),'
    echo '  <X/Y alignment> is given as left/right and top/bottom, respectively, and'
    echo '  <Z-order> is above or below. This option can be given independently of the'
    echo '            other positioning arguments; if given it must come last (or instead'
    echo '            of the theme name).'
    echo
    echo 'If <theme> is not specified (or "default" is given), the script will try to'
    echo 'find a running Hot Babe and determine if a "--dir <theme>" argument was given.'
    echo
    echo 'Note that this script will only make a limited effort at locating the'
    echo 'files for the default theme; locate it and copy to your ~/.hot-babe if'
    echo 'this fails.'
    echo
    echo 'Default values are: Zero margins, bottom-right alignment, below other windows.'
    echo
    exit 1
}

if [ $# -eq 0 ] ; then
    usage
fi

#### Configuration/Defaults ####

# Theme directory name
theme=${1:-default} # Will default hot-babe theme, if it can be found
if hbpid=$(pgrep -x hot-babe) ; then
    # Seems to be running. Check if --dir was passed, and extract its value if so
    if runningTheme=$(ps -o args= -p $hbpid | \
        grep -o -- '--dir [^[:space:]]*' | \
        cut -f 2 -d ' ' \
    ) ; then
        # Whatever was given on the command line, we override with the running theme
        theme=$runningTheme
    fi

    if [ "$2" ] && ! [ "${2%%%}" -eq "${2%%%}" ] 2>/dev/null ; then
        # Both theme and Z-order was given (or at least two string values - whatever
        # they might be.) Toss away the first argument. The suffix pattern removal
        # allows passing of percentage values for margins (removing any trailing %
        # before checking if the remainder is still a string).
        shift
    fi
fi

if [ "${1%%%}" -eq "${1%%%}" ] 2>/dev/null ; then
    # The first remaining argument is a number, so any Z-order argument must be $5
    casevar=$5
else
    if [ "$6" ] ; then
        # If a sixth argument was given, it's our Z-order
        casevar=$6
        shift
    else
        # Hopefully the first remaining argument is Z-order
        # Of course this means the usage() text is slightly wrong..
        casevar=$1
        shift
    fi
fi

# Z-order; above/below
# Define the zorder() function which constructs the xdotool command
case $casevar in
    [Aa][Bb][Oo][Vv][Ee])
        zorder() { echo "windowstate --remove BELOW $1 windowstate --add ABOVE $1"; }
        ;;
    [Bb][Ee][Ll][Oo][Ww])
        # Defer to the default
        ;&
    *)
        zorder() { echo "windowstate --remove ABOVE $1 windowstate --add BELOW $1"; }
esac

# Margins set in integer pixels or percentage points
Xmargin=${1:-0} # Default no horizontal margin
Ymargin=${2:-0} # Default no vertical margin

# Alignment; left/right and top/bottom
Xalign=${3:-right} # Default right-edge
Yalign=${4:-bottom} # Default bottom-edge


if [ "${1}" ] ; then
    # If we have any arguments remaining..
    if [ -z "${4}" ] ; then
        # ..but not at least four, then we're missing some.
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
# Using 'set' this way splits the passed value by IFS and assigns to positional
# parameters.
IFS=' ' set -- $(xprop -root _NET_DESKTOP_GEOMETRY|tr -d ,|cut -f 3,4 -d ' ')
scrwidth=$1
scrheigth=$2

if ! [ "$scrwidth" -gt 0 ] || ! [ "$scrheigth" -gt 0 ] ; then
    echo "Could not determine screen dimensions. Does 'xprop' work at all?"
    echo "Got '$scrwidth' and '$scrheigth'."
    exit 1
fi

# Calculate margins
if [ "${Xmargin%%%}" -ge 0 ] && ! [ "${Xmargin}" -gt 0 ] 2>/dev/null ; then
    # Margins apparently given in %
    marginX=$((scrwidth*${Xmargin%%%}/100))
else
    marginX=$Xmargin
fi
if [ "${Ymargin%%%}" -ge 0 ] && ! [ "${Ymargin}" -gt 0 ] 2>/dev/null ; then
    # Margins apparently given in %
    marginY=$((scrheigth*${Ymargin%%%}/100))
else
    marginY=$Ymargin
fi

if ! [ "$marginX" -ge 0 ] || ! [ "$marginY" -ge 0 ] ; then
    echo "Could not calculate margins. Was given '$marginX' and '$marginY'."
    usage
fi

# Get dimensions of first image in the animation
IFS=' ' set -- $(file "${first}"|grep -Eo '[0-9]{1,4} x [0-9]{1,4}'|cut -f 1,3 -d ' ')
imgwidth=$1
imgheigth=$2

if ! [ "$imgwidth" -gt 0 ] || ! [ "$imgheigth" -gt 0 ] ; then
    echo "Could not determine image dimensions. Check that the 'file' command gives sane output."
    echo "Its output must contain image dimensions matching the regex '[0-9]{1,4} x [0-9]{1,4}'."
    echo "(Was given '$imgwidth' and '$imgheigth'.)"
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
        echo "Xalign not correctly specified ('right' or 'left'). Was given '$Xalign'."
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
        echo "Yalign not correctly specified ('top' or 'bottom'). Was given '$Yalign'."
        usage
esac

# Let's wait for the Babe to show up.
wait=0
while [ $wait -lt 10 ] ; do
    if window=$(xdotool search --class hot-babe) ; then
        echo "The Hot Babe is here, relocating.."
        xdotool windowmove $window $posX $posY $(zorder $window)
        exit 0
    else
        wait=$((wait+2))
        # Let's not sit around for those last 2 seconds
        if [ $wait -ge 10 ] ; then
            break
        fi
        sleep 2
    fi
done

echo 'Waited too long for the Hot Babe. Bailing out!'
