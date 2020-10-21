#! /bin/bash

file=$1
dirname=$(dirname "$1")
basename=$(basename "$1")
filename=${basename%.*}

java -jar plantuml.jar "$1"
xdg-open "${filename}.png"

inotifywait -m -e create -e modify -e close_write "$dirname" |
while read filename eventlist eventfile
do
    java -jar plantuml.jar "$1"
done
