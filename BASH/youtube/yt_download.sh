#!/bin/bash

cmd="yt-dlp -x --audio-format mp3"
file="list.txt"
name="Pedro"
dir="$name"_mp3

if (( $(ls | grep $dir | wc -w) == 0 )) ; then
    mkdir $dir
else
    echo Dir already existing
fi

completeSize=0
links=$(cat $file)
sounds=0

for i in $links
do
    $cmd $i
    sound=$(ls *.mp3)
    sound="${sound/.mp3/ }"
    echo En train de copier $sound
    mv *.mp3 $dir
    echo ...
    echo $sound copied
    #size=$(ls -l *.mp3 | awk '{print $5}')
    #((completesize+=size))
    #echo Size of the sound : $size Bits 
    ((sounds++))
done

#echo Complete size : $completeSize
#size=$(ls -l $dir | awk '{print $5}')

echo /////////////////////
    echo List saved in $dir...
echo Nb of sounds opied            : $sounds
#echo Original size of the download : $completeSize Mbit
