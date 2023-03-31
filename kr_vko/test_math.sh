#!/bin/bash



spd=9032

					if [[ ($spd -lt 10000) && ($spd -gt 8000) ]]; then
						type_target="Боевой блок баллистической ракеты"
					elif [[ ($spd < 1000) && ($spd > 250) ]]; then
						type_target="Крылатая ракета"
					elif [[ ($spd < 250) && ($spd > 50) ]];then
						type_target="Самолет"
					else
						type_target="Неопознанный обьект"
					fi


echo $type_target
