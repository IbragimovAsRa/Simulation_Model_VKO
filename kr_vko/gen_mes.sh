#!/bin/bash

# Модуль дописан (ПРОТЕСТИРОВАТЬ)

config=$(grep -e "SPRO" vko_config)
R=$(echo $config | cut -d ',' -f 2)
x_center_spro=$(echo $config | cut -d ',' -f 3)
y_center_spro=$(echo $config | cut -d ',' -f 4)
#				 Модуль для определения направления
#----------------------------------------------------------------

function detect_target_route () { # на вход поступает 4
# аргумента (координаты x and y цели, и 
# покоординатные скорости Vx and Vy)
	x=$1
	y=$2
    Vx=$3
    Vy=$4
    X=$x_center_spro
    Y=$y_center_spro

    # определение уравненияя прямой
    k=$(echo "scale=10; $Vy/$Vx" | bc -l) 
    b=$(echo "scale=10;$y - $k * $x" | bc -l )
    D=$( echo "scale=10; (2*$k*($b-$Y) - 2*$X)^2 - 4*(1+ $k^2)*($X^2 + ($b - $Y)^2 - $R^2)" | bc -l)
    echo "D=$D"
    if (( $(echo "$D > 0" | bc -l) )); then # первый фильтр
        # второй фильтр на сближение или отдоление
        l_1=$(echo "sqrt( ($Y-$)^2 + ($X-$X)^2  )" | bc -l)
        l_2=$(echo "sqrt( ($Y-$y+$Vy)^2 + ($X-$X+$Vx)^2  )" | bc -l)

        if (( echo "$l2 < $l1" ));  then
            return 0
        else
            return 1
        fi

    else 
        return 1
    fi


}
#----------------------------------------------------------------


echo "result= $(detect_target_route -4 -4 2 2)"

if detect_target_route 4 4 -2 -2;   then
    echo "Цель ID:xxxxxx движется в направлении СПРО"
else 
    echo "Цель ID:xxxxxx движется НЕ в направлении СПРО"
fi

