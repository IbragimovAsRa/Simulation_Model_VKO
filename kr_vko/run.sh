#!/bin/bash



#!/bin/bash


xterm  -geometry 80x24-1920-1080 -e "./GenTargets.sh" &
xterm  -geometry 80x24-940-1080  -e "./script.sh" &
./stop.sh

#xterm  -geometry 80x24-1920-1080 -e "./zrdn_1" &
#xterm -geometry 80x24-940-1080 -e "./zrdn_2" & 
#xterm -geometry 80x24-450-1080 -e "./zrdn_3" 

#./stop


