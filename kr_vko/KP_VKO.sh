#!/bin/bash

# БД каждый раз удаляется и создается заново
# Структура журнала и БД
# 'время' 'элемент системы' 'информация' 'id цели' 'координаты цели'
# 'время' 'элемент системы' 'работоспособность восстановлена'
# 07.06 11:09:59, RLS3 цель движется в направлении СПРО, id:090b79


# -----------------------------------------------





# -----------------------------------------------



rm -rf logs/logs_file
touch logs/logs_file # ЖУРНАЛ

while true; do
	receive_path="messages/KP_VKO"
	mess_file=$(ls -t "$receive_path" | tail -1)
	cat "$receive_path/$mess_file" >>logs/logs_file
	rm -rf "$receive_path/$mess_file"
	sleep 1
done
