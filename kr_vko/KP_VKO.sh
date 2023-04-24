#!/bin/bash

# 1) проверить детектор направления
# 2) начать сборку
# 3) проверить детектор роботоспособности

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
    echo "request of status" | tee 
    "messages/zrdn_1/ping_file"
    "messages/zrdn_2/ping_file"
    "messages/zrdn_3/ping_file"
    "messages/RLS_1/ping_file"
    "messages/RLS_2/ping_file"
    "messages/RLS_3/ping_file"
    "messages/SPRO/ping_file"
    > /dev/null
}

function check_status_mes() {
    local system_elem;
    if grep -e "status" -f "$receive_path/$mess_file" > tmp_state;  then
        system_elem=$(cat tmp_state | cut -d ',' -f 2)
		sed -i "/$system_elem/d" tmp_all_states
    fi

}

function check_status_vko_elems() {
    local check_time=8
    check_status_mes
    local diff=$(( $(date +%s) - $timer ))
    if [ $diff > $check_time ]; then
        if [[ -s "tmp_all_states" ]]; then
            for vko_elem in $(cat tmp_all_states); do
                if ! grep -e "$vko_elem" out_of_vko_elem > /dev/null; then
                    make_log "$(date +"%y-%m-%d %H:%M:%S")" "$vko_elem" "Роботоспособность системы нарушена" "nan"
                    echo "$vko_elem" >> out_of_vko_elem
                fi
            done
        fi
    fi
    echo -e "zrdn_1\n"
    send_ping
}

# ----------------------------------------------------------------
# ------ Инициализация -------------------------------------------
rm -rf logs/logs_file tmp_all_states out_of_vko_elem
touch logs/logs_file # ЖУРНАЛ
receive_path="messages/KP_VKO"
rm -rf $receive_path/*
init_data_base
sleep 2
timer=$(date +%s)
# ----------------------------------------------------------------

while true; do
    mess_file="$(ls -t "$receive_path" | tail -1)"
    if [ -n "$mess_file" ];   then
        Time=$(cat $receive_path/$mess_file | cut -d ',' -f 1)
        SystemElem=$(cat $receive_path/$mess_file | cut -d ',' -f 2)
        Info=$(cat $receive_path/$mess_file | cut -d ',' -f 3)
        TargetId=$(cat $receive_path/$mess_file | cut -d ',' -f 4)
        make_log "$Time" "$SystemElem" "$Info" "$TargetId"
        rm  -rf "$receive_path/$mess_file"       
    fi
    #check_status_vko_elems
    mess_file=""
	sleep 0.05
done
