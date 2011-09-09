test: bin/simchecker
	bin/simchecker "$(TFLAG) ../app_ethercat_test/bin/XK-1/app_ethercat_test.xe"

bin/simchecker: src/simchecker.c
	if [ ! -d bin ]; then mkdir bin; fi
	c++ -o bin/simchecker -std=c99 -m32 -I $(installpath)/include src/simchecker.c $(installpath)/lib/libxsidevice.so 
