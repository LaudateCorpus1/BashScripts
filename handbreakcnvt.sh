#!/bin/bash

#Globals

TBE="/home/jdtrout/Transcoding/tbe/"
ENCODE="/home/jdtrout/Transcoding/encoded/"

# all file names that have a space rename with an underscore.  This makes the file handling process easier.
find $TBE -type f | rename 's/\ /\_/g'

# read all file names into an array
vidArray=($(find $TBE -type f -printf %f\\n)) 

# get length of the array
LEN=${#vidArray[@]}

for (( i=0; i<${LEN}; i++ ));
do
  TBEFILE="${vidArray[$i]}"
  echo $TBEFILE

  
  # determan file type
  EXT=${TBEFILE/*./}
  
  # remove extention for filename
  ENCFILE=$(basename $TBEFILE $EXT)
  
  # rename files to lowercase comment out if you don't need 

  echo "Transcoding $TBEFILE"
  HandBrakeCLI -i $TBE$TBEFILE -o $ENCODE$ENCFILE\mp4 -f mp4 --preset="AppleTV 2"
  
done

# convert all underscore to spaces because it looks nicer  
find $ENCODE -type f | rename 's/\_/\ /g'
