#!/bin/sh
#
# convert the note events in a MIDI file to a suitable thing for track7

echo "return {"
for i in "$@" ; do
    midicsv $i | grep Note_on_c | tr -d ' ' | cut -f1,2,5,6 -d, | tr ',' ' ' | while read track tstamp note vel; do
        printf '%d %d %d %d\n' $tstamp $track $note $vel
    done | sort -n | while read tstamp track note vel ; do
        printf '    {%d, %d, %d, %d},\n' $tstamp $track $note $vel
    done
done
echo "}"
