#!/bin/bash

# 1) проверить детектор направления
# 2) начать сборку
# 3) проверить детектор роботоспособности


# для кодировки и декодировки используется симетричное шифрование OpenSSL



#-----------------------------------------------
#             Модуль для шифровки и декодирование
function send_encoded_message() {
    local mes=$1
    local path=$2
    echo "$mes" | openssl enc -aes-256-cbc -salt -pass file:temp/key.txt -out $path 2> /dev/null
}

function decrypt_encoded_message() {
    local path=$1
    openssl enc -d -aes-256-cbc -salt -pass file:temp/key.txt -in $path 2> /dev/null
}
# -----------------------------------------------
function init_data_base() {
    rm -rf db/log.db
    local transaction="DROP TABLE IF EXISTS  log;
                        CREATE TABLE log
                        (   
                            Id INTEGER PRIMARY KEY AUTOINCREMENT,
                            Time TEXT,
                            SystemElem TEXT,
                            Info TEXT,
                            TargetId TEXT
                        );"
    sqlite3 db/log.db "$transaction"
    sqlite3 db/log.db ".mode table"
}

function insert_to_database() {
    local Time=$1
    local SystemElem=$2
    local Info=$3
    local TargetId=$4
    local transaction="INSERT INTO log (Time,SystemElem,Info,TargetId) 
                 VALUES ('"$Time"','"$SystemElem"','"$Info"','"$TargetId"');"
    sqlite3 db/log.db "$transaction"
}

function make_log() {
    local Time=$1
    local SystemElem=$2
    local Info=$3
    local TargetId=$4
    insert_to_database "$Time" "$SystemElem" "$Info" "$TargetId"
    echo  "$(date -d "$Time" +%d.%m\ %H:%M:%S) "$SystemElem": $Info, ID: $TargetId" >> logs/logs_file
}

#           Модуль для проверки роботоспособности элементов ВКО (передатчик)
# ----------------------------------------------------------------
# формат файла status,zrdn_1,ok

function send_ping() {
    send_encoded_message "request of status"  "messages/zrdn_1/ping_file"
    send_encoded_message "request of status"  "messages/zrdn_2/ping_file"
    send_encoded_message "request of status"  "messages/zrdn_3/ping_file"
    send_encoded_message "request of status"  "messages/RLS_1/ping_file"
    send_encoded_message "request of status"  "messages/RLS_2/ping_file"
    send_encoded_message "request of status"  "messages/RLS_3/ping_file"
    send_encoded_message "request of status"  "messages/SPRO/ping_file"
}

function check_status_mes() {
    local system_elem;
    local message=$(decrypt_encoded_message "$receive_path/$mess_file")
    echo "$message" | grep -e "status" > tmp_state
    system_elem=$(cat tmp_state | cut -d ',' -f 2)
	sed -i "/$system_elem/d" tmp_all_states
}

function check_status_vko_elems() {
    local check_time=8
    local diff=$(( $(date +%s) - $timer ))
    if [ $diff -gt $check_time ]; then
        if [[ -s "tmp_all_states" ]]; then
            for vko_elem in $(cat tmp_all_states); do
                if ! grep -e "$vko_elem" out_of_vko_elem > /dev/null; then
                    make_log "$(date +"%y-%m-%d %H:%M:%S")" "$vko_elem" "Роботоспособность системы нарушена" "nan"
                    echo "$vko_elem" >> out_of_vko_elem
                fi
            done
        fi
        echo -e "zrdn_1\nzrdn_2\nzrdn_3\nRLS_1\nRLS_2\nRLS_3\nSPRO" > tmp_all_states
        send_ping
        timer=$(date +%s)
    fi
}

# ----------------------------------------------------------------
# ------ Инициализация -------------------------------------------

rm -rf logs/logs_file messages/KP_VKO/*
touch logs/logs_file # ЖУРНАЛ
touch tmp_all_states out_of_vko_elem
receive_path="messages/KP_VKO"
init_data_base
sleep 2
timer=$(date +%s)
# ----------------------------------------------------------------

while true; do
    check_status_vko_elems
    mess_file="$(ls -t "$receive_path" | tail -1)"
    if [ -n "$mess_file" ];   then
        message=$(decrypt_encoded_message "$receive_path/$mess_file")
        if echo "$message" | grep -e "status" > /dev/null;  then
            check_status_mes
        else
            Time=$(echo "$message" | cut -d ',' -f 1)
            SystemElem=$(echo "$message" | cut -d ',' -f 2)
            Info=$(echo "$message" | cut -d ',' -f 3)
            TargetId=$(echo "$message" | cut -d ',' -f 4)
            make_log "$Time" "$SystemElem" "$Info" "$TargetId"
        fi
        rm  -rf "$receive_path/$mess_file"       
    fi
    mess_file=""
    
	sleep 0.05
done
