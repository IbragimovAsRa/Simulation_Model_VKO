#!/bin/bash


while true; do
count=$(ls  /tmp/GenTargets/Targets | wc -l)
echo "текущее количество файлов = $count"
sleep 1

done
