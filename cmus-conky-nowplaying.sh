#!/bin/bash

## Script to get "now-playing" information and location of album art from cmus music player to use in conky.

## If you have ffmpeg binary in PATH , the script will fallback to try to extract the cover from ID3 Tags
## If you have sacad binary in PATH (https://github.com/desbma/sacad), the script will fallback to download cover from internet (google, amazon, etc)

## Make sure to include this script in your .conkyrc and point conky to the symlinked image.
## Note: As of now, this script links the image without the extension. This is due to .png files now being recognised.
## Please update your .conkyrc to reflect the change.
## You should position the image (with the -p option) close to the line where you execute the script,
## to ensure that the output takes it's place if it isn't present.

## Here is an example of what I put in my .conkyrc:
## ${execi 4 /home/ab/scripts/cmus-conky-art.sh}
## ${image /home/ab/conkyart -s 200x200 -p 4,470}

## OR

## Now playing:
##
## ${exec ~/Documents/cmus-conky-nowplaying.sh }
##
## ${execbar ~/Documents/cmus-conky-timebar.sh}
## ${image ~/conkyart -n -p 320,775 -s 96x96}

# The CONKART variable below determines where the art will be symlinked to ('conkyart' is the actual symlinked image):
CONKART="$HOME/conkyart"
tmp_cover=/tmp/cover.jpg
tmp_current=/tmp/current-cover

# If cmus is running...
if cmus-remote -Q &>/dev/null ; then
        # Get playing music data from cmus
        ARTIST=$(     cmus-remote -Q | grep 'tag artist' | cut -d" " -f 3-)
        ALBUM=$(      cmus-remote -Q | grep 'tag album'  | cut -d" " -f 3-)
        TITLE=$(      cmus-remote -Q | grep 'tag title'  | cut -d" " -f 3-)
        STATUS=$(     cmus-remote -Q | grep -E '^status '| cut -d" " -f 2-)
        DURATION=$(   cmus-remote -Q | grep -E '^duration '| cut -d" " -f 2-)
        POSITION=$(   cmus-remote -Q | grep -E '^position '| cut -d" " -f 2-)
        AUDIO_FILE=$( cmus-remote -Q | grep -E '^file '  | cut -c6- )
        AUDIO_FOLDER=$(dirname "$AUDIO_FILE")

        if [[ "$STATUS" = "playing" || "$STATUS" = "paused" ]]; then
                if [[ ${#TITLE} -gt 2 && ${#ARTIST} -gt 2 ]]; then
                        echo "$ARTIST"
                        echo "$TITLE"
                        DURATION=$(date -d@${DURATION} -u +%H:%M:%S)
                        POSITION=$(date -d@${POSITION} -u +%H:%M:%S)
                        echo "$DURATION / $POSITION - $STATUS"
                else
                        echo "$AUDIO_FILE"
                fi
        elif [[ $(~/Documents/vlc-dbus.sh status 2>/dev/null) = "Playing" ]] ; then
                echo Playing in VLC
                unlink "$CONKART"
                rm -f "$tmp_cover"
                # TODO: request info from VLC through DBUS
                exit 0
        else
                #Probably stopped or unknown
                echo $STATUS
                unlink "$CONKART"
                rm -f "$tmp_cover"
                exit 0
        fi

        if [[ $(cat "$tmp_current" 2>/dev/null) = "$AUDIO_FILE" ]]; then
                #Already processed, no need to do it again
                exit 0
        fi

        ART_FILE=$(find "$AUDIO_FOLDER" -regextype posix-egrep -iregex '.*/[^/]*(albumart.*|folder|cover|front)\.(jpg|png)'|head -n 1)

        if [ -z "$ART_FILE" ]; then
                rm -f "$tmp_cover"
                if ffmpeg -y -i "$AUDIO_FILE" "$tmp_cover" &>/dev/null;then
                        if [ -e "$tmp_cover" ]; then
                                ART_FILE="$tmp_cover"
                        fi
                fi
        fi

        if [ -z "$ART_FILE" ]; then
                rm -f "$tmp_cover"
                if sacad "$ARTIST" "$ALBUM" 200 "$tmp_cover" &>/dev/null ;then
                        if [ -e "$tmp_cover" ]; then
                                ART_FILE="$tmp_cover"
                        fi
                fi
        fi

        # If nothing is found, look for any jpg file and use first match.
        # This may result in the wrong image being displayed, as it will take any image found in the folder as a fallback.
        # If you would prefer not to risk that happening delete/comment out this section from "if" to "fi"
        if [ -z "$ART_FILE" ]; then
                ART_FILE=$(find "$AUDIO_FOLDER" -regextype posix-egrep -iregex '.*/.*\.(jpg|png)'|head -n 1)
        fi

        # If nothing is ultimately found, write some info
        if [ -z "$ART_FILE" ]; then
                echo "No album art."
                if [ -e "$CONKART" ]; then
                        unlink "$CONKART"
                        rm -f "$tmp_cover"
                fi
        else
                # If we found something...
                # Symlink result for a path with no spaces.
                # (conky doesn't seem to like spaces in file paths.)
                ln -sf "$ART_FILE" "$CONKART"
                echo "$AUDIO_FILE" > "$tmp_current"
        fi

# If nothing is playing/cmus is closed display message and remove any previous symlink to album art.
else
        echo "Nothing playing."

        if [ -e "$CONKART" ]; then
                unlink "$CONKART"
                rm -f "$tmp_cover"
        fi
fi

