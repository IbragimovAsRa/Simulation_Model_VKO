run:	script.sh
	./script.sh

format:	script.sh
	shfmt -l -w *.sh 

check:	script.sh
	shellcheck *.sh 
	
clean:	
	rm -rf current_target*
