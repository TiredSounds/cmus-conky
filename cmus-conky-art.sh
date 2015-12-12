#!/bin/bash
## Script to get location of album art from cmus music player to use in conky.

## Make sure to include this script in your .conkyrc and point conky to the symlinked image.
## Note: As of now, this script links the image without the extension. This is due to .png files now being recognised.
## Please update your .conkyrc to reflect the change.
## You should position the image (with the -p option) close to the line where you execute the script,
## to ensure that the output takes it's place if it isn't present.

## Here is an example of what I put in my .conkyrc:
## ${execi 4 /home/ab/scripts/cmus-conky-art.sh}
## ${image /home/ab/conkyart -s 200x200 -p 4,470}
 
## The CONKART variable below determines where the art will be symlinked to ('conkyart' is the actual symlinked image):

CONKART=$( echo "$HOME/conkyart" )

# If cmus is running...
if cmus-remote -Q &>/dev/null ; then

        # Get directory for album art.
        FOLDER=$( cmus-remote -Q | grep 'file ' | cut -c6- | sed 's:/[^/]*$::' )

        # Find an image matching a string of common names. Add more as you wish using '\|foo.jpg' as the structure.
        FILE=$( ls "$FOLDER" | grep -iw -m1 'folder.jpg\|cover.jpg\|front.jpg\|folder.png\|cover.png\|front.png' )
	
	# If nothing is found, look for any jpg file and use first match.
	# This may result in the wrong image being displayed, as it will take any image found in the folder as a fallback.
	# If you would prefer not to risk that happening delete/comment out this section from "if" to "fi"
	if [ -z "$FILE" ]; then
		FILE=$( ls "$FOLDER" | grep -i -m1 '.jpg\|.png' )
	fi

        # If nothing is ultimately found, display a message and remove any previous symlink to album art if present.
        if [ -z "$FILE" ]; then
                echo "No album art."
                if [ -e $CONKART ]; then
                        unlink $CONKART
                fi
	
	# If we found something...
        else
	
                # Combine folder and filename together and symlink result for a path with no spaces.
                # (conky doesn't seem to like spaces in file paths.)
                ln -sf "$FOLDER/$FILE" $CONKART
        fi
	
# If nothing is playing/cmus is closed display message and remove any previous symlink to album art.
else
        echo "Nothing playing."
       
        if [ -e $CONKART ]; then
                unlink $CONKART
        fi
fi
