#!/bin/bash

echo -e "\n\n   Запуск имитационной модели \n\n"

while [[ $comma != "q" ]]; do
	echo "   Для выхода - 'q' "
	read comma
done
killall run 2>/dev/null
killall xterm 2>/dev/null
killall zrdn_1.sh 2>/dev/null
killall GenTargets.sh 1>/dev/null  2>/dev/null
killall zrdn_2.sh 2>/dev/null
killall zrdn_3.sh 2>/dev/null
killall KP_VKO.sh 2>/dev/null

make clean
echo -e "\n\n  Done.. The simulation model has been\033[32m successfully completed\033[0m\n\n"
exit