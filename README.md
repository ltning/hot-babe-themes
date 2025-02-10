# What in the nine hells is this?!?
Themes, config and scripts for the hot-babe CPU monitor.

## Contents
There's a default `config` file, which you can modify at will. See `hot-babe(1)` for details.

Then there's `move.sh`, which uses `xprop(1)` and `xdotool(1)` to move `hot-babe` to a suitable place on your screen. Some window managers do not let you move it, and the claimed `--geometry` option to `hot-babe` does not seem to work - hence this script.

Lastly, there's a set of themes. See below for usage instructions.

## But .. why??
Because `hot-babe` has been available on most/all BSD/UNIX/Linux variants out there for ever so long, and yet there are no themes for it to be found anywhere. Or maybe they're all in private "collections" and possibly not suitable for public consumption?

Fully understanding the controversial nature of the `hot-babe` package, and making no attempt to defend or excuse the blatantly misogynistic and otherwise discriminating history (and, to be fair, present) of the computer industry, I've added a couple of skins that I believe to be in the spirit of the original author and artist.

## Who are the artists?
The original images have been found through various image searches, and despite significant effort I have not been able to track down their origins. This is unfortunate, and I hope to replace them with other themes where origins and licenses are known and appropriate.

## License
See license file. The theme image files may be from other origins and thus not necessarily covered under the default license. Fair-use rights are assumed.

# Usage
Install `hot-babe`, `xdotool` and `xprop`. Clone this repository - I suggest you name it `~/.hot-babe`. Pick a theme, and run `hot-babe --dir <theme>`, followed by `sh move.sh <theme>`. Run `sh move.sh` without parameters to see the options you can pass.
