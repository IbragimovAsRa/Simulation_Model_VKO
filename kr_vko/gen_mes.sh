#!/bin/bash

# Модуль дописан (ПРОТЕСТИРОВАТЬ)

config_spro=$(grep -e "SPRO" vko_config)
R_spro=$(echo $config_spro | cut -d ',' -f 2)
x_center_spro=$(echo $config_spro | cut -d ',' -f 3)
y_center_spro=$(echo $config_spro | cut -d ',' -f 4)
#				 Модуль для определения направления
#----------------------------------------------------------------

function detect_target_route () { 
	local x=$1 
	local y=$2
    local Vx=$3
    local Vy=$4
    local X=$x_center_spro
    local Y=$y_center_spro

   # Определение уравненияя прямой
    local k=$(echo "scale=10; ($Vy)/($Vx)" | bc -l) 
    local b=$(echo "scale=10;($y) - ($k) * ($x)" | bc -l )
    local D=$(echo "scale=10; (2*($k)*(($b)-($Y)) - 2*($X))^2 - 4*(1+ ($k)^2)*(($X)^2 + (($b) - ($Y))^2 - ($R_spro)^2)" | bc -l)
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
#----------------------------------------------------------------



if detect_target_route 1 1 -2 -2 ;   then
    echo "Цель ID:xxxxxx движется в направлении СПРО"
else 
    echo "Цель ID:xxxxxx движется НЕ в направлении СПРО"
fi

