#!/bin/sh

if [ -z "$1" ]
  then
    echo "No argument supplied"
    exit 1
fi

FUZZ=70%
STEPS=30
FILENAME=$1
ADDITIONAL=5

FILE=$(basename "$1")
EXT="${FILE##*.}"
TARGET="${FILENAME%%.*}"-cropped."${EXT}"

convert $FILENAME -auto-level -colorspace gray +dither -colors $STEPS gray.png
convert gray.png -scale x1! -auto-level x-axis.png
convert gray.png -scale 1x! -auto-level y-axis.png
read ORIGINAL_H ORIGINAL_W <<< $(convert gray.png -format "%H %W" info:- | sed s/+//)
read CONVERT_H CROP_TOP <<< $(convert y-axis.png -bordercolor black -border 1 -fuzz $FUZZ -trim -format "%h %Y" info:- | sed s/+//)
read CONVERT_W CROP_LEFT <<< $(convert x-axis.png -bordercolor black -border 1 -fuzz $FUZZ -trim -format "%w %X" info:- | sed s/+//)
rm x-axis.png
rm y-axis.png
rm gray.png

# Remove the border numbers
CROP_TOP=$((CROP_TOP-1))
CROP_LEFT=$((CROP_LEFT-1))

CROP_RIGHT=$((ORIGINAL_W - CONVERT_W - CROP_LEFT))
CROP_BOTTOM=$((ORIGINAL_H - CONVERT_H - CROP_TOP))

echo "Original: $ORIGINAL_W x $ORIGINAL_H"
echo "New:      $CONVERT_W x $CONVERT_H"
echo "Cropped:"
echo "  Top:    $CROP_TOP"
echo "  Bottom: $CROP_BOTTOM"
echo "  Left:   $CROP_LEFT"
echo "  Right:  $CROP_RIGHT"

if(($CROP_BOTTOM > $CROP_TOP)); then
  Y_OFFSET=$CROP_BOTTOM
else
  Y_OFFSET=$CROP_TOP
fi

if(($CROP_RIGHT > $CROP_LEFT)); then
  X_OFFSET=$CROP_RIGHT
else
  X_OFFSET=$CROP_LEFT
fi


# Add a little more for fun
if(($Y_OFFSET > 5)); then
  Y_OFFSET=$((Y_OFFSET+ADDITIONAL))
fi
if(($X_OFFSET > 5)); then
  X_OFFSET=$((X_OFFSET+ADDITIONAL))
fi

FINAL_H=$((ORIGINAL_H - Y_OFFSET * 2))
FINAL_W=$((ORIGINAL_W - X_OFFSET * 2))
CROP=$FINAL_W"x"$FINAL_H"+"$X_OFFSET"+"$Y_OFFSET

convert $FILENAME -crop $CROP -quality 100 $TARGET