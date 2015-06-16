#!/bin/bash
## Gets current track time for a bar in Conky.
## Usage: Put ${execbar /path/to/script} in your .conkyrc. 
## It might be useful to use ${goto x} or ${voffset x} to adjust position, and ${color #xxxxxx} for color.
## The 'default_bar_size x y' option can be used before the TEXT section in your .conkyrc to adjust height and width.
## Requires 'bc' for calculating percentage.

if cmus-remote -Q &>/dev/null ; then
    DUR=$( cmus-remote -Q | grep "duration" | cut -c10- )
    POS=$( cmus-remote -Q | grep "position" | cut -c10- )
    echo "($POS/$DUR)*100" | bc -l
fi
