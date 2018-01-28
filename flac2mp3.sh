# This script requires LAME, FLAC and metaFLAC binaries. Be sure
# to put them somewhere included in your $PATH variable
# (eg. /usr/local/bin). If you don't have them, you can download
# them from the following
# 
# FLAC - http://flac.sourceforge.net/
# LAME - http://lame.sourceforge.net/
#
# flac2mp3, as the name might suggest, batch converts flac files to
# mp3 (VBR 0, 44.1khz by default) and copies the flac metadata across
# to id3v2 tags. It'll also recurse through any subdirectories if
# specified by using the -R switch (or by changing the recurse variable
# below to 1).
#
# to do
# - Add output directory support
# - Preserve the directory hierarchy for the target
# - add support for splitting flac referencing a .cue. Maybe shntool or
#   something. Must be a better way than having to convert and process wav.
# - Add a switch to allow the user to specify custom arguments to be passed
#   to LAME, rather than having to edit the hardcoded defaults
# - Maybe a progress bar would be cool? I dunno

#!/bin/sh

RECURSE=0
SOURCE="./"
OUTPUT="./"

# process command line switches

while [ $# -gt 0 ]
do
	case "$1" in
		-R | -r | --recurse ) RECURSE=1;;
		-S | -s | --source  ) shift
						      SOURCE=$1;;
		-O | -o | --output  ) shift
						      OUTPUT=$1;;
		* ) echo -e >&2 \
			"usage: $0 [-R] [-s source] [-o output] \n" \
			"*note: output not actually implemented yet."
			exit 1;;
	esac
	shift
done

# set up the convert function for later use
# probably needs to be rewritten somewhat to implement the output
# folder and to keep the directory structure the same as the source

convert() {
	
	# set the output filename to that of the input file
	outf=`echo "$f" | sed s/\.flac$/.mp3/g`

	# grab the flac metadata
	eval "$(
		metaflac "$f" --show-tag=ARTIST \
					  --show-tag=TITLE \
					  --show-tag=ALBUM \
					  --show-tag=GENRE \
					  --show-tag=TRACKNUMBER \
					  --show-tag=DATE | sed 's/=\(.*\)/="\1"/'
	)"

	# let's do it!
	echo "Encoding $f..."
	flac -c -s -d "$f" | lame -S -q 0 -m s --vbr-new -V 0 -s 44.1 \
	--nohist --add-id3v2 --tt "$TITLE" --tn "${TRACKNUMBER:-0}" \
	--ta "$ARTIST" --tl "$ALBUM" --ty "$DATE" --tg "${GENRE:-12}" \
	- "$outf"
	echo -e "Complete! \n"
	
	return
}

# Checks if $SOURCE is a .flac file, and if so, converts it
# Otherwise, ensures $SOURCE and $OUTPUT trail with /

if [[ "$SOURCE" == *.flac ]]; then
	f=$SOURCE
	convert
	exit 0
else
	if [ `echo "$SOURCE" | grep "[^/]$"` ]; then
		SOURCE=$SOURCE"/"
	fi
fi

if [ `echo "$OUTPUT" | grep "[^/]$"` ]; then
	OUTPUT=$OUTPUT"/"
fi

# Performs batch conversions

if [ $RECURSE -eq 1 ]
	then
		find "$SOURCE" -name "*.flac" -print0 | while read -d $'\0' f
		do
			convert
		done
		exit 0
else
	for f in "$SOURCE"*.flac
	do
		if [ "$f" == "*.flac" ]; then
			echo -e "Couldn't find any .flac files to convert."
			exit 0
		fi
		convert
	done
	exit 0
fi
