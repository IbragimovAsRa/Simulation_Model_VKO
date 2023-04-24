run:	run.sh
	./run.sh 
format:	script.sh
	shfmt -l -w *.sh 
check:	script.sh
	shellcheck *.sh 
stop:	
	killall -9 xterm run.sh zrdn* 
	killall -9 KP_VKO.sh
clean:	
	rm -rf current* attacke*  log*


show_log_db:
	sqlite3 -column -header db/log.db "select * from log;"
show_log_file:
	cat logs/logs_file