#!/bin/bash -l

# Модуль рассчета попадания цели в сектор
#--------------------------------------------------------------------------
config=$(grep -e "RLS_3" vko_config)
R=$(echo $config | cut -d ',' -f 2)
x_center=$(echo $config | cut -d ',' -f 3)
y_center=$(echo $config | cut -d ',' -f 4)
a=$(echo $config | cut -d ',' -f 5)
angle_sector=$(echo $config | cut -d ',' -f 6)

function target_in_sector() { # на вход поступают координаты цели
	x_target=$1
	y_target=$2
	x_delt=$((x_target - x_center))
	y_delt=$((y_target - y_center))
	r_target=$((x_delt ** 2 + y_delt ** 2))
	if (($r_target < $((R ** 2)))); then # первый фильтр (по радиусу)
		k=$(echo "($y_delt)/($x_delt)" | bc -l)
		target_angle_rad=$(echo "scale=10; a( $y_delt / $x_delt )" | bc -l)
		target_angle_degr=$(echo "scale=0; $target_angle_rad * 180 / 3.14159" | bc -l)
		if ((($x_delt < 0) && ($y_delt > 0))); then
			target_angle_degr=$((target_angle_degr + 180))
		elif ((($x_delt < 0) && (($y_delt < 0)))); then
			target_angle_degr=$((target_angle_degr + 180))
		elif ((($x_delt > 0) && (($y_delt < 0)))); then
			target_angle_degr=$((target_angle_degr + 360))
		fi
		left_limit=$((-$angle_sector / 2 + $a))
		right_limit=$(($angle_sector / 2 + $a))
		if ((($((target_angle_degr - 360)) > $left_limit) && ($((target_angle_degr - 360)) < $right_limit))); then
			return 0
		elif ((($target_angle_degr > $left_limit) && ($target_angle_degr < $right_limit))); then
			return 0
		elif ((($((target_angle_degr + 360)) > $left_limit) && ($((target_angle_degr + 360)) < $right_limit))); then
			return 0
		else
			return 1
		fi
	else
		return 1
	fi
}
#--------------------------------------------------------------------------

rm -rf current_target_RLS_3 current_targets_spd_RLS_3
rm -rf current_target_temp_RLS_3

touch current_targets_spd_RLS_3
touch current_target_RLS_3
touch current_target_temp_RLS_3

sleep 1.2
while true; do
	# обработка новой пачки координат целей
	cp current_target_RLS_3 current_target_temp_RLS_3
	files=$(ls -t /tmp/GenTargets/Targets | head -n 30)

	for file in $files; do

		target=$(echo "$file" | tail -c -7)
		contents=$(cat "/tmp/GenTargets/Targets/$file")
		X=$(echo "$contents" | grep -Eo '[0-9]+' | sed -n '1p')
		Y=$(echo "$contents" | grep -Eo '[0-9]+' | sed -n '2p')
		if target_in_sector $X $Y; then
			if grep -q "$target" current_target_RLS_3; then         # проверка была ли обнаружена эта цель ранее
				if ! grep -q "$target" current_targets_spd_RLS_3; then # проверка была ли скорость уже рассчитана

					# ---------------------------рассчет скорости --------------------------------------
					X_old=$(cat current_target_temp_RLS_3 | grep -e "$target" | cut -d ',' -f 2)
					Y_old=$(cat current_target_temp_RLS_3 | grep -e "$target" | cut -d ',' -f 3)
					X_delt=$((X - X_old))
					Y_delt=$((Y - Y_old))

					if ((($Y_delt != 0) && $X_delt != 0)); then # проверка на случай поступления старых координат
						spd=$(echo "sqrt($(((X_delt ** 2) + (Y_delt ** 2))))" | bc -l)

						if (($(echo "$spd < 10000" | bc -l) && $(echo "$spd > 8000" | bc -l))); then
							type_target="Боевой блок баллистической ракеты"
						elif (($(echo "$spd < 1000" | bc -l) && $(echo "$spd > 250" | bc -l))); then
							type_target="Крылатая ракета"
						elif (($(echo "$spd < 250" | bc -l) && $(echo "$spd > 50" | bc -l))); then
							type_target="Самолет"
						else
							type_target="Неопознанный обьект"
						fi

						int_spd=$(echo $spd | awk '{print int($1)}')
						echo -e "\nИнформация по цели ID: $target\n - Тип: $type_target\n - Скорость: Vx = $X_delt м/с, Vy = $Y_delt м/с, Vabs = $int_spd м/с\n"
						# -----------------------------------------------------------------------------------

						echo "$target" >>current_targets_spd_RLS_3

					fi
				fi
				sed -i "/$target/d" current_target_temp_RLS_3
			else
				echo -e "\n\033[31mОбнаружена цель ID:$target с координатами x=$X, y=$Y\033[0m"
				echo "$target,$X,$Y" >>current_target_RLS_3
			fi
		fi
	done

	#----------------------обработка мертвых целей---------------------------------------------
	for dead_target in $(cat current_target_temp_RLS_3); do
		dead_target_id=$(echo $dead_target | cut -d ',' -f 1)
		echo -e "\nЦель ID: $dead_target_id пропала с радара"
		sed -i "/$dead_target/d" current_target_RLS_3
	done
	#------------------------------------------------------------------------------------------
	sleep 0.4
done
