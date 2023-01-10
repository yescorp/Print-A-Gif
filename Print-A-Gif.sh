#! /bin/bash
#####################################
# PARAMETERS DEFINITION
REPEATX=2
REPEATY="AUTO"
TABWIDTH="AUTO"
TABWIDTH_AUTO=30
PRINTMARGIN=50
CUTSPACING=1
FRAMEMULTIPLIER=3
ANNOTATIONSIZE=30
#####################################
# Input
if [ $# -eq 0 ]
then
    echo "Error: No arguments supplied! You must provide a GIF file to process!"
    exit 1
fi
INPUTFILE=$1
echo "PRINT-A-GIF" 
echo "Processing file:" $INPUTFILE
echo "┏━━━━━"
if [ ! -f $INPUTFILE ]
then
    echo "┣ Error: Provided GIF file doesn't exist!"
    echo "┻"
    exit 1    
fi

# TBD - Check if the input is provided
# Image data
IMWIDTH=$(identify -format '%w' $INPUTFILE[0])
if [ "$TABWIDTH" = "AUTO" ]
then
    TABWIDTH=$(bc <<< "($IMWIDTH*$TABWIDTH_AUTO/100+0.5)/1")
fi
echo "┣ tab width:" $TABWIDTH
IMHEIGHT=$(identify -format '%h' $INPUTFILE[0])
NEW_IMWH="$(bc <<< "$IMWIDTH + $TABWIDTH")x$IMHEIGHT"

if [ "$REPEATY" = "AUTO" ]
then
    # Paper dimensions (A4) = 2480 x 3508 at 300 DPI/PPI
    # 2480 ..... TOTALWIDTH
    # 3480 ..... REPEAT_Y*TOTALHEIGHT
    # So: REPEAT_Y*TOTALHEIGHT = TOTALWIDTH*3480/2480
    TOTALWIDTH=$(bc <<< "$REPEATX*($IMWIDTH+$TABWIDTH)+2*$PRINTMARGIN+2*$CUTSPACING")
    TOTALHEIGHT=$(bc <<< "$IMHEIGHT+2*$CUTSPACING")
    REPEATY=$(bc <<< "$TOTALWIDTH*3480/2460/$TOTALHEIGHT")
fi
echo "┣ image grid per page:" $REPEATX"x"$REPEATY

# Create printable PDF
echo "┣ image width x height:" $IMWIDTH"x"$IMHEIGHT
echo "┣ output image width x height:" $NEW_IMWH
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
echo "┣ frame count:" $FILECOUNT
echo "┣ frame multiplier:" $FRAMEMULTIPLIER
echo -ne "┣ adding repeating frames ... "
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
echo "done"
FILECOUNT=$(ls -l tmp/out*.png | wc -l)
echo "┣ enhanced frame count: " $FILECOUNT
FRAMESPERPAGE=$(bc <<< "$REPEATX * $REPEATY")
echo "┣ frames per page: " $FRAMESPERPAGE
PAGECOUNT=$(bc <<< "$FILECOUNT / $FRAMESPERPAGE + 1")
# If final page of frames isn't full, we still need to make it the same size / scaling as previous pages
MISSINGFRAMECOUNT=$(bc <<< "$FRAMESPERPAGE - $FILECOUNT % $FRAMESPERPAGE")
if [ "$MISSINGFRAMECOUNT" -eq $FRAMESPERPAGE ]; then
    MISSINGFRAMECOUNT=0
    PAGECOUNT=$(bc <<< "$PAGECOUNT - 1")
fi
echo "┣ missing frame count: " $MISSINGFRAMECOUNT
echo -ne "┣ adding frames ... "
for (( i=$FILECOUNT; i<$FILECOUNT+$MISSINGFRAMECOUNT; i++ ))
do
    # Just making a blank frame from scratch results in weird spacing for some reason, so take an existing frame and just wipe it clean
    magick convert tmp/out-0.png -alpha Opaque +level-colors White tmp/out-$i.png
done
echo "done"
echo "┣ page count: " $PAGECOUNT
# Write frame number in binding tab
TEXTSIZE=$(bc <<< "$ANNOTATIONSIZE*($IMWIDTH + $TABWIDTH)/1120")
echo -ne "┣ annotating frames (text size $TEXTSIZE) ... "
for (( i=1; i<$FILECOUNT+$MISSINGFRAMECOUNT; i++ ))
do 
    magick convert tmp/out-$i.png -gravity West -fill blue -pointsize $TEXTSIZE -annotate 270x270+$ANNOTATIONSIZE+0 "$i" tmp/out-$i.png 
done
echo "done"
# Prepare pages
WIDTHPADDING=$PRINTMARGIN
HEIGHTPADDING=$PRINTMARGIN
PAGELIST=""
echo -ne "┣ preparing pages ... "
for (( i=0; i<$PAGECOUNT; i++ ))
do
    FILELIST=""
    for (( j=0; j<$FRAMESPERPAGE; j++ ))
    do
        N=$(bc <<< "$i*$FRAMESPERPAGE+$j")
        FILELIST+="tmp/out-$N.png "
    done
    magick montage $FILELIST -tile $REPEATX"x"$REPEATY -geometry +0+0 tmp/tmp.png
    printf -v i08 "%08d" $i
    magick convert tmp/tmp.png -bordercolor none -border $WIDTHPADDING"x"$HEIGHTPADDING tmp/page-$i08.png
    PAGELIST+="tmp/page-$i.png "
done
echo "done"

# Output PDF
OUTPUTFILE="flipbook-"
OUTPUTFILE+=$(basename "$INPUTFILE" .gif)
OUTPUTFILE+=".pdf"
echo -ne "┣ exporting $OUTPUTFILE ... "
magick convert tmp/page-*.png -page a4 $OUTPUTFILE
echo "done"
# Clean up
rm -r tmp
echo "┻" 