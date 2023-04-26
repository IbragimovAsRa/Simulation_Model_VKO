#!/bin/bash
# Пример уменьшения значения переменной на 1

function aaa() {
    echo "sdsds"
    return 0
}



if [ -s "docum" ];  then
    for var in $(cat docum); do 
        if [ $var == "3" ]; then
            break
        fi
        echo $var
    done
fi