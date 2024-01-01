param ([string] $InputGifPath)

$TABWIDTH_AUTO=25
$TABCOLOR_COVER="white"
$ANNOTATION_COLOR = "white"

$repeatX=1
$repeatY=4
$tabWidth="AUTO"
$tabColor="gray90"
$printMargin=50
$cutSpacing=1
$frameMultiplier=3
$annotationSize=30
$resize = 2

if ($InputGifPath -eq $null -or $InputGifPath -eq "") {
    write-host "Please specify the -InputGifPath parameter"
    return -1
}

New-Item -ItemType Directory tmp -Force

write-host "PRINT-A-GIF" 
write-host "Processing file: $InputGifPath"
write-host "┏━━━━━"

if (-not (Test-Path -Path $InputGifPath -PathType Leaf))
{
    write-host "┣ Error: Provided GIF file doesn't exist!"
    write-host "┻"
    return -2
}


# TBD - Check if the input is provided
# Image data
$imageWidth = Invoke-Expression "magick identify -format '%w' '$InputGifPath[0]'"

if($tabWidth -eq "AUTO")
{
    $tabWidth = ([int]$imageWidth * $TABWIDTH_AUTO) / 100 + 0.5
}

write-host "┣ image width:" $imageWidth
write-host "┣ tab width:" $tabWidth

$imageHeight = Invoke-Expression "magick identify -format '%h' '$inputGifPath[0]'"

write-host "┣ image height:" $imageHeight

# ???????????
$pageArea = ($tabWidth + $imageWidth) * [int]$imageHeight

# Create printable PDF
write-host "┣ image width x height:" $imageWidth"x"$imageHeight
write-host "┣ Area of the page:"$imageWidth 'x' $imageHeight '='  $pageArea
$t = New-Item -ItemType Directory -Name 'tmp' -f

$rawOutput = Invoke-Expression "magick identify -format '%w.' '$inputGifPath'"

$framesCount = ($rawOutput.toCharArray() | Where-Object {$_ -eq '.' } | Measure-Object).Count

write-host "┣ Frames count: $framesCount"

# Invoke-Expression "magick convert '$inputGifPath' -coalesce tmp/temp.gif"
# $inputGifPath = './tmp/temp.gif'
Invoke-Expression "magick convert -gravity east -coalesce '$inputGifPath' tmp/out.png"

$resizeImageHeight = [int]$imageHeight * $resize
$resizeImageWidth = [int]$imageWidth * $resize
$resizeGeometry = "$resizeImageWidth" + "x" + "$resizeImageHeight"
write-host "┣ Resize Geometry: $resizeGeometry"

$extentImageHeight = [int]$resizeImageHeight + $tabWidth
$extentGeometry = "$resizeImageWidth" + "x" + "$extentImageHeight"
$finalWidthExtent = [int]$resizeImageWidth + $tabWidth
$finalExtent = "$finalWidthExtent" + "x" + "$extentImageHeight"
write-host "┣ Extent Geometry: $finalExtent"

for ($i = 0; $i -lt $framesCount; $i++)
{
    Write-Progress -PercentComplete ($i/$framesCount*100) -Status "Processing frames" -Activity "Frame $i of $framesCount"
    Invoke-Expression "magick convert -gravity east -coalesce -resize $resizeGeometry -extent $finalExtent -compose src -border $cutSpacing -bordercolor white tmp/out-$i.png tmp/out-$i-$i.png"
}

if ($repeatY -eq "AUTO")
{
    # Paper dimensions (A4) = 2480 x 3508 at 300 DPI/PPI
    # 2480 ..... TOTALWIDTH
    # 3480 ..... REPEAT_Y*TOTALHEIGHT
    # So: REPEAT_Y*TOTALHEIGHT = TOTALWIDTH*3480/2480
    $totalWidth = $repeatX * ([int]$resizeImageWidth) + 2 * $printMargin + 2 * $cutSpacing
    write-host $totalWidth
    $totalHeight = [int]$extentImageHeight + 2 * $cutSpacing
    # $repeatY = (($totalWidth * 3480) / 2460) / $totalHeight
    $repeatY = 3480 / $totalHeight
    $repeatY = [Math]::Floor($repeatY)
}

write-host "┣ image grid per page:" $repeatX"x"$repeatY

$framesPerPage = $repeatX * $repeatY
$pageCount = $framesCount / $framesPerPage + 1
$missingFrameCount = $framesPerPage - $framesCount % $framesPerPage

if ($missingFrameCount -eq $framesPerPage)
{
    $missingFrameCount = 0
    $pageCount = $pageCount - 1
}

$pageCount = [math]::truncate($pageCount)

write-host "┣ Page Count: $pageCount"
write-host "┣ Missing Frames Count: $missingFrameCount"
write-host "┣ Frames per Page: $framesPerPage"
write-host "┣ Adding missing frames ..."

for ($i = $framesCount; $i -lt $framesCount + $missingFrameCount; $i++)
{
    Invoke-Expression "magick convert tmp/out-0-0.png -alpha Opaque +level-colors $TABCOLOR_COVER tmp/out-$i-$i.png"
}

$textSize = $annotationSize*($resizeImageWidth)/1120
write-host "┣ Annotating frames"

for ($i = 0; $i -lt $framesCount; $i++)
{
    Write-Progress -PercentComplete ($i/$framesCount*100) -Status "Annotating frames" -Activity "Frame $i of $framesCount"
    Invoke-Expression "magick convert -gravity west -fill $ANNOTATION_COLOR -pointsize $textSize -annotate 270x270+$annotationSize+0 $i tmp/out-$i-$i.png tmp/out-$i-$i.png"
}

$widthPadding = $printMargin
$heightPadding = $printMargin

write-host "┣ Preparing pages ..."

for ($i = 0; $i -lt $pageCount; $i++)
{
    Write-Progress -PercentComplete ($i/$pageCount*100) -Status "Preparing pages" -Activity "Page $i of $pageCount"
    $fileList = ""
    for ($j = 0; $j -lt $framesPerPage; $j++)
    {
        $N = $i * $framesPerPage + $j;
        $fileList += "tmp/out-$N-$N.png "
    }

    Invoke-Expression ("magick montage $fileList -tile $repeatX" + "x" + "$repeatY -geometry +0+0 tmp/tmp.png")
    Invoke-Expression ("magick convert -bordercolor none -border $widthPadding" + "x" + "$heightPadding tmp/tmp.png tmp/page-$i.png")
}

$outputFile = "flipbook.pdf"
write-host "┣ Exporting flipbook ..."

Invoke-Expression "magick convert tmp/page-*.png -page a4 $OUTPUTFILE"

Remove-Item tmp -Recurse

return 0
