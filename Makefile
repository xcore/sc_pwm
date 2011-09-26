# BUILD_SUBDIRS = plugin_pwm app_pwm_singlebit_port_demo app_pwm_singlebit_port_test app_pwm_multibit_port_demo app_pwm_multibit_port_test
# TEST_SUBDIRS = app_pwm_singlebit_port_test app_pwm_multibit_port_test

BUILD_SUBDIRS = app_pwm_multibit_fast_demo testbench_multibit_fast \
                app_pwm_singlebit_simple_demo testbench_singlebit_simple
TEST_SUBDIRS= testbench_multibit_fast

%.all:
	cd $* && xmake all

%.clean:
	cd $* && xmake clean

%.test:
	cd $* && xmake test

all: $(foreach x, $(BUILD_SUBDIRS), $x.all)
clean: $(foreach x, $(BUILD_SUBDIRS), $x.clean)
test: $(foreach x, $(TEST_SUBDIRS), $x.test)
