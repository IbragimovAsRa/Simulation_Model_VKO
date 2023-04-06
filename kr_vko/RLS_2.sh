#!/bin/bash -l


					# Модуль рассчета попадания цели в сектор
#--------------------------------------------------------------------------
config=$(grep -e "RLS_1" vko_config)
R=$(echo $config | cut -d ',' -f 2)
x_center=$(echo $config | cut -d ',' -f 3)
y_center=$(echo $config | cut -d ',' -f 4)
a=$(echo $config | cut -d ',' -f 5)
angle_sector=$(echo $config | cut -d ',' -f 6)


function tangens() { # угол в градусах
	angle=$1
	angle_r=$(echo "scale=10; pi=4*a(1); $angle*(pi/180)" | bc -l)
	tan=$(echo "scale=10;s($angle_r) / c($angle_r)" | bc -l)
	echo $tan
}

function target_in_sector() { # на вход поступают координаты цели
	x_target=$1
	y_target=$2
	echo $x_target
	echo $y_target
	x_delt=$((x_target - x_center))
	y_delt=$((y_target - y_center))
	r_target=$((x_delt ** 2 + y_delt ** 2))
	if (($r_target < $((R ** 2)))); then # первый фильтр (по радиусу)
		k=$(echo  "($y_delt)/($x_delt)" | bc -l )
		target_angle_rad=$(echo "scale=10; a( $y_delt / $x_delt )" | bc -l)
		target_angle_degr=$(echo "scale=0; $target_angle_rad * 180 / 3.14159" | bc -l)
		if (( ($x_delt < 0) && ($y_delt > 0))); then
			target_angle_degr=$((target_angle_degr + 180))
		elif (( ($x_delt < 0) && (($y_delt < 0))  )); then
			target_angle_degr=$((target_angle_degr + 180))
		elif (( ($x_delt > 0) && (($y_delt < 0))  )); then
			target_angle_degr=$((target_angle_degr + 360))
		fi
		left_limit=$((-$angle_sector/2 + $a))
		right_limit=$(($angle_sector/2 + $a))		
		if ((   ($((target_angle_degr - 360)) > $left_limit) && ($((target_angle_degr - 360)) < $right_limit)    )); then
			echo "true"
		elif (( ($target_angle_degr > $left_limit) && ($target_angle_degr < $right_limit) )); then
			echo "true"
		elif (( ($((target_angle_degr + 360)) > $left_limit) && ($((target_angle_degr + 360)) < $right_limit) )); then
			echo "true"
		else
			echo "false"
		fi		
	else
		echo "false"
	fi
}
#--------------------------------------------------------------------------

target_in_sector  1 1 


