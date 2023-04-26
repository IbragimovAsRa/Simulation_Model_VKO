#!/bin/bash
# Пример уменьшения значения переменной на 1

#!/bin/bash

# Задаем значения

X_delt=-3
Y_delt=-3
spd=$(echo "sqrt($(((X_delt ** 2) + (Y_delt ** 2))))" | bc -l)

echo "$spd"