#!/bin/bash

rm -rf /tmp/GenTargets/Targets/*
rm -rf ./messages/KP_VKO/*
make clean
sleep 1

openssl rand -base64 32 > temp/key.txt
sleep 0.5

./zrdn_1.sh &
./zrdn_2.sh &
./zrdn_3.sh &
./RLS_1.sh &
./RLS_2.sh &
./RLS_3.sh &
./SPRO.sh &
./KP_VKO.sh &
./GenTargets.sh >/dev/null &
./stop.sh





















#xterm  -geometry 80x24-1920-1080 -e "./zrdn_1" &
#xterm -geometry 80x24-940-1080 -e "./zrdn_2" &
#xterm -geometry 80x24-450-1080 -e "./zrdn_3"

#./stop

#xterm -geometry 80x24-1920-1080 -e "./zrdn_1.sh > log2 " &
#xterm -geometry 80x24-940-1080 -e "./zrdn_2.sh 2>/dev/null" &
#xterm -geometry 80x24-450-1080 -e "./zrdn_3.sh 2>/dev/null" &
#xterm -geometry 80x24-1920-60 -e "./RLS_1.sh 2>/dev/null" &
#xterm -geometry 80x24-940-60 -e "./RLS_2.sh 2>/dev/null" &
#xterm -geometry 80x24-450-60 -e "./RLS_3.sh 2>/dev/null" &
#xterm -geometry 160x17-1920-420 -e "./GenTargets.sh > log1" &
