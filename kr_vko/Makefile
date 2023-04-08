run:	run.sh
	./run.sh 
format:	script.sh
	shfmt -l -w *.sh 
check:	script.sh
	shellcheck *.sh 
stop:	
	killall -9 xterm run.sh zrdn* 
clean:	
	rm -rf current*
