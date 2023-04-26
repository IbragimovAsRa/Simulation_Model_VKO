#!/bin/bash

# +-----------------------------------------------------------------------------+
# |                           Шифровка и декодирование                          |
# +-----------------------------------------------------------------------------+

function send_encoded_message() {
    local mes=$1
    local path=$2
    echo "$mes" | openssl enc -aes-256-cbc -salt -pass file:temp/key.txt -out $path 2> /dev/null
}

function decrypt_encoded_message() {
    local path=$1
    openssl enc -d -aes-256-cbc -salt -pass file:temp/key.txt -in $path 2> /dev/null
}

# +----------------------------------------------------------------------------+
# |                             Отправка сообщений                             |
# +----------------------------------------------------------------------------+

function gen_filename() {
	echo "$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 10)"
}

function send_message() {
	local receiver=$1
	local message=$2
	local filename=$(gen_filename)
	send_encoded_message "$(date +"%y-%m-%d %H:%M:%S"),$system_elem,$message" "./messages/$receiver/$filename"
}

# +-----------------------------------------------------------------------------+
# |                Определение нахождения цели в секторе обзора                 |
# +-----------------------------------------------------------------------------+

function target_in_sector() {
	local x_target=$1
	local y_target=$2
	local x_delt=$((x_center - x_target))
	local y_delt=$((y_center - y_target))
	local r_target=$((x_delt ** 2 + y_delt ** 2))
	if (($r_target < $((R ** 2)))); then
		return 0
	else
		return 1
	fi
}

# +-----------------------------------------------------------------------------+
# |                             Уничтожение цели                                |
# +-----------------------------------------------------------------------------+

function missile_launch() { # передается id цели
	local target_id=$1
	send_message KP_VKO "Произвиден пуск ракеты по цели,$target_id"
    bk=$((bk - 1))
	touch /tmp/GenTargets/Destroy/$target_id
	echo "$target_id" >> temp/attacked_targets_$system_elem
}

function atack_target() {
    local target=$1
    if [[ $bk -gt 0 ]];  then
        missile_launch $target
        bk_status=1
        return  0 # атака на цель совершена успешно
    else
        if [ $bk_status == 1 ]; then
            bk_status=0
            send_message KP_VKO "Боекомплект пуст,nan"
            timer=$(date +%s)
        fi
        if ! grep -e "$target" temp/targets_awaiting_attack_$system_elem; then
            echo "$target" >> temp/targets_awaiting_attack_$system_elem
        fi
        return 1 # цель не удалось атаковать
    fi
}

# +-----------------------------------------------------------------------------+
# |                            Прием сообщений от КП                            |
# +-----------------------------------------------------------------------------+
function receiver_mess() {
    local message
    local mess_file
    mess_file="$(ls -t "$receive_path" | tail -1)"
    if [ -n "$mess_file" ];   then
        message=$(decrypt_encoded_message "$receive_path/$mess_file")
        if [ "$message" == "request of status" ]; then
            send_message KP_VKO "status-OK"
        fi
        rm  -rf "$receive_path/$mess_file"       
    fi
    mess_file=""
}

# +-----------------------------------------------------------------------------+
# |                          Пополнение боекомплекта                            |
# +-----------------------------------------------------------------------------+
#  Пополнение БК
function replenishment_bk() {
    local diff
    diff=$(( $(date +%s) - $timer ))
    if  [ $bk_status == 0 ] && [ $diff -gt $bk_time ]; then
        bk=$((bk + bk_count))
        send_message KP_VKO "Боекомплект пополнен,nan"
        bk_status=1
    fi
} 

# +-----------------------------------------------------------------------------+
# |                          Начальная инициализация                            |
# +-----------------------------------------------------------------------------+



counter=0
bk_status=1 # 1 - в бк есть ракеты, 0 - бк пуст
bk_time=$(grep -e "bk_time" vko_config | cut -d ',' -f 2)
#----------------------+
system_elem="zrdn_2"  #|
#----------------------+ 
receive_path="messages/$system_elem"

config=$(grep -e "$system_elem" vko_config)
R=$(echo $config | cut -d ',' -f 2)
x_center=$(echo $config | cut -d ',' -f 3)
y_center=$(echo $config | cut -d ',' -f 4)
bk_count=$(echo $config | cut -d ',' -f 5) # боекомплект ракет

timer=0

touch temp/current_targets_spd_$system_elem
touch temp/current_target_$system_elem
touch temp/current_target_temp_$system_elem
touch temp/attacked_targets_$system_elem
touch temp/attacked_targets_old_$system_elem
touch temp/targets_awaiting_attack_$system_elem
touch temp/files_$system_elem
touch temp/files_old_$system_elem

sleep 2

# +-----------------------------------------------------------------------------+
# |                           Основная программа                                |
# +-----------------------------------------------------------------------------+
while true; do
	# обработка новой пачки координат целей

	ls -t /tmp/GenTargets/Targets | head -n 30 > temp/files_$system_elem

	if ! diff temp/files_$system_elem temp/files_old_$system_elem >/dev/null; then
	

        cp temp/files_$system_elem temp/files_old_$system_elem
		files_var=$(cat temp/files_$system_elem)
		cp temp/current_target_$system_elem temp/current_target_temp_$system_elem

		for file in $files_var; do
            
			target=$(echo "$file" | tail -c -7)
			contents=$(cat "/tmp/GenTargets/Targets/$file")
			X=$(echo "$contents" | grep -Eo '[0-9]+' | sed -n '1p')
			Y=$(echo "$contents" | grep -Eo '[0-9]+' | sed -n '2p')
			if target_in_sector $X $Y; then
				if grep -q "$target" temp/current_target_$system_elem; then # проверка была ли обнаружена эта цель ранее
					# обработка случая второй засечки и определение скорости
					# заносим скорость если скорости этой ракеты нет или координаты не отличаются
					if ! grep -q "$target" temp/current_targets_spd_$system_elem; then

						# ---------------------------рассчет скорости --------------------------------------
						X_old=$(cat temp/current_target_temp_$system_elem | grep -e "$target" | cut -d ',' -f 2)
						Y_old=$(cat temp/current_target_temp_$system_elem | grep -e "$target" | cut -d ',' -f 3)
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
							# отправка информации по цели на КП
							send_message KP_VKO "Обнаружена цель: $type_target,$target"

							echo "$target,$type_target" >> temp/current_targets_spd_$system_elem
							#      Пуск ракет на уничтожение
							if [ "$type_target" == "Самолет" ] || [ "$type_target" == "Крылатая ракета" ]; then
								# первый пуск
                                atack_target $target
							fi
						fi
					fi
					sed -i "/$target/d" temp/current_target_temp_$system_elem
				else
					echo "$target,$X,$Y" >> temp/current_target_$system_elem
				fi
			fi

		done

		#----------------------обработка уничтоженных и пропавших с радара целей---------------------------------------------
		for dead_target in $(cat temp/current_target_temp_$system_elem); do
		
			dead_target_id=$(echo $dead_target | cut -d ',' -f 1)
			if grep -q "$dead_target_id" temp/attacked_targets_$system_elem; then
				send_message KP_VKO "Цель уничтожена,$dead_target_id"
				sed -i "/$dead_target_id/d" temp/attacked_targets_$system_elem
				sed -i "/$dead_target_id/d" temp/attacked_targets_old_$system_elem

			else
				send_message KP_VKO "Цель пропала с радара,$dead_target_id"
			fi
			sed -i "/$dead_target/d" temp/current_target_$system_elem
		done

		#------------------------------------------------------------------------------------------
		# обработка промахов


		if [ $counter == 3 ]; then
			for mis in $(cat temp/attacked_targets_old_$system_elem | sort  | uniq);	do
				send_message KP_VKO "Промах по цели,$mis"
				missile_launch $mis
			done
			cp temp/attacked_targets_$system_elem temp/attacked_targets_old_$system_elem
			counter=0
		fi
		counter=$(( counter + 1 ))

        # обработка неатокованных целей из-за отсутствия БК
        if [ $bk > 0 ] && [ -s "temp/targets_awaiting_attack_$system_elem" ]; then
            for var in $(cat temp/targets_awaiting_attack_$system_elem); do
                if ! atack_target $var; then
                    break
                else
                    sed -i "/$var/d" temp/targets_awaiting_attack_$system_elem
                fi
            done
        fi

	fi
    #--------------------------------------------------
    #  пополнения БК
    replenishment_bk
    #--------------------------------------------------
    #           модуль приемника сообщений

    receiver_mess

    #--------------------------------------------------
	sleep 0.2

done