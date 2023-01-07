#! /bin/bash
#####################################
# PARAMETERS DEFINITION
REPEATX=2
REPEATY=3
TABWIDTH=44
# TBD: Tab width needs to be calculated
PRINTMARGIN=30
CUTSPACING=1
FRAMEMULTIPLIER=3
#####################################
# Input
INPUTFILE=$1
# TBD - Check if the input is provided
# Image data
IMWIDTH=$(identify -format '%w' $INPUTFILE[0])
IMHEIGHT=$(identify -format '%h' $INPUTFILE[0])
NEW_IMWH="$(bc <<< "$IMWIDTH + $TABWIDTH")x$IMHEIGHT" 

# Preview - TBD
# Create printable PDF
echo "Processing file: " $INPUTFILE
echo "Image width x height: " $IMWIDTH"x"$IMHEIGHT
echo "Output image width x height: " $NEW_IMWH
mkdir tmp
# coalesce (rather than convert) ensures frames are same size. Convert may create different sized frames for some kinds of gifs. Apparently.
# Separate gifs into frames, add grey binding tab to the left and yellow spacing border to each frame
magick convert $INPUTFILE -coalesce tmp/$INPUTFILE
INPUTFILE="tmp/"$INPUTFILE

magick convert \
    -coalesce -gravity east -extent $NEW_IMWH -background gray90 -bordercolor yellow -border $CUTSPACING \
    $INPUTFILE tmp/out.png

# Multiply frames

FILECOUNT=$(ls -l tmp/out*.png | wc -l)
echo "Frame count:" $FILECOUNT
echo "Frame multiplier:" $FRAMEMULTIPLIER
echo "Adding repeating frames"
if [ "$FRAMEMULTIPLIER" -gt "1" ]
then
    for (( i=$(bc <<< "$FILECOUNT-1"); i>=0; i-- ))
    do 
        # Rename first
        N=$(bc <<< "($i+1)*$FRAMEMULTIPLIER-1")
        mv tmp/out-$i.png tmp/out-$N.png
        # Add repeated frames
        for (( j=$(bc <<< "$N-1"); j>$(bc <<< "$N-$FRAMEMULTIPLIER"); j-- ))
        do
            cp tmp/out-$N.png tmp/out-$j.png
        done
    done
fi
FILECOUNT=$(ls -l tmp/out*.png | wc -l)
echo "Enhanced frame count: " $FILECOUNT
FRAMESPERPAGE=$(bc <<< "$REPEATX * $REPEATY")
echo "Frame per page: " $FRAMESPERPAGE
PAGECOUNT=$(bc <<< "$FILECOUNT / $FRAMESPERPAGE + 1")
# If final page of frames isn't full, we still need to make it the same size / scaling as previous pages
MISSINGFRAMECOUNT=$(bc <<< "$FRAMESPERPAGE - $FILECOUNT % $FRAMESPERPAGE")
if [ "$MISSINGFRAMECOUNT" -eq $FRAMESPERPAGE ]; then
    MISSINGFRAMECOUNT=0
    PAGECOUNT=$(bc <<< "$PAGECOUNT - 1")
fi
echo "Missing frame count: " $MISSINGFRAMECOUNT
for (( i=$FILECOUNT; i<$FILECOUNT+$MISSINGFRAMECOUNT; i++ ))
do
    # Just making a blank frame from scratch results in weird spacing for some reason, so take an existing frame and just wipe it clean
    echo "Adding frame: $i"
    magick convert tmp/out-0.png -alpha Opaque +level-colors White tmp/out-$i.png
done
echo "Page count: " $PAGECOUNT
# Write frame number in binding tab
for (( i=1; i<$FILECOUNT+$MISSINGFRAMECOUNT; i++ ))
do 
    echo "Annotating frame: $i"
    magick convert tmp/out-$i.png -gravity West -fill blue -pointsize 10 -annotate 270x270+10+0 "$i" tmp/out-$i.png 
done
# Prepare pages - Paper dimensions (A4) = 210 x 297
TOTALWIDTH=$(bc <<< "$REPEATX * ($IMWIDTH + $TABWIDTH + ($CUTSPACING * 2))")
TOTALHEIGHT=$(bc <<< "$REPEATY * ($IMHEIGHT + ($CUTSPACING * 2))")
WIDTHFILL=$(bc <<< "210F / $TOTALWIDTH")
HEIGHTFILL=$(bc <<< "297F / $TOTALHEIGHT")

if [ "$WIDTHFILL" -lt "$HEIGHTFILL" ]; then
    WIDTHPADDING=0
    HEIGHTPADDING=$(bc <<< "(((($WIDTHFILL*TOTALHEIGHT))/$WIDTHFILL)/2)+$PRINTMARGIN")
else
    WIDTHPADDING =$(bc <<< "(((($HEIGHTFILL*TOTALWIDTH))/$HEIGHTFILL)/2)+$PRINTMARGIN")
    HEIGHTPADDING=0
fi
echo "Fill: "$WIDTHFILL"x"$HEIGHTFILL
echo "Padding: "$WIDTHPADDING"x"$HEIGHTPADDING 

WIDTHPADDING=0
HEIGHTPADDING=0
PAGELIST=""
for (( i=0; i<$PAGECOUNT; i++ ))
do
    FILELIST=""
    for (( j=0; j<$FRAMESPERPAGE; j++ ))
    do
        N=$(bc <<< "$i*$FRAMESPERPAGE+$j")
        FILELIST+="tmp/out-$N.png "
    done
    echo "Page $i: "$FILELIST
    magick montage $FILELIST -tile $REPEATX"x"$REPEATY -geometry +0+0 tmp/tmp.png
    printf -v i08 "%08d" $i
    magick convert tmp/tmp.png -bordercolor none -border $WIDTHPADDING"x"$HEIGHTPADDING tmp/page-$i08.png
    PAGELIST+="tmp/page-$i.png "
done

# Output PDF
magick convert tmp/page-*.png -page a4 output.pdf
# Clean up
rm -r tmp 