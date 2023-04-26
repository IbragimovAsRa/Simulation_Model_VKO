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
	echo "$target_id" >> temp/attacked_targets_zrdn_1
    echo "current bk = $bk"
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
        if ! grep -e "$target" temp/targets_awaiting_attack_zrdn_1; then
            echo "$target" >> temp/targets_awaiting_attack_zrdn_1
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
        bk=$((bk + 40))
        send_message KP_VKO "Боекомплект пополнен,nan"
        bk_status=1
    fi
} 

# +-----------------------------------------------------------------------------+
# |                 Определение направления по отношению к СПРО                 |
# +-----------------------------------------------------------------------------+
function detect_target_route () { 
	local x=$1 
	local y=$2
    local Vx=$3
    local Vy=$4
    local X=$x_center_spro
    local Y=$y_center_spro

   # Определение уравненияя прямой
    local k=$(echo "scale=6; ($Vy)/($Vx)" | bc -l) 
    local b=$(echo "scale=6;($y) - ($k) * ($x)" | bc -l )
    local D=$(echo "scale=6; (2*($k)*(($b)-($Y)) - 2*($X))^2 - 4*(1+ ($k)^2)*(($X)^2 + (($b) - ($Y))^2 - ($R_spro)^2)" | bc -l)
    local sign_d=$(echo "$D > 0" | bc -l)
    if  [ $sign_d -eq 1 ]; then
        local l_1=$(echo "sqrt( (($Y)-($y))^2 + (($X)-($x))^2  )" | bc -l)
        local l_2=$(echo "sqrt( (($Y)-(($y)+($Vy)))^2 + (($X)-(($x)+($Vx)))^2  )" | bc -l)
        local comp_l=$(echo "$l_2 < $l_1" | bc -l)
        if  [ $comp_l -eq 1 ]; then
            return 0
        else
            return 1
        fi
    else
        return 1 # дескриминант меньше нуля    
    fi
}

# +-----------------------------------------------------------------------------+
# |                          Начальная инициализация                            |
# +-----------------------------------------------------------------------------+



counter=0
bk_status=1 # 1 - в бк есть ракеты, 0 - бк пуст
bk_time=$(grep -e "bk_time" vko_config | cut -d ',' -f 2)
system_elem="zrdn_1"
receive_path="messages/$system_elem"

config=$(grep -e "zrdn_1" vko_config)
R=$(echo $config | cut -d ',' -f 2)
x_center=$(echo $config | cut -d ',' -f 3)
y_center=$(echo $config | cut -d ',' -f 4)
bk=$(echo $config | cut -d ',' -f 5) # боекомплект ракет


config_spro=$(grep -e "SPRO" vko_config)
R_spro=$(echo $config_spro | cut -d ',' -f 2)
x_center_spro=$(echo $config_spro | cut -d ',' -f 3)
y_center_spro=$(echo $config_spro | cut -d ',' -f 4)

timer=0

touch temp/current_targets_spd_zrdn_1
touch temp/current_target_zrdn_1
touch temp/current_target_temp_zrdn_1
touch temp/attacked_targets_zrdn_1
touch temp/attacked_targets_old_zrdn_1
touch temp/targets_awaiting_attack_zrdn_1
touch temp/files
touch temp/files_old

sleep 2

# +-----------------------------------------------------------------------------+
# |                           Основная программа                                |
# +-----------------------------------------------------------------------------+
while true; do
	# обработка новой пачки координат целей

	ls -t /tmp/GenTargets/Targets | head -n 30 > temp/files

	if ! diff temp/files temp/files_old >/dev/null; then
	

        cp temp/files temp/files_old
		files_var=$(cat temp/files)
		cp temp/current_target_zrdn_1 temp/current_target_temp_zrdn_1

		for file in $files_var; do
            
			target=$(echo "$file" | tail -c -7)
			contents=$(cat "/tmp/GenTargets/Targets/$file")
			X=$(echo "$contents" | grep -Eo '[0-9]+' | sed -n '1p')
			Y=$(echo "$contents" | grep -Eo '[0-9]+' | sed -n '2p')
			if target_in_sector $X $Y; then
				if grep -q "$target" temp/current_target_zrdn_1; then # проверка была ли обнаружена эта цель ранее
					# обработка случая второй засечки и определение скорости
					# заносим скорость если скорости этой ракеты нет или координаты не отличаются
					if ! grep -q "$target" temp/current_targets_spd_zrdn_1; then

						# ---------------------------рассчет скорости --------------------------------------
						X_old=$(cat temp/current_target_temp_zrdn_1 | grep -e "$target" | cut -d ',' -f 2)
						Y_old=$(cat temp/current_target_temp_zrdn_1 | grep -e "$target" | cut -d ',' -f 3)
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

							echo "$target,$type_target" >> temp/current_targets_spd_zrdn_1
							
							#      Пуск ракет на уничтожение
							if [ "$type_target" == "Самолет" ] || [ "$type_target" == "Крылатая ракета" ]; then
								# первый пуск
                                atack_target $target
							fi
						fi
					fi
					sed -i "/$target/d" temp/current_target_temp_zrdn_1
				else
					echo "$target,$X,$Y" >> temp/current_target_zrdn_1
				fi
			fi

		done

		#----------------------обработка уничтоженных и пропавших с радара целей---------------------------------------------
		for dead_target in $(cat temp/current_target_temp_zrdn_1); do
		
			dead_target_id=$(echo $dead_target | cut -d ',' -f 1)
			if grep -q "$dead_target_id" temp/attacked_targets_zrdn_1; then
				send_message KP_VKO "Цель уничтожена,$dead_target_id"
				sed -i "/$dead_target_id/d" temp/attacked_targets_zrdn_1
				sed -i "/$dead_target_id/d" temp/attacked_targets_old_zrdn_1

			else
				send_message KP_VKO "Цель пропала с радара,$dead_target_id"
			fi
			sed -i "/$dead_target/d" temp/current_target_zrdn_1
		done

		#------------------------------------------------------------------------------------------
		# обработка промахов


		if [ $counter == 3 ]; then
			for mis in $(cat temp/attacked_targets_old_zrdn_1 | sort  | uniq);	do
				send_message KP_VKO "Промах по цели,$mis"
				missile_launch $mis
			done
			cp temp/attacked_targets_zrdn_1 temp/attacked_targets_old_zrdn_1
			counter=0
		fi
		counter=$(( counter + 1 ))

        # обработка неатокованных целей из-за отсутствия БК
        if [ $bk > 0 ] && [ -s "temp/targets_awaiting_attack_zrdn_1" ]; then
            for var in $(cat temp/targets_awaiting_attack_zrdn_1); do
                if ! atack_target $var; then
                    break
                else
                    sed -i "/$var/d" temp/targets_awaiting_attack_zrdn_1
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