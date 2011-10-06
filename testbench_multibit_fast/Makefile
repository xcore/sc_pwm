all: bin/simchecker

test: bin/simchecker
	bin/simchecker "$(TFLAG) ../app_pwm_multibit_fast_demo/bin/Release/app_pwm_multibit_fast_demo.xe"

bin/simchecker: src/simchecker.c
	if [ ! -d bin ]; then mkdir bin; fi
	c++ -o bin/simchecker -m32 -I $(installpath)/include src/simchecker.c $(installpath)/lib/libxsidevice.so 

clean:
	rm -rf bin
