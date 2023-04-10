#!/bin/bash
missile_count=100 # боекомплект ракет

#-----------------------------------------------------------------------------
config=$(grep -e "zrdn_1" vko_config)
R=$(echo $config | cut -d ',' -f 2)
x_center=$(echo $config | cut -d ',' -f 3)
y_center=$(echo $config | cut -d ',' -f 4)

function target_in_sector() {
	x_target=$1
	y_target=$2
	x_delt=$((x_center - x_target))
	y_delt=$((y_center - y_target))
	r_target=$((x_delt ** 2 + y_delt ** 2))
	if (($r_target < $((R ** 2)))); then
		return 0
	else
		return 1
	fi
}

function missile_launch() { # передается id цели
	target_id=$1
	echo "Произвиден пуск ракеты по цели ID:$target_id"
	#missile_count= $(( $missile_count - 1 ))
	echo "В боекомплекте осталось ракет:$missile_count"
	touch /tmp/GenTargets/Destroy/$target_id
	echo "$target_id" >>attacked_targets_zrdn_1
}

rm -rf current_target_zrdn_1 current_targets_spd_zrdn_1 misses_target_zrdn_1
rm -rf current_target_temp_zrdn_1 attacked_targets_zrdn_1 attacked_targets_old_zrdn_1

touch current_targets_spd_zrdn_1
touch current_target_zrdn_1
touch current_target_temp_zrdn_1
touch attacked_targets_zrdn_1
touch attacked_targets_old_zrdn_1
counter=0

sleep 2
while true; do
	# обработка новой пачки координат целей

	ls -t /tmp/GenTargets/Targets | head -n 30 >files

	if ! diff files files_old >/dev/null; then
	


		files=$(cat files)
		cp current_target_zrdn_1 current_target_temp_zrdn_1

		for file in $files; do

			target=$(echo "$file" | tail -c -7)
			contents=$(cat "/tmp/GenTargets/Targets/$file")
			X=$(echo "$contents" | grep -Eo '[0-9]+' | sed -n '1p')
			Y=$(echo "$contents" | grep -Eo '[0-9]+' | sed -n '2p')
			if target_in_sector $X $Y; then
				if grep -q "$target" current_target_zrdn_1; then # проверка была ли обнаружена эта цель ранее
					# обработка случая второй засечки и определение скорости
					# заносим скорость если скорости этой ракеты нет или координаты не отличаются
					if ! grep -q "$target" current_targets_spd_zrdn_1; then

						# ---------------------------рассчет скорости --------------------------------------
						X_old=$(cat current_target_temp_zrdn_1 | grep -e "$target" | cut -d ',' -f 2)
						Y_old=$(cat current_target_temp_zrdn_1 | grep -e "$target" | cut -d ',' -f 3)
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

							echo "$target,$type_target" >>current_targets_spd_zrdn_1
							
							#      Пуск ракет на уничтожение
							if [ "$type_target" == "Самолет" ] || [ "$type_target" == "Крылатая ракета" ]; then
								# первый пуск
								missile_launch $target
							fi

						fi
					fi


					sed -i "/$target/d" current_target_temp_zrdn_1
				else
					echo -e "\n\033[31mОбнаружена цель ID:$target с координатами x=$X, y=$Y\033[0m"
					echo "$target,$X,$Y" >>current_target_zrdn_1
				fi
			fi

		done

		#----------------------обработка уничтоженных и пропавших с радара целей---------------------------------------------
		for dead_target in $(cat current_target_temp_zrdn_1); do
		
			dead_target_id=$(echo $dead_target | cut -d ',' -f 1)
			if grep -q "$dead_target_id" attacked_targets_zrdn_1; then
				echo -e "\nЦель ID: $dead_target_id уничтожена"
				sed -i "/$dead_target_id/d" attacked_targets_zrdn_1
				sed -i "/$dead_target_id/d" attacked_targets_old_zrdn_1

			else
				echo -e "\nЦель ID: $dead_target_id пропала с радара"
			fi
			sed -i "/$dead_target/d" current_target_zrdn_1
		done

		#------------------------------------------------------------------------------------------
		# обработка промахов


		if [ $counter == 2 ]; then
			for mis in $(cat attacked_targets_old_zrdn_1 | sort  | uniq);	do
				echo "промах по цели ID: $mis"
				missile_launch $mis
			done
			cp attacked_targets_zrdn_1 attacked_targets_old_zrdn_1
			counter=0
		fi
		counter=$(( counter + 1 ))
	fi
	ls -t /tmp/GenTargets/Targets | head -n 30 >files_old
	sleep 0.4

done
