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

function target_in_sector() { # на вход поступают координаты цели
	local x_target=$1
	local y_target=$2
	local x_delt=$((x_target - x_center))
	local y_delt=$((y_target - y_center))
	local r_target=$((x_delt ** 2 + y_delt ** 2))
	if (($r_target < $((R ** 2)))); then # первый фильтр (по радиусу)
		local k=$(echo "($y_delt)/($x_delt)" | bc -l)
		local target_angle_rad=$(echo "scale=10; a( $y_delt / $x_delt )" | bc -l)
		local target_angle_degr=$(echo "scale=0; $target_angle_rad * 180 / 3.14159" | bc -l)
		if ((($x_delt < 0) && ($y_delt > 0))); then
			target_angle_degr=$((target_angle_degr + 180))
		elif ((($x_delt < 0) && (($y_delt < 0)))); then
			target_angle_degr=$((target_angle_degr + 180))
		elif ((($x_delt > 0) && (($y_delt < 0)))); then
			target_angle_degr=$((target_angle_degr + 360))
		fi
		local left_limit=$((-$angle_sector / 2 + $a))
		local right_limit=$(($angle_sector / 2 + $a))
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



#----------------------+
system_elem="RLS_1"   #|
#----------------------+ 
receive_path="messages/$system_elem"

config=$(grep -e "$system_elem" vko_config)
R=$(echo $config | cut -d ',' -f 2)
x_center=$(echo $config | cut -d ',' -f 3)
y_center=$(echo $config | cut -d ',' -f 4)
a=$(echo $config | cut -d ',' -f 5)
angle_sector=$(echo $config | cut -d ',' -f 6)

config_spro=$(grep -e "SPRO" vko_config)
R_spro=$(echo $config_spro | cut -d ',' -f 2)
x_center_spro=$(echo $config_spro | cut -d ',' -f 3)
y_center_spro=$(echo $config_spro | cut -d ',' -f 4)

touch temp/current_targets_spd_$system_elem
touch temp/current_target_$system_elem
touch temp/current_target_temp_$system_elem
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
                            if detect_target_route $X $Y $X_delt $Y_delt;   then
                                send_message KP_VKO "Цель движется в направлении СПРО,$target"
                                send_message SPRO "Цель движется в направлении СПРО,$target"
                            fi
							echo "$target,$type_target" >> temp/current_targets_spd_$system_elem
						fi
					fi
					sed -i "/$target/d" temp/current_target_temp_$system_elem
				else
					echo "$target,$X,$Y" >> temp/current_target_$system_elem
				fi
			fi

		done

		#----------------------обработка пропавших с радара целей---------------------------------------------
		for dead_target in $(cat temp/current_target_temp_$system_elem); do
			dead_target_id=$(echo $dead_target | cut -d ',' -f 1)
			send_message KP_VKO "Цель пропала с радара,$dead_target_id"
			sed -i "/$dead_target/d" temp/current_target_$system_elem
		done

    #--------------------------------------------------
    #           модуль приемника сообщений

    receiver_mess

    #--------------------------------------------------
	sleep 0.2

done