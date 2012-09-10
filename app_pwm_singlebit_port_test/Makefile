# The TARGET variable determines what target system the application is 
# compiled for. It either refers to an XN file in the source directories
# or a valid argument for the --target option when compiling.

TARGET = XC-1A

# The APP_NAME variable determines the name of the final .xe file. It should
# not include the .xe postfix. If left blank the name will default to 
# the project name

APP_NAME =

# The flags passed to xcc when building the application
# You can also set the following to override flags for a particular language:
#
#    XCC_XC_FLAGS, XCC_C_FLAGS, XCC_ASM_FLAGS, XCC_CPP_FLAGS
#
# If the variable XCC_MAP_FLAGS is set it overrides the flags passed to 
# xcc for the final link (mapping) stage.

XCC_FLAGS = -g -O3 -DNUM_PORTS=$(NUM_PORTS)



# The USED_MODULES variable lists other module used by the application. 

USED_MODULES = module_pwm_singlebit_port

#=============================================================================

.PHONY : test time

EXECUTABLE=bin/XC-1A/app_pwm_singlebit_port_test.xe
#TIMINGSCRIPT=../module_pwm_singlebit_port/src/pwm.py
#TRACING=--trace-to trace.txt --vcd-tracing '-o trace.vcd -ports-detailed'

PWM_PLUGIN = ../plugin_pwm/bin/PWM.dll

#xsim $(TRACING) --plugin $(PWM_PLUGIN) '40' --plugin $(PWM_PLUGIN) '41' --plugin $(PWM_PLUGIN) '50' --plugin $(PWM_PLUGIN) '51' $(EXECUTABLE)
#xsim $(TRACING) --plugin $(PWM_PLUGIN) '40' --plugin  $(PWM_PLUGIN) '41' $(EXECUTABLE)
test:
ifeq ($(NUM_PORTS), 1)
	xsim $(TRACING) --plugin $(PWM_PLUGIN) '40' $(EXECUTABLE)
else
ifeq ($(NUM_PORTS), 2)
	xsim $(TRACING) --plugin $(PWM_PLUGIN) '40' --plugin $(PWM_PLUGIN) '41' $(EXECUTABLE)
else
ifeq ($(NUM_PORTS), 7)
	xsim $(TRACING) --plugin $(PWM_PLUGIN) '40' --plugin $(PWM_PLUGIN) '41' --plugin $(PWM_PLUGIN) '50' --plugin $(PWM_PLUGIN) '51' --plugin $(PWM_PLUGIN) '52' --plugin $(PWM_PLUGIN) '53' --plugin $(PWM_PLUGIN) '62' $(EXECUTABLE)
else
ifeq ($(NUM_PORTS), 8)
	xsim $(TRACING) --plugin $(PWM_PLUGIN) '40' --plugin $(PWM_PLUGIN) '41' --plugin $(PWM_PLUGIN) '50' --plugin $(PWM_PLUGIN) '51' --plugin $(PWM_PLUGIN) '52' --plugin $(PWM_PLUGIN) '53' --plugin $(PWM_PLUGIN) '62' --plugin $(PWM_PLUGIN) '63' $(EXECUTABLE)
else
ifeq ($(NUM_PORTS), 15)
	xsim $(TRACING) --plugin $(PWM_PLUGIN) '40' --plugin $(PWM_PLUGIN) '41' --plugin $(PWM_PLUGIN) '50' --plugin $(PWM_PLUGIN) '51' --plugin $(PWM_PLUGIN) '52' --plugin $(PWM_PLUGIN) '53' --plugin $(PWM_PLUGIN) '62' --plugin $(PWM_PLUGIN) '63' --plugin $(PWM_PLUGIN) '20' --plugin $(PWM_PLUGIN) '21' --plugin $(PWM_PLUGIN) '30' --plugin $(PWM_PLUGIN) '31' --plugin $(PWM_PLUGIN) '32' --plugin $(PWM_PLUGIN) '33' --plugin $(PWM_PLUGIN) '34' '35' $(EXECUTABLE)
else
ifeq ($(NUM_PORTS), 16)
	xsim $(TRACING) --plugin $(PWM_PLUGIN) '40' --plugin $(PWM_PLUGIN) '41' --plugin $(PWM_PLUGIN) '50' --plugin $(PWM_PLUGIN) '51' --plugin $(PWM_PLUGIN) '52' --plugin $(PWM_PLUGIN) '53' --plugin $(PWM_PLUGIN) '62' --plugin $(PWM_PLUGIN) '63' --plugin $(PWM_PLUGIN) '20' --plugin $(PWM_PLUGIN) '21' --plugin $(PWM_PLUGIN) '30' --plugin $(PWM_PLUGIN) '31' --plugin $(PWM_PLUGIN) '32' --plugin $(PWM_PLUGIN) '33' --plugin $(PWM_PLUGIN) '34' --plugin $(PWM_PLUGIN) '35' $(EXECUTABLE)
else
	$(error "Invalid port number")
endif
endif
endif
endif
endif
endif
time:
	xta load $(EXECUTABLE) source $(TIMINGSCRIPT) 4 10 -exit


#=============================================================================
# The following part of the Makefile includes the common build infrastructure
# for compiling XMOS applications. You should not need to edit below here.

XMOS_MAKE_PATH ?= ../..
include $(XMOS_MAKE_PATH)/xcommon/module_xcommon/build/Makefile.common
