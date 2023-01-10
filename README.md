# Print-A-Gif
Turn any GIF into a printable flip book via bash script!

<b>This is is a Linux bash script re-write of the original Print-A-Gif by stupotmcdoodlepip.</b> But it doesn't work the same way as the original in all the aspects but it mostly does and the spirit is the same.

You will need ImageMagick for image processing and bc installed to have this running properly.

Script usage:
```console
Print-A-Gif.sh [GIFFILE]
```

There is no GUI. You need to supply parameters in the script file itself.
```console
#####################################
# PARAMETERS DEFINITION
REPEATX=2
REPEATY="AUTO"
TABWIDTH="AUTO"
TABWIDTH_AUTO=30
PRINTMARGIN=30
CUTSPACING=1
FRAMEMULTIPLIER=3
ANNOTATIONSIZE=30
#####################################
```
The notes and tips below are mostly coming from the original!

Some notes on the parameters:  

- Use the REPEATX and REPEATY controls to choose how the images are tiled. I've found that 2 frames on wide works nicely. If REPEATY is set to "AUTO" then the script will fit as many as can vertically , otherwise you can provide any number you see fit.

- TABWIDTH: This is the width of the gluing / clamping area at the left of the frames. If this is set to "AUTO" then the TABWIDTH is automatically set to TABWIDTH_AUTO [%] of the width of the original frame but can be adjusted if preferred.

- PRINTMARGIN: This is the margin around the edge of each page of frames in the final output file. Adjust so that nothing is lost from the edges when printing. Ideal value is 0 as it will save you some cutting.

- CUTSPACING: This is the spacing between each frame. I tend to leave this set to 1 as it makes it easier to cut all the frames the same size with an scalpel.

- <span style="color:red">(New parameter)</span> FRAMEMULTIPLIER: This allows to repeat same frame multiple times. This may be useful to adjust the flip book speed.

- Bear in mind that TABWIDTH, PRINTMARGIN, CUTSPACING and FRAMEMULTIPLIER are subject to change when printed due to final scaling. Experiment if necessary.

- <span style="color:red">(New parameter)</span> ANNOTATIONSIZE: This allows to set the font size for the annotations. This relative value and shall be adjusted visually when seeing the result. The actual text size for the annotations is calculated automatically.

- All the interim images are placed in "tmp" folder and deleted at the end

- You may also see some blank frames at the end. These are used to pad out the final page if necessary. This ensured that all pages came out the same size and saved a lot of calculations.

- Now you can print the pdf and cut out the frames!

Tips:

- Be sure to leave adequate tab width for gluing / clamping. Too narrow and it's hard to see the left side of the images when flipping through the flip book.

- Stiffer paper, e.g., glossy photo paper lends to a better flipping experience

- When stacking the cut-out frames, slant the stack a little bit so that the bottom layers protrude a little further to the right than the top layers. This makes it easier to flip through the pages.

- Try to be as accurate as possible when cutting so that the left and right edges of the flip book aren't too jagged. There will inevitably be some variation.

- When stacking the frames, tap the right edge of the stack down on a table. It's more important that this edge is aligned when it comes to flipping through the book.

- Clamp the spine edge securely when gluing

Original demo video: https://www.youtube.com/watch?v=roJq69vgE2U

Example output of the script:
```console
PRINT-A-GIF
Processing file: the-simpsons-homer-simpson.gif
┏━━━━━
┣ tab width: 66
┣ image grid per page: 2x5
┣ image width x height: 220x165
┣ output image width x height: 286x165
┣ frame count: 29
┣ frame multiplier: 3
┣ adding repeating frames ... done
┣ enhanced frame count:  87
┣ frames per page:  10
┣ missing frame count:  3
┣ adding frames ... done
┣ page count:  9
┣ annotating frames (text size 7) ... done
┣ preparing pages ... done
┣ exporting flipbook-the-simpsons-homer-simpson.pdf ... done
┻
```
