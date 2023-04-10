#!/bin/bash

rm -rf logs/logs_file
touch logs/logs_file

while true; do
	receive_path="messages/KP_VKO"
	mess_file=$(ls -t "$receive_path" | tail -1)
	cat "$receive_path/$mess_file" >>logs/logs_file
	rm -rf "$receive_path/$mess_file"
	sleep 1
done
