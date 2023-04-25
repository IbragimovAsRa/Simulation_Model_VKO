run:	run.sh
	./run.sh 
format:	script.sh
	shfmt -l -w *.sh 
check:	script.sh
	shellcheck *.sh 
stop:	
	killall -9 xterm run.sh zrdn* RLS* SPRO* KP_VKO.sh GenTargets.sh stop.sh 2> /dev/null
clean:	
	rm -rf current* attacke*   files files_old tmp_state tmp_all_states out_of_vko*  messages/KP_VKO/* 
	rm -rf messages/KP_VKO/* messages/zrdn*/* messages/RLS*/* messages/SPRO/* temp/* 
all_clean:
	rm -rf current* attacke*   files files_old tmp_state tmp_all_states out_of_vko*  messages/KP_VKO/* 
	rm -rf messages/KP_VKO/* messages/zrdn*/* messages/RLS*/* messages/SPRO/* temp/* db/* logs/*
show_log_db:
	sqlite3 -column -header db/log.db "select * from log;"
show_log_file:
	cat logs/logs_file


# Команды нарушения роботоспособности
destroy_zrdn_1:
	killall -9 zrdn_1.sh 2> /dev/null
destroy_zrdn_2:
	killall -9 zrdn_2.sh 2> /dev/null
destroy_zrdn_3:
	killall -9 zrdn_3.sh 2> /dev/null
destroy_RLS_1:
	killall -9 RLS_1.sh 2> /dev/null
destroy_RLS_2:
	killall -9 RLS_2.sh 2> /dev/null
destroy_RLS_3:
	killall -9 RLS_3.sh 2> /dev/null
destroy_SPRO:
	killall -9 SPRO.sh 2> /dev/null

# Команды востановления роботоспособности
recover_zrdn_1:
	./zrdn_1.sh
recover_zrdn_2:
	./zrdn_2.sh
recover_zrdn_3:
	./zrdn_3.sh
recover_RLS_1:
	./RLS_1.sh
recover_RLS_2:
	./RLS_2.sh
recover_RLS_3:
	./RLS_2.sh
recover_SPRO:
	./SPRO.sh