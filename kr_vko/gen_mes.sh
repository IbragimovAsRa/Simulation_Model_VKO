#!/bin/bash

counter=0



while true;	do

	counter=$(( counter + 1 ))
	if [ $counter == 3 ]; then
		echo "$counter"	
		counter=0


	fi

	

	sleep 2
done
