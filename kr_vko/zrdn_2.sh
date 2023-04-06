#!/bin/bash

config=$(grep -e "zrdn_2" vko_config)
R=$(echo $config | cut -d ',' -f 2)
x_center=$(echo $config | cut -d ',' -f 3)
y_center=$(echo $config | cut -d ',' -f 4)

function target_in_sector() {
	x_target=$1
	y_target=$2
	echo $x_target
	echo $y_target
	x_delt=$((x_center - x_target))
	y_delt=$((y_center - y_target))

	r_target=$((x_delt ** 2 + y_delt ** 2))

	if (($r_target < $((R ** 2)))); then
		echo "true"
	else
		echo "false"
	fi
}
