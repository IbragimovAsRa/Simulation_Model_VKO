#!/bin/bash

rm -rf /tmp/GenTargets/Targets/*
rm -rf ./messages/KP_VKO/*

sleep 1

#xterm -geometry 80x24-1920-1080 -e "./zrdn_1.sh > log2 " &
#xterm -geometry 80x24-940-1080 -e "./zrdn_2.sh 2>/dev/null" &
#xterm -geometry 80x24-450-1080 -e "./zrdn_3.sh 2>/dev/null" &
#xterm -geometry 80x24-1920-60 -e "./RLS_1.sh 2>/dev/null" &
#xterm -geometry 80x24-940-60 -e "./RLS_2.sh 2>/dev/null" &
#xterm -geometry 80x24-450-60 -e "./RLS_3.sh 2>/dev/null" &
#xterm -geometry 160x17-1920-420 -e "./GenTargets.sh > log1" &

./zrdn_1.sh 2>/dev/null &
./KP_VKO.sh  &
./GenTargets.sh >/dev/null &
./stop.sh

#xterm  -geometry 80x24-1920-1080 -e "./zrdn_1" &
#xterm -geometry 80x24-940-1080 -e "./zrdn_2" &
#xterm -geometry 80x24-450-1080 -e "./zrdn_3"

#./stop