#!/bin/bash

#--------------functions----------------------

function count_commans() { # на вход поступает строка
	commas=$(tr -cd ',' <<< $1 | wc -c)
	echo $commas	
}


#---------------------------------------------

# ТЗ
# 1) выдавать сообщение о смерти цели 
# 2) разобраться со временем
# 3) вывести скорость и классифицировать обьект



rm -rf current_target current_targets_spd
rm -rf current_target_temp

touch current_targets_spd
touch current_target
touch current_target_temp

while true; do
	# обработка новой пачки координат целей
	cp current_target current_target_temp
	files=$(ls -t /tmp/GenTargets/Targets | head -n 30)
	
	for file in $files; do
		target=$(echo "$file" | tail -c -7)
		contents=$(cat "/tmp/GenTargets/Targets/$file")
		X=$(echo "$contents" | grep -Eo '[0-9]+' | sed -n '1p')
		Y=$(echo "$contents" | grep -Eo '[0-9]+' | sed -n '2p')
		if grep -q "$target" current_target; then
			# обработка случая второй засечки и определение скорости
			
			# заносим скорость если скорости этой ракеты нет или координаты не отличаются
			if [ "$(grep -e "$target" current_target)" = "$(grep -e "$target" current_target_temp)" ]; then
				if ! grep -q "$target" current_targets_spd; then
					
					# ---------------------------рассчет скорости --------------------------------------
					X_old=$(cat current_target_temp | grep -e "$target" | cut -d ',' -f 2)
					Y_old=$(cat current_target_temp | grep -e "$target" | cut -d ',' -f 3)
					
					X_delt=$((X - X_old))
					Y_delt=$((Y - Y_old))
										
					spd=$(echo "sqrt($(((X_delt ** 2) + (Y_delt ** 2))))" | bc -l)
					
					if [[ ($spd -lt 10000) && ($spd -gt 8000)  ]]; then
						type_target="Боевой блок баллистической ракеты"
					elif [[ ($spd -lt 1000) && ($spd -gt 250)  ]]; then
						type_target="Крылатая ракета"
					elif [[ ($spd -lt 250) && ($spd -gt 50)  ]];then
						type_target="Самолет"
					else
						type_target="Неопознанный обьект"
					fi
					
					
					echo -e "\nИнформация по цели ID: $target\n - Тип: $type_target\n - Скорость: Vx = $X_delt, Vy = $Y_delt, Vabs = $spd\n"
					# -----------------------------------------------------------------------------------
					
					
					echo "$target" >> current_targets_spd
				fi
			fi
			
			sed -i "/$target/d" current_target_temp
		else
			echo -e "\nОбнаружена цель ID:$target с координатами x=$X, y=$Y"
			echo "$target,$X,$Y" >> current_target
		fi
	done
	
	#обработка мертвых целей
	for dead_target in $(cat current_target_temp); do
		echo -e "\nЦель ID: $dead_target пропала с радара"
		sed -i "/$dead_target/d" current_target
	done
	sleep 0.5
done
