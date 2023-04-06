#!/bin/bash




while [[ $comma != "q" ]]
do
    echo "press 'q' for quit (для выхода)"
    read comma
done
killall run  2>/dev/null
killall xterm  2>/dev/null

echo "Работа имитационной модели завершена успешно"
exit
