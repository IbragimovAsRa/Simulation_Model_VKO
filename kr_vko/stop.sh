#!/bin/bash

echo -e "\n\n   Запуск имитационной модели \n\n"

while [[ $comma != "q" ]]; do
	echo "   Для выхода - 'q' "
	read comma
done
killall run 2>/dev/null
killall xterm 2>/dev/null
rm -rf current*

echo -e "\n\n   Работа имитационной модели завершена\033[32m УСПЕШНО\033[0m\n\n"
exit
